# Quick Start - Report Incident Feature

## ✅ What's Been Implemented

### Core Features (2.1-2.8)
- ✅ [2.1] Image picker (camera/gallery) with preview
- ✅ [2.2] SQL dropdowns for stations & violations
- ✅ [2.3] AI image classification with confidence scores
- ✅ [2.4] Auto-update violation type from AI results
- ✅ [2.5] TFLite model integration ready
- ✅ [2.6] Offline SQLite storage (all fields)
- ✅ [2.7] Online Firebase storage (Firestore)
- ✅ [2.8] Smart image handling (OFFLINE_ONLY for local files)

---

## 🚀 Quick Setup

### 1. Update Dependencies
```bash
cd c:\Users\Ausu\Desktop\code\futter_final_66111741
flutter pub get
```

### 2. Set Up Firebase (for online storage)

**Option A: Quick Setup (Simulation Mode)**
- Just run the app - features work with simulated AI
- Offline saving works immediately
- Firebase sync is optional

**Option B: Real Firebase**
1. Go to https://console.firebase.google.com
2. Create new project
3. Set up Firestore Database
4. Download credentials:
   - **Android:** `google-services.json` → `android/app/`
   - **iOS:** `GoogleService-Info.plist` → Add to Xcode
5. Restart app

### 3. Add Custom TFLite Model (Optional)

1. Create `assets/models/` folder
2. Place your `.tflite` model file there
3. Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/models/election_model.tflite
```
4. In `Report_Incident.dart`, replace `_simulateAIClassification()` with real inference

---

## 📱 How to Use

### Reporter Flow
1. Open "Report Incident" page
2. **Select Image** → Camera or Gallery → Image preview shows
3. **Optional: Use AI** → Tap "Analyze with AI" → Auto-fills violation type
4. **Fill Form:**
   - Station: Select from dropdown (required)
   - Violation Type: Auto-filled or select manually (required)
   - Reporter Name: Enter text (required)
   - Description: Enter details (required)
5. **Save** → Data saved offline + synced online if possible

---

## 📂 File Structure

```
lib/
├── screens/Report_Incident.dart          ← Main UI (all features here)
├── services/
│   ├── ai_image_classifier.dart          ← AI/TFLite integration
│   └── firebase_service.dart             ← Firebase operations
├── database/database_helper.dart         ← Updated with sync
└── models/incident_report.dart           ← Already has all fields
```

---

## 🔧 Data Models

### Violation Types (Auto-loaded from SQLite)
| ID | Name | Severity |
|----|------|----------|
| 1 | ซื้อสิทธิ์ขายเสียง | High |
| 2 | ขนคนไปลงคะแนน | High |
| 3 | หาเสียงเกินเวลา | Medium |
| 4 | การกลั่นแกล้งผู้สมัคร | Medium |
| 5 | ละเมิดสิทธิ์ผู้เลือกตั้ง | High |

### AI Mapping
- **Money/Wallet/Envelope** → Type 1 (ซื้อสิทธิ์ขายเสียง)
- **Crowd/Minibus/Vehicle** → Type 2 (ขนคนไปลงคะแนน)
- **Poster/Banner/Campaign** → Type 3 (หาเสียงเกินเวลา)

---

## 💾 Storage Details

### SQLite (Offline)
- **All fields stored:** ✅ Name, Description, Photo, AI Result, Confidence, Timestamp
- **Database:** `election_report.db`
- **Always available:** Works without internet

### Firestore (Online)
- **Smart image handling:**
  - Local photos → Stored as `"OFFLINE_ONLY"` (not uploaded)
  - External URLs → Preserved as-is
- **Sync automatic:** On save, if internet exists
- **Fallback:** If offline, saves locally first, syncs later

---

## 🎯 Key Implementation Details

### [2.3] AI Classification
```dart
// Current: Simulated (for demo)
// Shows realistic results without actual model

// When you add real TFLite:
// - Replace _simulateAIClassification() 
// - Use _aiClassifier.classifyImage()
// - Get real inference results
```

### [2.4] Auto-Update Logic
```dart
// Only updates if:
// 1. AI returns a mapped violation type
// 2. Confidence >= 70%
// 3. Manual selection always possible
```

### [2.8] Smart Image Handling
```dart
// Local file (from camera/gallery)
Evidence_photo = "OFFLINE_ONLY"  // No large file upload

// External URL
Evidence_photo = "https://..."   // Preserved as URL
```

---

## ✨ Features Summary

| Feature | Status | Details |
|---------|--------|---------|
| Image Picker | ✅ | Camera + Gallery |
| Image Preview | ✅ | 200x200 container |
| AI Analysis | ✅ | Simulated (ready for real model) |
| Confidence Score | ✅ | Shows % |
| Auto-Fill | ✅ | Updates if confidence ≥ 70% |
| SQLite Save | ✅ | All fields, always available |
| Firebase Save | ✅ | Optional, smart image handling |
| Offline Support | ✅ | Works without internet |
| Online Sync | ✅ | Auto when connected |
| Error Handling | ✅ | Validation + user feedback |

---

## 🧪 Testing

### Basic Test
```
1. Open Report Incident
2. Select image
3. Tap AI analysis
4. Check violation type updates
5. Fill remaining fields
6. Save
7. Check SQLite for data
```

### Firebase Test
```
1. Set up Firebase project
2. Add google-services.json
3. Save report with internet
4. Check Firestore console
5. Verify evidence_photo = "OFFLINE_ONLY"
```

---

## ⚙️ Configuration

### Firebase Firestore Collection Path
Currently: `incident_reports`

**To change:**
- Open `lib/services/firebase_service.dart`
- Find: `.collection('incident_reports')`
- Replace with your collection name

### AI Model Path
Currently: Simulated (demo)

**To add real model:**
- Place `.tflite` in `assets/models/`
- Initialize in `initState()`: 
  ```dart
  await _aiClassifier.initialize('assets/models/your_model.tflite');
  ```
- Replace `_simulateAIClassification()` with real inference

---

## 📝 Notes

- **Simulation mode:** Fully functional without real model or Firebase
- **Offline first:** All data saves locally before attempting online sync
- **No image upload:** Large image files stay on device (OFFLINE_ONLY)
- **Easy to customize:** Each feature is in separate service class

---

## 🔗 File Locations
- Main Screen: [lib/screens/Report_Incident.dart](lib/screens/Report_Incident.dart)
- AI Service: [lib/services/ai_image_classifier.dart](lib/services/ai_image_classifier.dart)
- Firebase Service: [lib/services/firebase_service.dart](lib/services/firebase_service.dart)
- Database: [lib/database/database_helper.dart](lib/database/database_helper.dart)
- Full Guide: [REPORT_INCIDENT_IMPLEMENTATION.md](REPORT_INCIDENT_IMPLEMENTATION.md)

---

## ✅ Checklist to Get Started

- [ ] Run `flutter pub get`
- [ ] Verify code compiles with `flutter analyze`
- [ ] Test app on emulator/device
- [ ] Verify image picker works
- [ ] Check SQLite saves data
- [ ] (Optional) Set up Firebase
- [ ] (Optional) Add real TFLite model

---

**Status:** Ready for testing and deployment
**Last Updated:** 2026-02-22
