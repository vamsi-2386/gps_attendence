# Flutter HRMS Check-In Flow - Test Execution Guide

## Quick Start

This guide provides step-by-step instructions to test the complete check-in workflow in the Lumenor HRMS app.

---

## PRE-REQUISITES

### 1. Environment Setup (5 minutes)

```bash
# Clone/open project
cd /c/Users/229x1/Desktop/gps_attendence

# Verify Supabase credentials
cat app/src/database/.env
cat lumenor_hrms_flutter/.env

# Install dependencies
cd app && pip install -r requirements.txt
cd ../lumenor_hrms_flutter && flutter pub get
```

### 2. Start Backend Services

**Terminal 1: FastAPI Backend**
```bash
cd /c/Users/229x1/Desktop/gps_attendence/app
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```
Expected: `Uvicorn running on http://0.0.0.0:8000`

**Terminal 2: Streamlit Portal**
```bash
cd /c/Users/229x1/Desktop/gps_attendence/app
streamlit run app.py
```
Expected: Browser opens to http://localhost:8501

**Terminal 3: Flutter App**
```bash
cd /c/Users/229x1/Desktop/gps_attendence/lumenor_hrms_flutter
flutter run
```
Expected: App launches on device/emulator

---

## TEST FLOW: 7 STEPS

### Step 1: Create Test Employee (15 minutes)

**In Streamlit Portal (http://localhost:8501):**

1. Click "Company Portal" button
2. Enter admin credentials (or register company)
3. Create company profile:
   - Company Name: "Test Corp"
   - Office Latitude: 28.6139 (Delhi example)
   - Office Longitude: 77.2090
   - Office Radius: 100 (meters)
   - Generate Invite Code: Copy this code

4. Go back to home, select "Login via FaceID"
5. Click "Register New Profile"
6. Accept biometric consent
7. Capture face image (well-lit, centered)
8. Enter:
   - Name: "Test User"
   - Employee Code: "EMP-001"
   - Invite Code: [Paste from step 3]
9. Click "Create Account"
10. Account created, logged in automatically

**Verify Supabase:**
```
Dashboard → employees table
Should contain 1 new row with:
- name: "Test User"
- employee_code: "EMP-001"
- face_embedding: [128-dimensional array]
```

---

### Step 2: Navigate to Home Screen (5 minutes)

**In Flutter App:**

1. Start app on iOS/Android device or emulator
2. Splash screen displays (2 seconds)
3. Login screen appears with two buttons:
   - "Login via FaceID"
   - "Register New Profile"

**In Streamlit Portal:**

1. Remain on employee dashboard
2. Tab 1: "🏠 Dashboard" selected
3. Sub-section: "📍 GPS Attendance" visible

**Checkpoint:** ✅ Both apps show home/dashboard screens

---

### Step 3: Verify Geofence Banner Colors (10 minutes)

**Test 3A: Inside Office Geofence**

In Streamlit Dashboard:

1. Scroll to "📡 Get Your Device Location"
2. Check: "🛠️ Simulate being inside Office (for testing on Desktop)"
3. Click location button (or skip if already granted)
4. Observe metrics:
   - Your Latitude: [office_lat]
   - Your Longitude: [office_lng]
   - Distance to Office: 0.0 m
   - Delta: "✅ Inside 100m zone" (green)

5. Banner display:
   - Color: Blue-purple gradient
   - Text: "You are **inside** the office geofence (0.0m from office centre)"
   - Background: Light blue tint

**Expected Screenshot:**
```
┌─────────────────────────────────────┐
│  🏢 Office Location                 │
│  Main Office                        │
│  📌 28.6139, 77.2090                │
│                  Geofence           │
│                  100m               │
│                                     │
│  Distance: 0.0m ✅ Inside 100m      │
│                                     │
│  ✅ You are **inside** the office   │
│     geofence (0.0m from centre)     │
│                                     │
│  [ ✅ Check-In Button ]             │
└─────────────────────────────────────┘
```

**Verify in Flutter:**
- Geofence banner color: Green/success state
- Distance metric displayed
- Check-In button enabled (clickable)

**Test 3B: Outside Office Geofence**

In Streamlit Dashboard:

1. Uncheck: "Simulate being inside Office"
2. Location defaults to ISP-based (Hyderabad area)
3. Observe:
   - Distance to Office: 1,500+ meters
   - Delta: "❌ Outside 100m zone" (red)

4. Banner display:
   - Color: Red (error state)
   - Text: "You are **1,500+ meters away** from the office"

**Expected Screenshot:**
```
┌─────────────────────────────────────┐
│  Distance: 1500.0m ❌ Outside 100m  │
│                                     │
│  ❌ You are **1,500+ meters away**  │
│     from the office. Move within    │
│     100m to check in.               │
│                                     │
│  [ ✅ Check-In Button ]             │
│    (Warning: location outside)      │
└─────────────────────────────────────┘
```

**Checkpoint:** ✅ Banner colors change correctly based on distance

---

### Step 4: Tap "Clock In" Button (20 minutes)

**In Streamlit Dashboard (Inside Office):**

1. Ensure "Simulate being inside Office" is CHECKED
2. Scroll to Check-In button
3. Click "✅ Check-In"
4. Observe:
   - Loading spinner or "Verifying..." message
   - Camera input widget appears
   - Message: "Position your face in the center to login"

5. Capture face image:
   - Ensure good lighting
   - Face centered
   - No glasses/hats (if possible)
   - Click capture

6. Wait for processing:
   - Progress: "AI is scanning.."
   - Typical duration: 3-10 seconds

**In Flutter App:**

1. Navigate to check-in screen
2. Tap "Clock In" button
3. Face capture interface opens
4. Camera preview displays with instructions
5. Capture face image
6. Verify loading spinner and "Verifying..." message

**Checkpoint:** ✅ Face capture triggered successfully

---

### Step 5: Verify Face Re-Verify Prompt (15 minutes)

**Expected Behavior:**

The app processes face image and returns one of three decisions:

**Case A: ACCEPTED (Success)**
```
Confidence Score: 0.92 (92%)
Decision: Accepted ✅

Result:
- Success screen shown
- Proceed to Step 6
```

**Case B: REVIEW (Borderline)**
```
Confidence Score: 0.65 (65%)
Decision: Review ⚠️

Result:
- Warning message: "borderline match"
- "flagged for HR review"
- Can proceed with warning
```

**Case C: REJECTED (Failure)**
```
Confidence Score: 0.45 (45%)
Decision: Rejected ❌

Result:
- Error message: "Face match score too low"
- Check-in BLOCKED
- Cannot proceed
- Can retry by capturing again
```

**In Streamlit:**

After image capture, you'll see:
- Debug image displayed
- Result message (success/warning/error)
- Confidence score displayed

**In Supabase Dashboard:**

After successful face verification:
```
Table: verification_events
New row:
  - event_type: "GPS Check-In"
  - success: true
  - confidence_score: 0.92
  - timestamp: 2026-06-23T15:30:00Z
```

**Checkpoint:** ✅ Face verification logged, decision recorded

---

### Step 6: Verify Check-In Success Screen (10 minutes)

**In Streamlit Dashboard:**

After successful check-in, you should see:
```
✅ Checked in successfully!

Checked in at 03:30 PM

Today's Attendance:
Check In: 03:30 PM
Check Out: --:--

[Status: Active Check-In]
[🚪 Check-Out Button Now Available]
```

**Expected Changes:**
1. Button changes from "✅ Check-In" to "🚪 Check-Out"
2. Info banner: "🕐 Checked in at 03:30 PM. Ready to check out?"
3. Success message: "✅ Checked in successfully!" (toast)
4. Screen content remains same but state updated

**In Flutter App:**

Success screen displays:
```
╔════════════════════════════════════╗
║  ✅ CHECK IN SUCCESSFUL            ║
├────────────────────────────────────┤
║  Checked in at 03:30 PM            ║
║                                    ║
║  Employee: Test User               ║
║  Project: Project Alpha            ║
║  Location: Inside Office           ║
║  Confidence: 92%                   ║
║                                    ║
║  [Continue to Home] [View Records] ║
╚════════════════════════════════════╝
```

**In Supabase Dashboard:**

Check attendance_logs table:
```
New record created:
- employee_id: [UUID of test employee]
- subject_id: [Project ID]
- timestamp: 2026-06-23T15:30:00Z
- latitude: 28.6139
- longitude: 77.2090
- location_status: "Inside Office"
- is_present: true
- face_confidence: 0.92
- checkout_time: NULL (not yet checked out)
```

**Verify Fields:**
- [ ] All 10 fields populated
- [ ] Timestamp in UTC (ends with Z)
- [ ] Coordinates match office location
- [ ] is_present = true
- [ ] checkout_time = NULL

**Checkpoint:** ✅ Supabase record created with correct data

---

### Step 7: Check "Clock Out" Timer Functionality (10 minutes)

**In Streamlit Dashboard:**

1. After successful check-in
2. Check-Out button is now visible: "🚪 Check-Out"
3. Info banner: "Checked in at 03:30 PM. Ready to check out?"
4. **Wait 2-5 minutes** (to simulate work session)
5. Click "🚪 Check-Out" button
6. Observe:
   - Loading spinner: "Verifying..."
   - Takes <5 seconds
   - Success: "✅ Checked out successfully!"
   - Button reverts to "✅ Check-In"
   - Banner resets

**Verify Duration:**

After check-out, navigate to "📅 Attendance History" tab:
```
| Date       | Check-In Time | Check-Out Time | Status      |
|------------|---------------|----------------|-------------|
| 2026-06-23 | 03:30 PM      | 03:35 PM       | ✅ Present  |
```

Duration = 03:35 PM - 03:30 PM = 5 minutes ✅

**In Supabase Dashboard:**

Same attendance_logs record now updated:
```
Updated fields:
- checkout_time: 2026-06-23T15:35:00Z
- duration_minutes: 5 (if calculated)
```

**Verify:**
- [ ] checkout_time populated with new timestamp
- [ ] Timestamp is AFTER check-in timestamp
- [ ] Duration calculable: checkout - checkin

**Checkpoint:** ✅ Check-out recorded, duration tracked

---

## INTEGRATION VERIFICATION

After completing all 7 steps, verify integrations:

### 1. Geofence API Integration ✅

Verify in FastAPI logs:
```
POST /api/v1/attendance/check-in
Request:
  - employee_id: [UUID]
  - latitude: 28.6139
  - longitude: 77.2090
  - timestamp: 2026-06-23T15:30:00Z

Response 200:
  - success: true
  - distance_from_office: 0.0
  - inside_geofence: true
```

### 2. Face Recognition API Integration ✅

Verify in backend:
```
Face processing:
  1. Image received (JPEG format)
  2. Face detection: 1 face found
  3. Embedding extracted: 128-dimensional vector
  4. Comparison: Cosine similarity = 0.92
  5. Decision: Accepted (0.92 > 0.7 threshold)
```

### 3. Supabase Integration ✅

Verify records:
```
1. attendance_logs: 1 record with checkout_time
2. verification_events: 2 records (check-in + optional check-out)
3. All timestamps in UTC
4. All foreign keys valid (employee_id exists)
```

### 4. Real-Time Updates ✅

Verify UI refresh:
```
- After check-in: Button changes immediately
- After check-out: Status updates without manual reload
- Attendance history: Latest record appears instantly
```

---

## EXPECTED RESULTS SUMMARY

| Step | Component | Expected | Actual | Pass? |
|------|-----------|----------|--------|-------|
| 3    | Geofence Inside | Green banner | | ☐ |
| 3    | Geofence Outside | Red banner | | ☐ |
| 4    | Check-In Button | Click works | | ☐ |
| 5    | Face Verification | Decision returned | | ☐ |
| 6    | Success Screen | Displayed | | ☐ |
| 6    | Supabase Record | Created | | ☐ |
| 7    | Check-Out | Updates record | | ☐ |
| 7    | Duration | Calculated | | ☐ |

---

## TROUBLESHOOTING

### Issue: "Face not found!"

**Cause:** Dark image, face out of frame, or poor quality

**Solution:**
1. Ensure good lighting (natural or room light)
2. Position face directly in center of frame
3. Remove glasses/sunglasses if possible
4. Try again with clearer image

### Issue: "Low similarity score" / Rejected

**Cause:** Different person captured or significant appearance change

**Solution:**
1. Verify correct person is capturing image
2. Try with better lighting
3. Remove facial hair/accessories if changed since enrollment
4. Re-enroll if persistent issues

### Issue: "Outside Office" but should be inside

**Cause:** GPS accuracy or geofence radius too small

**Solution:**
1. Check office location in Supabase companies table
2. Verify geofence radius (default 100m) is appropriate
3. Move closer to office (5 meters away)
4. Use "Simulate being inside Office" for desktop testing

### Issue: Supabase record not created

**Cause:** API response error or network issue

**Verify:**
1. FastAPI backend running: `curl http://10.79.79.4:8000/api/v1/health`
2. Supabase credentials correct in config files
3. Check FastAPI logs for error messages
4. Verify network connectivity

### Issue: Image not captured / Camera not working

**Cause:** Permission denied or camera hardware issue

**Solution:**
1. Grant camera permission in system settings
2. Verify camera hardware works (test with other app)
3. Restart app
4. Try different device/emulator if available

### Issue: Timeout during face verification

**Cause:** Slow network or model not loaded

**Solution:**
1. Check internet connection
2. Wait for model to load (first call slow, 5-10 seconds)
3. Subsequent calls should be faster (<5 seconds)
4. Retry if network was temporary issue

---

## PASSING CRITERIA

All of the following must be TRUE to mark test as **PASS**:

- [x] Geofence banner changes color correctly (green inside, red outside)
- [x] Check-In button successfully captured face image
- [x] Face verification completed (decision returned)
- [x] Success screen displayed after accepted verification
- [x] Supabase `attendance_logs` record created with all 10 fields
- [x] Check-Out button worked and updated `checkout_time`
- [x] Duration calculated correctly (checkout_time - check_in_time)
- [x] No errors in FastAPI logs or Flutter console
- [x] All timestamps in UTC format
- [x] No duplicate records created

**Result:** ✅ PASS / ⚠️ PASS WITH WARNINGS / ❌ FAIL

---

## NEXT STEPS

After test completion:

1. **Document Results:** Use CHECKIN_TEST_CHECKLIST.txt
2. **Report Issues:** Note any failures with reproduction steps
3. **Performance:** Record timing for face verification
4. **Feedback:** Share user experience observations
5. **Deploy:** If PASS, ready for staging/production
6. **Iterate:** Fix any FAIL items and re-test

---

## SUPPORT

For issues or questions:
- Check Supabase dashboard logs
- Review FastAPI terminal output
- Check Flutter console: `flutter logs`
- Inspect browser DevTools (Network tab) for API calls
- Review code in CHECKIN_TEST_REPORT.md (Section: Integration Issues)

---

**Generated:** 2026-06-23  
**Last Updated:** 2026-06-23
