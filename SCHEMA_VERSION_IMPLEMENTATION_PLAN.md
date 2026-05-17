# Schema Version Implementation Plan

**Date:** May 18, 2026  
**Objective:** Add `dataModelVersion` field to DeviceInfo for cross-platform data model compatibility checking

---

## Overview

Add a `dataModelVersion` field to the DeviceInfo JSON that the firmware sends over BLE. This enables the Flutter app to:
1. Validate firmware/app data model compatibility
2. Warn users about version mismatches
3. Track schema evolution over time
4. Support future migrations

---

## Phase 1: Arduino Firmware Update

### File: `pneuma-core.ino`

**Location:** `streamDeviceInfo()` function (line ~385)

**Change:**
```cpp
void streamDeviceInfo(BLEDevice& central) {
  StaticJsonDocument<1024> doc;

  // ... existing code ...
  
  doc["firmwareVersion"] = "1.2.0";
  doc["dataModelVersion"] = "1.9.0";  // ✅ ADD THIS LINE
  
  // ... rest of existing code ...
}
```

**Testing:**
- Use nRF Connect app to verify JSON includes new field
- Confirm JSON size still fits within 1024-byte buffer
- Verify zero-length packet termination still works

**Estimated Time:** 5 minutes  
**Risk Level:** LOW (additive change only)

---

## Phase 2: Flutter App Updates

### 2.1 Update DeviceInfo Model

**File:** `lib/models/device.dart`

**Location:** DeviceInfo class definition (line ~154)

#### Changes Required:

**A. Add Field to Class**
```dart
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final int descriptorVersion;
  final String? macAddress;
  final String processorMake;
  final String processorModel;
  final String processorSerial;
  final String firmwareVersion;
  final String? dataModelVersion;  // ✅ ADD THIS FIELD (nullable for backward compatibility)
  final DateTime? lastSeen;
  final PumpInfo pump;
  final List<SensorInfo> sensors;
  final Set<String> capabilities;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.descriptorVersion,
    this.macAddress,
    required this.processorMake,
    required this.processorModel,
    required this.processorSerial,
    required this.firmwareVersion,
    this.dataModelVersion,  // ✅ ADD THIS PARAMETER
    this.lastSeen,
    required this.pump,
    required this.sensors,
    this.capabilities = const {},
  });
```

**B. Update toJson() Method**
```dart
Map<String, dynamic> toJson() => {
  'deviceId': deviceId,
  'deviceName': deviceName,
  'descriptorVersion': descriptorVersion,
  if (macAddress != null) 'macAddress': macAddress,
  'processorMake': processorMake,
  'processorModel': processorModel,
  'processorSerial': processorSerial,
  'firmwareVersion': firmwareVersion,
  if (dataModelVersion != null) 'dataModelVersion': dataModelVersion,  // ✅ ADD THIS
  if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
  'pump': pump.toJson(),
  'sensors': sensors.map((s) => s.toJson()).toList(),
  'capabilities': capabilities.toList(),
};
```

**C. Update fromJson() Factory**
```dart
factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  descriptorVersion: json['descriptorVersion'] as int,
  macAddress: json['macAddress'] as String?,
  processorMake: json['processorMake'] as String,
  processorModel: json['processorModel'] as String,
  processorSerial: json['processorSerial'] as String,
  firmwareVersion: json['firmwareVersion'] as String,
  dataModelVersion: json['dataModelVersion'] as String?,  // ✅ ADD THIS
  lastSeen: json['lastSeen'] != null
      ? DateTime.parse(json['lastSeen'] as String)
      : null,
  pump: PumpInfo.fromJson(json['pump'] as Map<String, dynamic>),
  sensors: (json['sensors'] as List)
      .map((s) => SensorInfo.fromJson(s as Map<String, dynamic>))
      .toList(),
  capabilities: (json['capabilities'] as List?)
      ?.cast<String>()
      .toSet() ?? {},
);
```

**D. Add Compatibility Checker Method**
```dart
/// Check if device data model version is compatible with app
bool isDataModelCompatible({String appVersion = '1.9.0'}) {
  if (dataModelVersion == null) {
    // Legacy firmware without version field - assume compatible for now
    return true;
  }
  
  // Parse semantic versions
  final deviceParts = dataModelVersion!.split('.').map(int.parse).toList();
  final appParts = appVersion.split('.').map(int.parse).toList();
  
  if (deviceParts.length < 2 || appParts.length < 2) {
    return false; // Invalid version format
  }
  
  // Major version must match
  if (deviceParts[0] != appParts[0]) {
    return false;
  }
  
  // Minor version: app must be >= device version
  if (appParts[1] < deviceParts[1]) {
    return false; // App is too old
  }
  
  return true;
}

/// Get human-readable compatibility message
String getCompatibilityMessage({String appVersion = '1.9.0'}) {
  if (dataModelVersion == null) {
    return 'Legacy firmware detected (no schema version)';
  }
  
  if (isDataModelCompatible(appVersion: appVersion)) {
    return 'Schema compatible: Device $dataModelVersion, App $appVersion';
  }
  
  return 'INCOMPATIBLE: Device schema $dataModelVersion does not match app $appVersion';
}
```

**Testing:**
- Unit tests for compatibility checker logic
- Test with null `dataModelVersion` (backward compatibility)
- Test various version combinations (1.8.0, 1.9.0, 2.0.0, etc.)

**Estimated Time:** 30 minutes  
**Risk Level:** LOW (nullable field, backward compatible)

---

### 2.2 Update Info Panel UI

**File:** `lib/widgets/panels/info_panel.dart`

**Location:** Device info display section (line ~130)

**Add Display Row:**
```dart
_InfoRow(
  label: 'Firmware',
  value: deviceInfo.firmwareVersion,
  labelStyle: labelStyle,
  valueStyle: valueStyle,
),
const SizedBox(height: 10),
_InfoRow(
  label: 'Schema Version',  // ✅ ADD THIS
  value: deviceInfo.dataModelVersion ?? 'Unknown',
  labelStyle: labelStyle,
  valueStyle: valueStyle,
),
```

**Optional: Add Compatibility Indicator**
```dart
const SizedBox(height: 10),
_InfoRow(
  label: 'Compatibility',
  value: deviceInfo.getCompatibilityMessage(),
  labelStyle: labelStyle,
  valueStyle: deviceInfo.isDataModelCompatible() 
      ? valueStyle 
      : valueStyle.copyWith(color: Colors.orange),
),
```

**Testing:**
- Verify field displays correctly
- Check layout doesn't overflow
- Test with null value (shows "Unknown")

**Estimated Time:** 10 minutes  
**Risk Level:** LOW (UI only)

---

### 2.3 Add Connection-Time Validation (Optional but Recommended)

**File:** `lib/services/ble_service.dart`

**Location:** After DeviceInfo is parsed (line ~314 and ~337)

**Add Validation Logic:**
```dart
void _onDeviceInfoNotification(List<int> data) {
  // ... existing buffer accumulation code ...
  
  if (data.isEmpty) {
    // Complete transmission - parse JSON
    if (_deviceInfoBuffer.isEmpty) return;

    try {
      final jsonString = utf8.decode(_deviceInfoBuffer);
      final json = jsonDecode(jsonString);
      _deviceInfo = DeviceInfo.fromJson(json);
      
      // ✅ ADD COMPATIBILITY CHECK
      _checkDataModelCompatibility(_deviceInfo!);
      
      _deviceInfoController.add(_deviceInfo!);
      print("Device Info Received: ${_deviceInfo!.deviceName}");
      _deviceInfoBuffer.clear();
    } catch (e) {
      print("Error parsing Device Info: $e");
      _deviceInfoBuffer.clear();
    }
  } else {
    // Continue accumulating
    _deviceInfoBuffer.addAll(data);
  }
}

// ✅ ADD THIS METHOD
void _checkDataModelCompatibility(DeviceInfo deviceInfo) {
  const appVersion = '1.9.0'; // Could be loaded from pubspec or constant
  
  if (!deviceInfo.isDataModelCompatible(appVersion: appVersion)) {
    print('⚠️ WARNING: Data model version mismatch!');
    print('   Device: ${deviceInfo.dataModelVersion}');
    print('   App: $appVersion');
    print('   ${deviceInfo.getCompatibilityMessage(appVersion: appVersion)}');
    
    // Optional: Add to status stream or show user warning
    // _compatibilityWarningController.add(deviceInfo.getCompatibilityMessage());
  } else if (deviceInfo.dataModelVersion != null) {
    print('✅ Data model compatible: Device ${deviceInfo.dataModelVersion}, App $appVersion');
  }
}
```

**Optional: Add User Warning Stream**
```dart
// At top of BLEService class
final _compatibilityWarningController = StreamController<String>.broadcast();
Stream<String> get compatibilityWarningStream => _compatibilityWarningController.stream;

// In _checkDataModelCompatibility:
if (!deviceInfo.isDataModelCompatible(appVersion: appVersion)) {
  _compatibilityWarningController.add(
    'Device schema version ${deviceInfo.dataModelVersion} may be incompatible with app version $appVersion'
  );
}
```

**Testing:**
- Connect with updated firmware (should show compatible)
- Mock incompatible version to test warnings
- Verify logs show appropriate messages

**Estimated Time:** 20 minutes  
**Risk Level:** LOW (logging/warning only)

---

### 2.4 Update Constants File (Optional)

**File:** Create `lib/config/schema_version.dart`

**Content:**
```dart
/// PneumaGe Master Schema version supported by this app
const String kSchemaVersion = '1.9.0';

/// Parse semantic version string to [major, minor, patch]
List<int> parseVersion(String version) {
  try {
    return version.split('.').map(int.parse).toList();
  } catch (e) {
    return [0, 0, 0];
  }
}

/// Check if device schema version is compatible with app
bool isSchemaCompatible(String? deviceVersion, {String appVersion = kSchemaVersion}) {
  if (deviceVersion == null) return true; // Legacy firmware
  
  final deviceParts = parseVersion(deviceVersion);
  final appParts = parseVersion(appVersion);
  
  // Major version must match
  if (deviceParts[0] != appParts[0]) return false;
  
  // App minor version must be >= device minor version
  if (appParts[1] < deviceParts[1]) return false;
  
  return true;
}
```

**Testing:**
- Unit tests for version parsing
- Test various version strings

**Estimated Time:** 15 minutes  
**Risk Level:** LOW (utility functions)

---

### 2.5 Update Measurement Creation (Future Enhancement)

**File:** `lib/models/measurement.dart`

**Location:** `PneumaGeRecordFactory.createLiveMeasurement()` (line ~838)

**Future Enhancement:** Store device's dataModelVersion in Provenance
```dart
static PneumaGeRecord createLiveMeasurement({
  // ... existing parameters ...
  String? dataModelVersion,  // Add this parameter
  // ...
}) {
  return PneumaGeRecord(
    version: dataModelVersion ?? '1.9.0',  // Use device's version if available
    // ...
    provenance: Provenance(
      // ... existing fields ...
      firmwareVersion: firmwareVersion,
      // Note: dataModelVersion is stored at top level, not in provenance
    ),
    // ...
  );
}
```

**Note:** This is for future consistency. The measurement record already has a top-level `version` field that represents the schema version.

**Estimated Time:** 10 minutes  
**Risk Level:** LOW (optional improvement)

---

## Phase 3: Testing & Validation

### 3.1 Unit Tests

**File:** `test/models/device_test.dart` (create if doesn't exist)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pneumage_app/models/device.dart';

void main() {
  group('DeviceInfo dataModelVersion', () {
    test('parses dataModelVersion from JSON', () {
      final json = {
        'deviceId': 'test-123',
        'deviceName': 'Test Device',
        'descriptorVersion': 1,
        'processorMake': 'Arduino',
        'processorModel': 'Nano 33 BLE',
        'processorSerial': 'ABC123',
        'firmwareVersion': '1.2.0',
        'dataModelVersion': '1.9.0',
        'pump': {'make': 'Boxer', 'model': '22KD', 'serialNumber': 'P001'},
        'sensors': [],
      };

      final device = DeviceInfo.fromJson(json);
      expect(device.dataModelVersion, '1.9.0');
    });

    test('handles missing dataModelVersion (backward compatibility)', () {
      final json = {
        'deviceId': 'test-123',
        'deviceName': 'Test Device',
        'descriptorVersion': 1,
        'processorMake': 'Arduino',
        'processorModel': 'Nano 33 BLE',
        'processorSerial': 'ABC123',
        'firmwareVersion': '1.2.0',
        // dataModelVersion omitted
        'pump': {'make': 'Boxer', 'model': '22KD', 'serialNumber': 'P001'},
        'sensors': [],
      };

      final device = DeviceInfo.fromJson(json);
      expect(device.dataModelVersion, isNull);
      expect(device.isDataModelCompatible(), isTrue); // Should still be compatible
    });

    test('compatibility check: matching versions', () {
      final device = DeviceInfo.fromJson({
        'deviceId': 'test-123',
        'deviceName': 'Test',
        'descriptorVersion': 1,
        'processorMake': 'Arduino',
        'processorModel': 'Nano',
        'processorSerial': 'ABC',
        'firmwareVersion': '1.2.0',
        'dataModelVersion': '1.9.0',
        'pump': {'make': 'B', 'model': 'M', 'serialNumber': 'S'},
        'sensors': [],
      });

      expect(device.isDataModelCompatible(appVersion: '1.9.0'), isTrue);
    });

    test('compatibility check: app newer minor version', () {
      final device = DeviceInfo.fromJson({
        'deviceId': 'test-123',
        'deviceName': 'Test',
        'descriptorVersion': 1,
        'processorMake': 'Arduino',
        'processorModel': 'Nano',
        'processorSerial': 'ABC',
        'firmwareVersion': '1.2.0',
        'dataModelVersion': '1.8.0',
        'pump': {'make': 'B', 'model': 'M', 'serialNumber': 'S'},
        'sensors': [],
      });

      expect(device.isDataModelCompatible(appVersion: '1.9.0'), isTrue);
    });

    test('compatibility check: major version mismatch', () {
      final device = DeviceInfo.fromJson({
        'deviceId': 'test-123',
        'deviceName': 'Test',
        'descriptorVersion': 1,
        'processorMake': 'Arduino',
        'processorModel': 'Nano',
        'processorSerial': 'ABC',
        'firmwareVersion': '1.2.0',
        'dataModelVersion': '2.0.0',
        'pump': {'make': 'B', 'model': 'M', 'serialNumber': 'S'},
        'sensors': [],
      });

      expect(device.isDataModelCompatible(appVersion: '1.9.0'), isFalse);
    });

    test('compatibility check: app too old', () {
      final device = DeviceInfo.fromJson({
        'deviceId': 'test-123',
        'deviceName': 'Test',
        'descriptorVersion': 1,
        'processorMake': 'Arduino',
        'processorModel': 'Nano',
        'processorSerial': 'ABC',
        'firmwareVersion': '1.2.0',
        'dataModelVersion': '1.10.0',
        'pump': {'make': 'B', 'model': 'M', 'serialNumber': 'S'},
        'sensors': [],
      });

      expect(device.isDataModelCompatible(appVersion: '1.9.0'), isFalse);
    });
  });
}
```

### 3.2 Integration Tests

**Test Cases:**
1. ✅ Connect to updated firmware → verify version displays
2. ✅ Connect to old firmware (no version) → verify no errors
3. ✅ Mock incompatible version → verify warning appears
4. ✅ Export measurement → verify version in JSON
5. ✅ Import measurement → verify version preserved

### 3.3 Manual Testing Checklist

- [ ] Arduino firmware compiles successfully
- [ ] Device Info characteristic sends complete JSON
- [ ] App receives and parses dataModelVersion
- [ ] Info panel displays schema version
- [ ] Compatibility check logs appear in console
- [ ] Old firmware (without field) still works
- [ ] No crashes or errors during connection
- [ ] JSON export includes version information

---

## Phase 4: Documentation Updates

### 4.1 Update Arduino README

**File:** `pneuma-core/README.md`

Add to BLE Characteristics table:
```markdown
| **Device Info**     | `...0007` | Notify       | Streamed device JSON (includes dataModelVersion: "1.9.0") |
```

### 4.2 Update Requirements

**File:** `pneuma-core/REQUIREMENTS.md`

Update DeviceInfo structure:
```markdown
### Device Info JSON Structure (0x0007)
```json
{
  "firmwareVersion": "1.2.0",
  "dataModelVersion": "1.9.0",  // NEW: Schema version
  "sensors": [...]
}
```
```

### 4.3 Update Cross-Platform Strategy Doc

**File:** `CROSS_PLATFORM_DATA_MODEL_STRATEGIES.md`

Already updated! ✅ (Section 5.2 shows the enhancement)

---

## Phase 5: Deployment & Rollout

### 5.1 Version Compatibility Matrix

| Firmware | Data Model | App Version | Compatible? | Notes |
|:---------|:-----------|:------------|:------------|:------|
| 1.0.0-1.1.x | (none) | 1.9.0+ | ✅ Yes | Legacy mode, assumes compatible |
| 1.2.0+ | 1.9.0 | 1.9.0+ | ✅ Yes | Full compatibility checking |
| 2.0.0+ | 2.0.0 | 1.9.0 | ❌ No | Major version mismatch |
| 1.10.0 | 1.10.0 | 1.9.0 | ❌ No | App too old |

### 5.2 Rollout Strategy

1. **Week 1:** Deploy firmware update with dataModelVersion
2. **Week 2:** Deploy app update with parsing (maintains backward compatibility)
3. **Week 3:** Monitor for any compatibility issues
4. **Week 4:** Enable validation warnings for users

---

## Summary

### Files to Modify:

**Arduino (1 file):**
- ✅ `pneuma-core/pneuma-core.ino` - Add version to DeviceInfo JSON

**Flutter App (4-6 files):**
- ✅ `lib/models/device.dart` - Add field, parsing, validation
- ✅ `lib/widgets/panels/info_panel.dart` - Display version
- ✅ `lib/services/ble_service.dart` - Add compatibility logging
- ⭕ `lib/config/schema_version.dart` - (Optional) Constants
- ⭕ `lib/models/measurement.dart` - (Optional) Future enhancement
- ✅ `test/models/device_test.dart` - Unit tests

**Documentation (3 files):**
- ✅ `pneuma-core/README.md` - Update BLE characteristic docs
- ✅ `pneuma-core/REQUIREMENTS.md` - Update DeviceInfo structure
- ✅ Already updated: `CROSS_PLATFORM_DATA_MODEL_STRATEGIES.md`

### Total Effort Estimate:
- **Arduino:** 5 minutes
- **Flutter App:** 1-2 hours (including tests)
- **Documentation:** 15 minutes
- **Total:** ~2-2.5 hours

### Risk Assessment: **LOW**
- All changes are additive (no breaking changes)
- Backward compatible with old firmware
- Field is nullable for graceful degradation
- Comprehensive test coverage planned

---

## Next Steps

1. ✅ Review this plan
2. ⬜ Implement Arduino firmware change
3. ⬜ Test with nRF Connect
4. ⬜ Implement Flutter model changes
5. ⬜ Write unit tests
6. ⬜ Update UI
7. ⬜ Integration testing
8. ⬜ Update documentation
9. ⬜ Deploy

---

*Plan created: May 18, 2026*
