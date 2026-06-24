import React, { useState, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator, Alert, Platform } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { router } from 'expo-router';
import axios from 'axios';

// Replace with your local IP address where FastAPI is running
const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://192.168.1.61:8000';

export default function LoginScreen() {
  const [permission, requestPermission] = useCameraPermissions();
  const [loading, setLoading] = useState(false);
  const cameraRef = useRef<CameraView>(null);

  if (!permission) {
    return <View style={styles.container}><ActivityIndicator color="#8b5cf6" size="large" /></View>;
  }

  if (!permission.granted) {
    return (
      <View style={styles.container}>
        <Text style={styles.text}>We need your permission to show the camera</Text>
        <TouchableOpacity style={styles.button} onPress={requestPermission}>
          <Text style={styles.buttonText}>Grant Permission</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const takePictureAndLogin = async () => {
    if (!cameraRef.current || loading) return;
    
    try {
      setLoading(true);
      const photo = await cameraRef.current.takePictureAsync({ base64: false });
      
      if (!photo) throw new Error("Failed to capture photo");

      const formData = new FormData();
      formData.append('photo', {
        uri: Platform.OS === 'ios' ? photo.uri.replace('file://', '') : photo.uri,
        type: 'image/jpeg',
        name: 'login.jpg',
      } as any);

      const response = await axios.post(`${API_BASE_URL}/api/employee/login`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      if (response.data.status === 'success') {
        const employee = response.data.employee;
        router.replace({ pathname: '/dashboard', params: { employeeStr: JSON.stringify(employee) } });
      }
    } catch (error: any) {
      console.log(error);
      const msg = error.response?.data?.detail || error.message || "Failed to login";
      Alert.alert("Authentication Failed", msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.titleSnap}>SNAP</Text>
        <Text style={styles.titleAttend}>ATTEND</Text>
        <Text style={styles.subtitle}>Enterprise Biometric Access</Text>
      </View>
      
      <View style={styles.cameraWrapper}>
        <View style={styles.cameraContainer}>
          <CameraView style={styles.camera} facing="front" ref={cameraRef} />
          <View style={styles.overlay}>
            <View style={styles.faceOutline} />
          </View>
        </View>
        <Text style={styles.instructionText}>Position your face within the frame</Text>
        
        <View style={styles.badgesContainer}>
          <View style={styles.badge}><Text style={styles.badgeText}>Face ID</Text></View>
          <View style={styles.badge}><Text style={styles.badgeText}>Liveness Check</Text></View>
          <View style={styles.badge}><Text style={styles.badgeText}>Anti-Spoof</Text></View>
        </View>
      </View>

      <TouchableOpacity 
        style={[styles.loginButton, loading && styles.loginButtonDisabled]} 
        onPress={takePictureAndLogin}
        disabled={loading}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.loginButtonText}>Scan Face to Login</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#050505', alignItems: 'center', justifyContent: 'center' },
  header: { position: 'absolute', top: 60, alignItems: 'center', width: '100%' },
  titleSnap: { fontSize: 42, fontWeight: '900', color: '#fff', letterSpacing: 4, lineHeight: 45 },
  titleAttend: { fontSize: 42, fontWeight: '900', color: '#8b5cf6', letterSpacing: 4, lineHeight: 45 },
  subtitle: { fontSize: 14, color: '#a1a1aa', marginTop: 8, letterSpacing: 1, textTransform: 'uppercase' },
  
  cameraWrapper: { alignItems: 'center', marginTop: 80 },
  cameraContainer: { width: 280, height: 380, borderRadius: 140, overflow: 'hidden', borderWidth: 3, borderColor: '#8b5cf6', position: 'relative', shadowColor: '#8b5cf6', shadowOffset: { width: 0, height: 0 }, shadowOpacity: 0.5, shadowRadius: 20, elevation: 10 },
  camera: { flex: 1 },
  overlay: { ...StyleSheet.absoluteFillObject, justifyContent: 'center', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.1)' },
  faceOutline: { width: 160, height: 220, borderWidth: 2, borderColor: 'rgba(255,255,255,0.5)', borderRadius: 80, borderStyle: 'dashed' },
  
  instructionText: { color: '#a1a1aa', fontSize: 14, marginTop: 24, fontWeight: '500' },
  
  badgesContainer: { flexDirection: 'row', gap: 8, marginTop: 16, flexWrap: 'wrap', justifyContent: 'center', paddingHorizontal: 20 },
  badge: { backgroundColor: 'rgba(139, 92, 246, 0.15)', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 100, borderWidth: 1, borderColor: 'rgba(139, 92, 246, 0.3)' },
  badgeText: { color: '#c084fc', fontSize: 10, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 0.5 },
  
  loginButton: { position: 'absolute', bottom: 50, backgroundColor: '#8b5cf6', paddingVertical: 18, paddingHorizontal: 40, borderRadius: 100, shadowColor: '#8b5cf6', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.5, shadowRadius: 15, elevation: 10, width: '80%', alignItems: 'center' },
  loginButtonDisabled: { opacity: 0.7 },
  loginButtonText: { color: '#fff', fontSize: 16, fontWeight: '800', textTransform: 'uppercase', letterSpacing: 1 },
  text: { color: '#fff', marginBottom: 20 },
  button: { backgroundColor: '#8b5cf6', padding: 12, borderRadius: 8 },
  buttonText: { color: '#fff', fontWeight: 'bold' }
});
