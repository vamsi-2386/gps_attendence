package com.example.lumenor_hrms_flutter

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val securityChannel = "lumenor/device_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDeveloperOptionsEnabled" ->
                        result.success(isDeveloperOptionsEnabled())
                    else -> result.notImplemented()
                }
            }
    }

    /// Reads the system "Developer options" master toggle. Returns false if the
    /// setting can't be read so the app fails open rather than locking the user
    /// out due to an unexpected platform error.
    private fun isDeveloperOptionsEnabled(): Boolean {
        return try {
            Settings.Global.getInt(
                contentResolver,
                Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                0,
            ) != 0
        } catch (e: Exception) {
            false
        }
    }
}
