# Report Incident Page - Implementation Guide

## Overview
This guide explains the comprehensive implementation of the Report Incident (แจ้งเหตุด่วน) page with:
- Image capture (camera/gallery) [2.1]
- SQL dropdown queries [2.2]
- AI image classification [2.3]
- Auto-updating violation type [2.4]
- Custom TFLite models [2.5]
- Offline SQLite storage [2.6]
- Online Firebase storage [2.7]
- Smart image handling [2.8]

---

## 1. Architecture Overview

### File Structure
```
lib/
├── screens/
│   └── Report_Incident.dart          # Main UI screen with all features
├── services/
│   ├── ai_image_classifier.dart      # TFLite model integration
│   └── firebase_service.dart         # Firebase Database/Firestore
├── database/
│   └── database_helper.dart          # SQLite + Firebase sync
├── models/
│   ├── incident_report.dart          # Data model
│   ├── polling_station.dart          # Station model
│   └── violation_type.dart           # Violation model
```

---

## 2. Dependencies Added to pubspec.yaml

```yaml
# Image handling
image_picker: ^1.1.2              # Camera and gallery selection

# AI/ML
tflite_flutter: ^0.10.4           # TensorFlow Lite inference
tflite_flutter_helper: ^0.0.6     # Image preprocessing

# Firebase
firebase_core: ^2.24.0            # Firebase initialization
firebase_database: ^10.4.0        # Realtime Database (optional)
cloud_firestore: ^4.14.0          # Firestore
path_provider: ^2.1.1             # File system access
```

### Installation
Run in terminal:
```bash
flutter pub get
```

---

## 3. Feature Implementation Details

### [2.1] Image Selection (Camera/Gallery)

**Location:** `lib/screens/Report_Incident.dart`

**Methods:**
- `_pickImageFromCamera()` - Opens device camera
- `_pickImageFromGallery()` - Opens photo gallery
- `_showImageSourceDialog()` - Presents selection dialog

**UI Components:**
- Image preview container (200x200)
- "Select Image" button with picker dialog
- Close button to remove selected image

**Code Usage:**
```dart
// User clicks "Select Image" → Dialog appears → Choose camera or gallery
// Selected image displays in preview container
// Can process with AI or submit directly
```

---

### [2.2] SQL Dropdown Queries

**Location:** `lib/database/database_helper.dart`

**Data Loaded:**
```dart
getPollingStations()  // Returns List<PollingStation>
getViolationTypes()   // Returns List<ViolationType>
```

**Sample Data in SQLite:**

**Polling Stations:**
| station_id | station_name | zone | province |
|-----------|---|---|---|
| 101 | โรงเรียนวัดพระมหาธาตุ | เขต 1 | กรุงเทพมหานคร |
| 102 | เต็นท์หน้าตลาดท่าวัง | เขต 2 | กรุงเทพมหานคร |

**Violation Types:**
| type_id | type_name | severity |
|---------|---|---|
| 1 | ซื้อสิทธิ์ขายเสียง | High |
| 2 | ขนคนไปลงคะแนน | High |
| 3 | หาเสียงเกินเวลา | Medium |

---

### [2.3] AI Image Classification

**Location:** `lib/services/ai_image_classifier.dart`

**Methods:**
- `initialize(String modelPath)` - Load TFLite model
- `classifyImage(String imagePath)` - Process image
- `classifyElectionViolation()` - Map to violation types

**AI Result Mapping:**

#### Option A: Generic MobileNet/MobileNetV2
Maps common objects to election violations:

| Detection | Mapped Violation | Type ID |
|-----------|-----------------|---------|
| wallet, purse, envelope, money | ซื้อสิทธิ์ขายเสียง | 1 |
| minibus, cab, vehicle, crowd | ขนคนไปลงคะแนน | 2 |
| water bottle, cup, gift, item | แจกสิ่งของ | - |
| poster, banner, campaign | หาเสียงเกินเวลา | 3 |

#### Option B: Custom Election Model (RECOMMENDED)
Direct detection of election violations:
- **Money** - ซื้อสิทธิ์ขายเสียง (Type 1)
- **Crowd** - ขนคนไปลงคะแนน (Type 2)
- **Poster** - หาเสียงเกินเวลา (Type 3)

**Current Implementation:** Simulated (see `_simulateAIClassification()` method)

---

### [2.4] Auto-Update Violation Type from AI

**Location:** `lib/screens/Report_Incident.dart` - `_processImageWithAI()`

**Logic:**
```dart
// After AI classification
if (result['violationType'] != null && _aiConfidence! >= 70.0) {
  // Auto-update dropdown only if confidence >= 70%
  _selectedViolationTypeId = result['violationType'];
}
```

**Behavior:**
- AI processes image and returns classification
- If confidence ≥ 70%, automatically fill dropdown
- User can still manually override the selection

---

### [2.5] Custom TFLite Model Setup

**To use actual models instead of simulation:**

1. **Prepare your model file** (`model.tflite`)
   - Custom election-specific model recommended
   - Place in: `assets/models/election_model.tflite`

2. **Update pubspec.yaml:**
   ```yaml
   flutter:
     assets:
       - assets/models/election_model.tflite
   ```

3. **Initialize in code:**
   ```dart
   // In initState()
   await _aiClassifier.initialize('assets/models/election_model.tflite');
   ```

4. **Replace simulation:**
   ```dart
   // Replace _simulateAIClassification() with real inference:
   final result = await _aiClassifier.classifyImage(_selectedImage!.path);
   final mapped = _aiClassifier.classifyElectionViolation(
     result['label'],
     double.parse(result['confidence']),
   );
   ```

**Model Performance:**
- Input size: 224x224 pixels
- Output: Label + confidence score
- Processing time: ~1-3 seconds per image

---

### [2.6] Offline Storage (SQLite)

**Location:** `lib/database/database_helper.dart`

**Database Schema:**
```sql
CREATE TABLE incident_report (
  report_id INTEGER PRIMARY KEY AUTOINCREMENT,
  station_id INTEGER NOT NULL,
  type_id INTEGER NOT NULL,
  reporter_name TEXT NOT NULL,
  description TEXT NOT NULL,
  evidence_photo TEXT,           -- Stores local file path
  timestamp DATETIME NOT NULL,
  ai_result TEXT,               -- AI classification label
  ai_confidence REAL,           -- Confidence score (0-100)
  FOREIGN KEY (station_id),
  FOREIGN KEY (type_id)
)
```

**Offline Save Method:**
```dart
// Saves all fields completely
final reportId = await DatabaseHelper.instance.insertIncidentReport(report);
```

**All Fields Saved:**
- ✅ Reporter name
- ✅ Description
- ✅ Evidence photo (local path)
- ✅ Station ID
- ✅ Violation type ID
- ✅ Timestamp
- ✅ AI result label
- ✅ AI confidence score

---

### [2.7] Online Storage (Firebase)

**Location:** `lib/services/firebase_service.dart`

**Setup Required:**

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com
   - Create new project
   - Enable Firestore Database

2. **Android Configuration**
   - Download `google-services.json`
   - Place in: `android/app/`

3. **iOS Configuration**
   - Download `GoogleService-Info.plist`
   - Add to Xcode: `Runner` → `GoogleService-Info.plist`

4. **Initialize Firebase**
   - App automatically initializes on first launch
   - Check status in logs

**Firebase Data Structure:**
```
Collection: incident_reports
├── Document: {auto-generated ID}
│   ├── station_id: 101
│   ├── type_id: 1
│   ├── reporter_name: "John Doe"
│   ├── description: "Suspicious activity..."
│   ├── evidence_photo: "OFFLINE_ONLY" OR "https://url..."
│   ├── timestamp: 2024-02-22T10:30:00Z
│   ├── ai_result: "Money/Payment Detection"
│   ├── ai_confidence: 85.5
│   ├── sync_status: "synced"
│   └── created_at: 2024-02-22T10:30:00Z
```

---

### [2.8] Smart Image Handling

**Location:** `lib/services/firebase_service.dart` - `uploadIncidentReport()`

**Image Source Detection:**
```dart
bool _isLocalFilePath(String path) {
  // Windows paths: C:\...
  if (RegExp(r'^[a-zA-Z]:\\').hasMatch(path)) return true;
  
  // Unix/Linux paths: /data/...
  if (path.startsWith('/')) return true;
  
  // URLs start with http/https → return false
  return false;
}
```

**Upload Rules:**

| Image Source | Firebase Value | Reason |
|---|---|---|
| Camera/Gallery (local) | `"OFFLINE_ONLY"` | Avoid uploading large files |
| External URL (web) | Original URL | Preserve reference |
| Network image | Original URL | Preserve reference |

**Implementation:**
```
If local file path (C:\ or /) {
  Store as: "OFFLINE_ONLY"
  Image saved ONLY in SQLite
} Else if URL {
  Store as: URL string
  Reference to external storage
}
```

**Benefits:**
- ✅ Saves cloud storage space
- ✅ Reduces bandwidth usage
- ✅ Keeps local images private
- ✅ Preserves external URLs

---

## 4. Usage Flow

### Step-by-Step User Flow

1. **Open Report Incident Page**
   - Form loads
   - Data queries from SQLite: stations, violation types
   - Dropdowns populate

2. **Select Image**
   - Tap "Select Image" button
   - Choose Camera or Gallery
   - Image preview displays

3. **Process with AI** (Optional)
   - Tap "Analyze with AI" button
   - Wait 2-3 seconds for processing
   - AI shows result: Label + Confidence %
   - Violation type auto-updates if confidence ≥ 70%

4. **Fill Form**
   - Reporter Name: Enter manually
   - Description: Enter details
   - Station: Select from dropdown (optional to override AI)
   - Violation Type: Auto-filled or select manually

5. **Save Report**
   - Tap "Save" button
   - **Offline:** Saves to SQLite immediately ✓
   - **Online:** Attempts Firebase sync:
     - If connected: Uploads (with smart image handling) ✓
     - If offline: Queues for sync ✓
   - Shows success message
   - Form resets

---

## 5. Integration Instructions

### Firebase Integration

**1. Android Setup**
```kotlin
// In build.gradle (project level)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}

// In build.gradle (app level)
plugins {
    id 'com.google.gms.google-services'
}
```

**2. iOS Setup**
```
- Open ios/Runner.xcworkspace
- Add GoogleService-Info.plist via Xcode
- Build and run
```

**3. Firestore Security Rules**
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /incident_reports/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Custom TFLite Model Integration

**1. Prepare Model**
- Train/export as `.tflite` file
- Optimize for mobile (224x224 input, <5MB)
- Test on device

**2. Add to Project**
```yaml
flutter:
  assets:
    - assets/models/election_model.tflite
```

**3. Update Classifier**
- Modify `AIImageClassifier.initialize()`
- Update input/output tensor mapping
- Test classification accuracy

---

## 6. Testing Checklist

### Offline Functionality
- [ ] Select image from camera
- [ ] Select image from gallery
- [ ] Process image with AI
- [ ] Auto-fill violation type
- [ ] Submit form
- [ ] Data saved to SQLite
- [ ] Verify in database

### Online Functionality
- [ ] Firebase initialized successfully
- [ ] Submit report with internet
- [ ] Firestore document created
- [ ] Local image stored as "OFFLINE_ONLY"
- [ ] External URL stored as-is
- [ ] Retrieve reports from Firestore

### AI Classification
- [ ] AI processes different image types
- [ ] Confidence scores display correctly
- [ ] Dropdown updates on confidence ≥ 70%
- [ ] Manual override works

### Error Handling
- [ ] No image selected → Shows error
- [ ] No dropdowns selected → Shows error
- [ ] Firebase unavailable → Saves offline only
- [ ] Image too large → Handles gracefully

---

## 7. Customization Guide

### Adding More Violation Types

**1. Update Database:**
```dart
// In _insertViolationTypes() method
await db.insert('violation_type', {
  'type_id': 6,
  'type_name': 'New Violation Type',
  'severity': 'High'
});
```

**2. Update AI Mapping:**
```dart
// In AIImageClassifier.classifyElectionViolation()
if (label.contains('new_keyword')) {
  return {
    'violationType': 6,
    'label': 'Detection Label',
    'confidence': '###',
  };
}
```

### Changing AI Model
```dart
// In report_incident.dart, _processImageWithAI()
// Replace entire method body with real model inference
final result = await _aiClassifier.classifyImage(_selectedImage!.path);
```

### Firebase Collection Naming
```dart
// Change collection name in firebase_service.dart
_firestore.collection('custom_collection_name').add(reportData);
```

---

## 8. Performance Optimization

### Image Optimization
```dart
// Compress image before AI processing
final compressed = await compute(
  _compressImage,
  _selectedImage!.path,
);
```

### Batch Upload
```dart
// Sync queued offline reports
await DatabaseHelper.instance.syncPendingReports();
```

### Database Indexing
```sql
CREATE INDEX idx_station ON incident_report(station_id);
CREATE INDEX idx_type ON incident_report(type_id);
CREATE INDEX idx_timestamp ON incident_report(timestamp);
```

---

## 9. Troubleshooting

| Issue | Solution |
|-------|----------|
| Image picker not working | Check iOS/Android permissions |
| AI not initialized | Ensure model file exists in assets |
| Firebase not syncing | Check internet connection, Firebase config |
| Dropdowns empty | Verify SQLite database initialization |
| AI too slow | Use smaller model or optimize preprocessing |

---

## 10. Next Steps

1. **Add actual TFLite model** (replace simulation)
2. **Set up Firebase project** with valid credentials
3. **Test on real device** with camera/internet
4. **Add image compression** before upload
5. **Implement sync queue** for offline reports
6. **Add analytics tracking** for usage monitoring

---

## References

- Flutter Image Picker: https://pub.dev/packages/image_picker
- TensorFlow Lite Flutter: https://pub.dev/packages/tflite_flutter
- Firebase Firestore: https://firebase.google.com/docs/firestore
- Election Violation Detection: Custom model training guide

---

**Last Updated:** 2026-02-22
**Status:** Ready for testing and customization
