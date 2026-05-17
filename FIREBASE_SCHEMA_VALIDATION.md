# Firebase Schema Validation Strategy

## Overview
This document outlines the strategy for validating PneumaGe Master Schema data during Firebase sync operations to ensure data integrity and handle schema version mismatches gracefully.

## Current Sync Architecture
- **Project Metadata** → Firestore documents
- **Measurement Metadata** → Firestore subcollection (lightweight)
- **Full Measurement Data** → Cloud Storage JSON files (includes all samples)
- **No Current Validation** → Data serialized/deserialized with assumption of compatibility

## Validation Strategy (3 Phases)

### Phase 1: Client-Side Validation ⭐ **IMPLEMENTED**
**Goal:** Catch data integrity issues before they reach Firebase and handle incompatible data gracefully during restore.

**Implementation:**
1. **Pre-Upload Validation** (`_validateRecordSchema()`)
   - Check schema version compatibility
   - Validate required fields (recordUuid, version, channels)
   - Verify data integrity (timestamp/value array lengths match)
   - Throw StateError if validation fails

2. **Restore Validation** (`_validateRestoredRecord()`)
   - Check version compatibility using semantic versioning
   - Validate required data structures (provenance, channels)
   - Skip invalid measurements with warning logs
   - Throw StateError if no valid measurements found

**Benefits:**
- ✅ Prevents corrupt data upload
- ✅ Graceful handling of legacy/incompatible records
- ✅ Clear error messages for debugging
- ✅ No server-side changes required
- ✅ Works offline (validation happens locally)

**Limitations:**
- Only validates data the app touches (not bulk imports)
- Cannot prevent malicious/corrupt data from other sources
- No validation of historical cloud data

---

### Phase 2: Server-Side Basic Validation
**Goal:** Enforce schema constraints at the database layer.

**Implementation:**
1. **Firestore Security Rules** (firestore.rules)
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /projects/{projectId}/measurements/{measurementId} {
         allow write: if 
           request.auth != null &&
           request.resource.data.record_uuid is string &&
           request.resource.data.version is string &&
           isCompatibleVersion(request.resource.data.version);
       }
     }
     
     function isCompatibleVersion(recordVersion) {
       let parts = recordVersion.split('.');
       let major = int(parts[0]);
       let minor = int(parts[1]);
       return major == 1 && minor >= 9 && minor <= 10;
     }
   }
   ```

2. **Validation Status UI**
   - Add `_validationStatus` field to measurement metadata
   - Show warning banner: "⚠️ 2 measurements skipped due to schema mismatch"
   - Allow user to view/export failed records for debugging

**Benefits:**
- ✅ Server-enforced data integrity
- ✅ Prevents malicious/corrupt data injection
- ✅ User visibility into sync issues
- ✅ No cloud functions required (lower cost)

**Limitations:**
- Limited validation logic (Firestore rules are constrained)
- Cannot validate complex nested structures
- Cannot validate Cloud Storage JSON files

**Effort:** ~2 hours
- 1 hour: Write and deploy Firestore rules
- 30 min: Add validation status to UI
- 30 min: Testing

---

### Phase 3: Advanced Cloud Function Validation
**Goal:** Full JSON Schema validation with automatic error reporting.

**Implementation:**
1. **Cloud Function** (TypeScript + Ajv)
   - Triggered on measurement document write
   - Fetch full record from Cloud Storage
   - Validate against complete JSON Schema (from CROSS_PLATFORM_DATA_MODEL_STRATEGIES.md)
   - Write validation results to Firestore (`_validated`, `_validationError`)

2. **Background Migration Job**
   - Scheduled function to validate existing cloud data
   - Generate migration reports for incompatible records
   - Support semi-automatic schema upgrades

3. **Admin Dashboard**
   - View validation errors across all users
   - Identify common schema issues
   - Monitor schema version distribution

**Benefits:**
- ✅ Complete schema validation (all 13 types)
- ✅ Automatic error detection and logging
- ✅ Migration support for schema upgrades
- ✅ Project-wide data quality monitoring

**Limitations:**
- Requires Firebase Functions (Blaze plan)
- Additional infrastructure complexity
- Validation runs after upload (not preventative)

**Effort:** ~8-10 hours
- 3 hours: Write and test Cloud Function
- 2 hours: Integrate JSON Schema (convert to TypeScript)
- 2 hours: Background migration job
- 2 hours: Admin dashboard UI
- 1 hour: Testing and deployment

---

## Validation Rules

### Schema Version Compatibility
**Semantic Versioning Rules:**
- Major version must match exactly (1.x.x only)
- App minor version must be >= record minor version
- Patch versions ignored for compatibility
- Null version (legacy firmware) treated as compatible

**Examples:**
- ✅ Record 1.9.0, App 1.9.0 → Compatible
- ✅ Record 1.8.0, App 1.9.0 → Compatible (app newer)
- ❌ Record 1.10.0, App 1.9.0 → Incompatible (app too old)
- ❌ Record 2.0.0, App 1.9.0 → Incompatible (major version mismatch)

### Required Fields Validation
**PneumaGeRecord:**
- `version`: string (semantic version format)
- `recordUuid`: non-empty string (UUID v4)
- `provenance`: object with creator info
- `measurementCycle`: object with channels array

**FluxChannel:**
- `targetGas`: non-empty string
- `rawStream.timestamps`: array matching `rawStream.values` length
- `filteredStream.timestamps`: array matching `filteredStream.values` length

**Measurement Metadata (Firestore):**
- `record_uuid`: string
- `version`: string
- `project_id`: string
- `cycle_id`: string
- `timestamp_start`: ISO 8601 string
- `coordinates`: object with lat/lon/elevation_m

### Data Integrity Checks
1. **Array Length Consistency**: All stream arrays (timestamps, values, pressures) must have matching lengths
2. **UUID Format**: recordUuid must be valid UUID v4 format
3. **Timestamp Ordering**: timestamps arrays must be monotonically increasing
4. **Numeric Ranges**: Values must be within physically plausible ranges
5. **Non-Empty Channels**: At least one flux channel required

---

## Error Handling

### Upload Validation Failure
```dart
try {
  await syncService.syncProject(project, measurements);
} catch (e) {
  if (e is StateError && e.message.contains('Schema version mismatch')) {
    // Show user-friendly message
    showDialog('Cannot sync: App version outdated');
  } else if (e is StateError && e.message.contains('Invalid record')) {
    // Log for debugging
    logError('Data corruption detected', error: e);
    showDialog('Cannot sync: Data validation failed');
  }
}
```

### Restore Validation Handling
```dart
final result = await syncService.restoreProject(projectId);

// result.measurements may be partial if some failed validation
if (result.measurements.isEmpty) {
  showDialog('No compatible measurements found - update app?');
} else {
  showSnackbar('${result.measurements.length} measurements restored');
  
  // Check logs for skipped measurements
  // Console will show: ⚠️ Skipping invalid measurement abc-123: Schema version mismatch
}
```

---

## Testing Strategy

### Unit Tests
- ✅ Valid record passes all checks
- ✅ Missing required fields throws StateError
- ✅ Incompatible version throws StateError
- ✅ Array length mismatch throws StateError
- ✅ Legacy record (null version) passes
- ✅ Partial restore succeeds with warnings

### Integration Tests
1. Upload valid measurement → succeeds
2. Upload corrupt measurement → fails with clear error
3. Restore project with mixed valid/invalid → succeeds with warnings
4. Restore project with all invalid → fails with clear error
5. Version upgrade scenario → older data restored correctly

### Manual Testing Checklist
- [ ] Create measurement with current app
- [ ] Sync to Firebase
- [ ] Verify metadata in Firestore
- [ ] Verify full data in Cloud Storage
- [ ] Restore on same device → success
- [ ] Simulate version mismatch (change kSchemaVersion)
- [ ] Attempt restore → should skip incompatible
- [ ] Check console logs for validation warnings

---

## Deployment Rollout

### Phase 1: Client Validation (Current)
1. ✅ Implement validation functions
2. ✅ Add unit tests
3. Deploy app update with validation
4. Monitor error logs for validation failures
5. Document common issues for Phase 2 rules

### Phase 2: Server Validation
1. Write Firestore security rules locally
2. Test with Firebase emulator
3. Deploy rules to production (non-breaking)
4. Monitor rule denials in Firebase Console
5. Add UI for validation status
6. Release app update with validation UI

### Phase 3: Advanced Validation
1. Set up Firebase Functions project
2. Implement validation function
3. Test with staging environment
4. Deploy to production with monitoring
5. Run background validation on existing data
6. Create admin dashboard
7. Announce validation service to users

---

## Related Documentation
- [CROSS_PLATFORM_DATA_MODEL_STRATEGIES.md](CROSS_PLATFORM_DATA_MODEL_STRATEGIES.md) - Full schema definitions
- [SCHEMA_VERSION_IMPLEMENTATION_PLAN.md](SCHEMA_VERSION_IMPLEMENTATION_PLAN.md) - Version field implementation
- [lib/config/schema_version.dart](lib/config/schema_version.dart) - Version compatibility utilities
- [lib/services/sync_service.dart](lib/services/sync_service.dart) - Sync implementation with validation

---

## Status: Phase 1 Complete ✅
**Date Implemented:** May 18, 2026  
**Next Steps:** Monitor validation logs → Plan Phase 2 deployment
