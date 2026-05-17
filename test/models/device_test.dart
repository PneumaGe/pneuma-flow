// Copyright 2026 PneumaGe Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter_test/flutter_test.dart';
import 'package:pneumage_app/models/device.dart';

void main() {
  group('DeviceInfo dataModelVersion', () {
    // Helper to create minimal DeviceInfo JSON
    Map<String, dynamic> createDeviceJson({String? dataModelVersion}) {
      return {
        'deviceId': 'test-123',
        'deviceName': 'Test Device',
        'descriptorVersion': 1,
        'processorMake': 'Arduino',
        'processorModel': 'Nano 33 BLE',
        'processorSerial': 'ABC123',
        'firmwareVersion': '1.2.0',
        if (dataModelVersion != null) 'dataModelVersion': dataModelVersion,
        'pump': {
          'make': 'Boxer',
          'model': '22KD',
          'serialNumber': 'P001',
          'flowRateMin': 0.1,
          'flowRateMax': 1.0,
        },
        'sensors': [],
      };
    }

    test('parses dataModelVersion from JSON', () {
      final json = createDeviceJson(dataModelVersion: '1.9.0');
      final device = DeviceInfo.fromJson(json);
      
      expect(device.dataModelVersion, '1.9.0');
    });

    test('handles missing dataModelVersion (backward compatibility)', () {
      final json = createDeviceJson(); // No dataModelVersion
      final device = DeviceInfo.fromJson(json);
      
      expect(device.dataModelVersion, isNull);
      expect(device.isDataModelCompatible(), isTrue); // Should still be compatible
    });

    test('includes dataModelVersion in toJson', () {
      final json = createDeviceJson(dataModelVersion: '1.9.0');
      final device = DeviceInfo.fromJson(json);
      final output = device.toJson();
      
      expect(output['dataModelVersion'], '1.9.0');
    });

    test('omits dataModelVersion from toJson when null', () {
      final json = createDeviceJson(); // No dataModelVersion
      final device = DeviceInfo.fromJson(json);
      final output = device.toJson();
      
      expect(output.containsKey('dataModelVersion'), isFalse);
    });

    group('compatibility checking', () {
      test('matching versions are compatible', () {
        final json = createDeviceJson(dataModelVersion: '1.9.0');
        final device = DeviceInfo.fromJson(json);
        
        expect(device.isDataModelCompatible(appVersion: '1.9.0'), isTrue);
      });

      test('app newer minor version is compatible', () {
        final json = createDeviceJson(dataModelVersion: '1.8.0');
        final device = DeviceInfo.fromJson(json);
        
        expect(device.isDataModelCompatible(appVersion: '1.9.0'), isTrue);
      });

      test('device newer minor version is incompatible', () {
        final json = createDeviceJson(dataModelVersion: '1.10.0');
        final device = DeviceInfo.fromJson(json);
        
        expect(device.isDataModelCompatible(appVersion: '1.9.0'), isFalse);
      });

      test('major version mismatch is incompatible', () {
        final json = createDeviceJson(dataModelVersion: '2.0.0');
        final device = DeviceInfo.fromJson(json);
        
        expect(device.isDataModelCompatible(appVersion: '1.9.0'), isFalse);
      });

      test('device older major version is incompatible', () {
        final json = createDeviceJson(dataModelVersion: '0.9.0');
        final device = DeviceInfo.fromJson(json);
        
        expect(device.isDataModelCompatible(appVersion: '1.9.0'), isFalse);
      });

      test('patch versions do not affect compatibility', () {
        final json = createDeviceJson(dataModelVersion: '1.9.5');
        final device = DeviceInfo.fromJson(json);
        
        expect(device.isDataModelCompatible(appVersion: '1.9.0'), isTrue);
      });

      test('null version (legacy firmware) is compatible', () {
        final json = createDeviceJson(); // No dataModelVersion
        final device = DeviceInfo.fromJson(json);
        
        expect(device.isDataModelCompatible(appVersion: '1.9.0'), isTrue);
      });

      test('invalid device version format is incompatible', () {
        final json = createDeviceJson(dataModelVersion: 'invalid');
        final device = DeviceInfo.fromJson(json);
        
        expect(device.isDataModelCompatible(appVersion: '1.9.0'), isFalse);
      });
    });

    group('compatibility messages', () {
      test('returns message for matching versions', () {
        final json = createDeviceJson(dataModelVersion: '1.9.0');
        final device = DeviceInfo.fromJson(json);
        
        final message = device.getCompatibilityMessage(appVersion: '1.9.0');
        expect(message, contains('compatible'));
        expect(message, contains('1.9.0'));
      });

      test('returns message for incompatible versions', () {
        final json = createDeviceJson(dataModelVersion: '2.0.0');
        final device = DeviceInfo.fromJson(json);
        
        final message = device.getCompatibilityMessage(appVersion: '1.9.0');
        expect(message.toUpperCase(), contains('INCOMPATIBLE'));
      });

      test('returns message for legacy firmware', () {
        final json = createDeviceJson(); // No dataModelVersion
        final device = DeviceInfo.fromJson(json);
        
        final message = device.getCompatibilityMessage(appVersion: '1.9.0');
        expect(message.toLowerCase(), contains('legacy'));
      });

      test('returns message for app too old', () {
        final json = createDeviceJson(dataModelVersion: '1.10.0');
        final device = DeviceInfo.fromJson(json);
        
        final message = device.getCompatibilityMessage(appVersion: '1.9.0');
        expect(message.toUpperCase(), contains('INCOMPATIBLE'));
      });
    });
  });
}
