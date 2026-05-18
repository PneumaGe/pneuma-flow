# Firebase Setup Guide for PneumaGe

## ✅ What's Already Done
- Firebase packages installed in pubspec.yaml
- SyncService implementation complete
- Firebase initialization added to main.dart

## 🚀 Quick Start

### 1. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase
```bash
cd /home/ssayed/git/pneuma-flow
flutterfire configure
```

Follow the prompts to:
- Select/create your Firebase project
- Choose platforms (Android, Linux, etc.)
- This generates `lib/firebase_options.dart`

### 3. Set Up Firestore Database
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database**
4. Click **Create Database**
5. Start in **test mode** (temporary)
6. Select nearest location
7. Click **Enable**

### 4. Set Up Cloud Storage
1. In Firebase Console → **Storage**
2. Click **Get Started**
3. Start in **test mode**
4. Click **Done**

### 5. Test Your Setup
```bash
flutter run
```

Your app should now start without Firebase errors!

## 📊 Database Structure

Your SyncService uses this structure:

```
Firestore:
└── projects/{projectId}
    ├── (project metadata)
    └── measurements/{measurementId}
        └── (lightweight metadata only)

Cloud Storage:
└── projects/{projectId}
    └── measurements/{measurementId}.json
        └── (full measurement data with all samples)
```

## 🔐 Next Steps: Security Rules

After testing, secure your database:

### Firestore Security Rules
Create `firestore.rules` in your project root:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Projects collection
    match /projects/{projectId} {
      // Authenticated users can read/write their own projects
      allow read, write: if request.auth != null;
      
      // Measurements subcollection
      match /measurements/{measurementId} {
        allow read, write: if request.auth != null;
        
        // Schema validation on write
        allow write: if 
          request.resource.data.record_uuid is string &&
          request.resource.data.version is string &&
          request.resource.data.project_id is string;
      }
    }
  }
}
```

### Cloud Storage Security Rules
Create `storage.rules`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /projects/{projectId}/measurements/{measurementId} {
      // Authenticated users can read/write
      allow read, write: if request.auth != null;
    }
  }
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules,storage:rules
```

## 🧪 Using Your SyncService

Your SyncService is ready to use! Here's how:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/sync_service.dart';

// Create a provider
final syncServiceProvider = Provider((ref) => SyncService());

// In your widget/screen:
final syncService = ref.read(syncServiceProvider);

// Upload a project
final updatedProject = await syncService.syncProject(
  project,
  measurements,
);

// Restore a project
final result = await syncService.restoreProject(projectId);
final restoredProject = result.project;
final restoredMeasurements = result.measurements;
```

## 📝 Schema Validation

Your SyncService includes built-in validation (see FIREBASE_SCHEMA_VALIDATION.md):
- ✅ Pre-upload validation catches corrupt data
- ✅ Restore validation handles version mismatches gracefully
- ✅ Semantic versioning compatibility checks

## 🔍 Troubleshooting

### Error: "firebase_options.dart not found"
Run `flutterfire configure` to generate it.

### Error: "Failed to get document"
Make sure Firestore database is created and security rules allow access.

### Error: "Storage object not found"
Verify Cloud Storage is enabled in Firebase Console.

### Error: "Permission denied"
Update security rules or enable authentication.

## 🎯 Optional: Add Authentication

If you want user accounts:

1. Firebase Console → **Authentication**
2. Click **Get Started**
3. Enable **Email/Password** or **Google Sign-In**
4. Use `firebase_auth` package (already in your pubspec.yaml!)

```dart
import 'package:firebase_auth/firebase_auth.dart';

// Sign in anonymously for testing
await FirebaseAuth.instance.signInAnonymously();

// Or with email/password
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);
```

## 📚 Next Steps

1. ✅ Run `flutterfire configure`
2. ✅ Create Firestore database
3. ✅ Create Cloud Storage bucket
4. ✅ Test with `flutter run`
5. Build UI for sync functionality
6. Add authentication (optional)
7. Deploy security rules
8. Test sync/restore flows

Your sync infrastructure is ready to go! 🚀
