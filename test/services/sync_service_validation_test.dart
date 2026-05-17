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
import 'package:pneumage_app/config/schema_version.dart';
import 'package:pneumage_app/models/measurement.dart';

void main() {
  group('Sync Service Schema Validation', () {
    // Helper to create a valid test record using the factory
    PneumaGeRecord createValidRecord({
      String? version,
      String? recordUuid,
      String? creator,
      List<String>? channelNames,
      bool addSamples = true,
    }) {
      var record = PneumaGeRecordFactory.createLiveMeasurement(
        projectId: 'test-project',
        operatorId: creator ?? 'Test Operator',
        systemId: 'test-system',
        latitude: 45.0,
        longitude: -122.0,
        elevation: 100.0,
        channelNames: channelNames ?? ['CO2'],
        creatorName: creator,
      );

      // Override version/recordUuid BEFORE adding samples
      if (version != null || recordUuid != null) {
        record = PneumaGeRecord(
          version: version ?? record.version,
          recordUuid: recordUuid ?? record.recordUuid,
          provenance: record.provenance,
          siteContext: record.siteContext,
          measurementCycle: record.measurementCycle,
        );
      }

      // Add sample data if requested (after overrides)
      if (addSamples && (channelNames ?? ['CO2']).isNotEmpty) {
        // Add to rawData (validation checks rawData.samples)
        final sampleValues = <String, double>{};
        for (final channel in channelNames ?? ['CO2']) {
          sampleValues[channel] = 400.0; // Default test value
        }
        
        record = PneumaGeRecordFactory.addSample(
          record,
          DateTime.now(),
          sampleValues,
          useFiltered: false, // Add to rawData
        );
      }

      return record;
    }

    group('_validateRecordSchema (pre-upload)', () {
      test('valid record with samples passes all checks', () {
        final record = createValidRecord(addSamples: true);

        // Should not throw
        expect(() => _validateRecordSchemaStandalone(record), returnsNormally);
      });

      test('throws on schema version mismatch', () {
        final record = createValidRecord(version: '2.0.0');

        expect(
          () => _validateRecordSchemaStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Schema version mismatch'),
            ),
          ),
        );
      });

      test('throws on missing recordUuid', () {
        final record = createValidRecord(recordUuid: '');

        expect(
          () => _validateRecordSchemaStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('missing recordUuid'),
            ),
          ),
        );
      });

      test('throws on no flux channels', () {
        final record = createValidRecord(channelNames: []);

        expect(
          () => _validateRecordSchemaStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('no flux channels'),
            ),
          ),
        );
      });

      test('throws on empty sample data', () {
        final record = createValidRecord(addSamples: false);

        expect(
          () => _validateRecordSchemaStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('no raw sample data'),
            ),
          ),
        );
      });

      test('throws on missing sample format', () {
        var record = createValidRecord(addSamples: true);
        
        // Manually create a channel with empty sample format
        final badChannel = FluxChannel(
          targetGas: 'CO2',
          sensorReference: 'Test',
          calibration: record.measurementCycle.channels.first.calibration,
          algorithms: {},
          rawData: ChannelData(
            sampleFormat: [], // Empty format!
            samples: [[123, 400.0, 20.0, 101325.0]],
            calculatedFlux: record.measurementCycle.channels.first.rawData.calculatedFlux,
          ),
          filteredData: record.measurementCycle.channels.first.filteredData,
        );

        record = PneumaGeRecord(
          version: record.version,
          recordUuid: record.recordUuid,
          provenance: record.provenance,
          siteContext: record.siteContext,
          measurementCycle: MeasurementCycle(
            cycleId: record.measurementCycle.cycleId,
            timestampStart: record.measurementCycle.timestampStart,
            chamberVolumeM3: record.measurementCycle.chamberVolumeM3,
            systemVolumeM3: record.measurementCycle.systemVolumeM3,
            systemVitals: record.measurementCycle.systemVitals,
            channels: [badChannel],
          ),
        );

        expect(
          () => _validateRecordSchemaStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('missing sample format'),
            ),
          ),
        );
      });

      test('throws on sample length mismatch', () {
        var record = createValidRecord(addSamples: true);
        
        // Manually create a channel with mismatched sample
        final badChannel = FluxChannel(
          targetGas: 'CO2',
          sensorReference: 'Test',
          calibration: record.measurementCycle.channels.first.calibration,
          algorithms: {},
          rawData: ChannelData(
            sampleFormat: ['timestamp_ms', 'concentration_ppm', 'temp_c', 'pressure_pa'],
            samples: [
              [123, 400.0], // Wrong length! Should be 4 elements
            ],
            calculatedFlux: record.measurementCycle.channels.first.rawData.calculatedFlux,
          ),
          filteredData: record.measurementCycle.channels.first.filteredData,
        );

        record = PneumaGeRecord(
          version: record.version,
          recordUuid: record.recordUuid,
          provenance: record.provenance,
          siteContext: record.siteContext,
          measurementCycle: MeasurementCycle(
            cycleId: record.measurementCycle.cycleId,
            timestampStart: record.measurementCycle.timestampStart,
            chamberVolumeM3: record.measurementCycle.chamberVolumeM3,
            systemVolumeM3: record.measurementCycle.systemVolumeM3,
            systemVitals: record.measurementCycle.systemVitals,
            channels: [badChannel],
          ),
        );

        expect(
          () => _validateRecordSchemaStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('sample 0 has 2 values'),
                contains('expected 4'),
              ),
            ),
          ),
        );
      });

      test('throws on missing creator', () {
        var record = createValidRecord(creator: '', addSamples: false);
        
        // Manually add samples to rawData so we test creator check, not sample check
        final channel = record.measurementCycle.channels.first;
        final updatedChannel = FluxChannel(
          targetGas: channel.targetGas,
          sensorReference: channel.sensorReference,
          calibration: channel.calibration,
          algorithms: channel.algorithms,
          rawData: ChannelData(
            sampleFormat: channel.rawData.sampleFormat,
            samples: [[1000, 400.0, 20.0, 101325.0]], // Add one sample
            calculatedFlux: channel.rawData.calculatedFlux,
          ),
          filteredData: channel.filteredData,
        );
        
        record = PneumaGeRecord(
          version: record.version,
          recordUuid: record.recordUuid,
          provenance: record.provenance,
          siteContext: record.siteContext,
          measurementCycle: MeasurementCycle(
            cycleId: record.measurementCycle.cycleId,
            timestampStart: record.measurementCycle.timestampStart,
            chamberVolumeM3: record.measurementCycle.chamberVolumeM3,
            systemVolumeM3: record.measurementCycle.systemVolumeM3,
            systemVitals: record.measurementCycle.systemVitals,
            channels: [updatedChannel],
          ),
        );

        expect(
          () => _validateRecordSchemaStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('missing provenance.creator'),
            ),
          ),
        );
      });

      test('validates multiple channels correctly', () {
        final record = createValidRecord(
          channelNames: ['CO2', 'CH4'],
          addSamples: true,
        );

        // Should not throw
        expect(() => _validateRecordSchemaStandalone(record), returnsNormally);
      });
    });

    group('_validateRestoredRecord (post-restore)', () {
      test('valid record passes all checks', () {
        final record = createValidRecord(addSamples: true);

        // Should not throw
        expect(() => _validateRestoredRecordStandalone(record), returnsNormally);
      });

      test('compatible older version passes', () {
        final record = createValidRecord(version: '1.8.0', addSamples: true);

        // Should not throw (app 1.9.0 can handle 1.8.0)
        expect(() => _validateRestoredRecordStandalone(record), returnsNormally);
      });

      test('throws on incompatible newer minor version', () {
        final record = createValidRecord(version: '1.10.0', addSamples: true);

        expect(
          () => _validateRestoredRecordStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Incompatible schema version'),
            ),
          ),
        );
      });

      test('throws on incompatible major version', () {
        final record = createValidRecord(version: '2.0.0', addSamples: true);

        expect(
          () => _validateRestoredRecordStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Incompatible schema version'),
            ),
          ),
        );
      });

      test('throws on missing provenance', () {
        final record = createValidRecord(creator: '', addSamples: true);

        expect(
          () => _validateRestoredRecordStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Missing required provenance data'),
            ),
          ),
        );
      });

      test('throws on no flux channels', () {
        final record = createValidRecord(channelNames: []);

        expect(
          () => _validateRestoredRecordStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('No flux channels'),
            ),
          ),
        );
      });

      test('throws on channel with no data', () {
        final record = createValidRecord(addSamples: false);

        expect(
          () => _validateRestoredRecordStandalone(record),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('has no data'),
            ),
          ),
        );
      });

      test('validates records with domain-specific metadata', () {
        var record = PneumaGeRecordFactory.createLiveMeasurement(
          projectId: 'test-project',
          operatorId: 'Test Operator',
          systemId: 'test-system',
          latitude: 45.0,
          longitude: -122.0,
          channelNames: ['CO2'],
          activeDomain: 'AGRICULTURE',
          domainMetadata: {'crop_type': 'corn', 'soil_type': 'loam'},
        );

        record = PneumaGeRecordFactory.addSample(
          record,
          DateTime.now(),
          {'CO2': 400.0},
          useFiltered: false, // Add to rawData
        );

        // Should not throw
        expect(() => _validateRestoredRecordStandalone(record), returnsNormally);
      });
    });
  });
}

// Standalone validation functions mirroring SyncService private methods
// These are tested here to verify the validation logic without mocking Firebase

void _validateRecordSchemaStandalone(PneumaGeRecord measurement) {
  // Check schema version compatibility
  if (measurement.version != kSchemaVersion) {
    throw StateError(
      'Schema version mismatch: Record is ${measurement.version}, '
      'but app expects $kSchemaVersion. Cannot sync incompatible data.'
    );
  }
  
  // Validate required fields
  if (measurement.recordUuid.isEmpty) {
    throw StateError('Invalid record: missing recordUuid');
  }
  
  if (measurement.measurementCycle.channels.isEmpty) {
    throw StateError('Invalid record: no flux channels defined');
  }
  
  // Validate data integrity for each channel
  for (final channel in measurement.measurementCycle.channels) {
    // Check that channel has sample data
    if (channel.rawData.samples.isEmpty) {
      throw StateError(
        'Invalid channel ${channel.targetGas}: no raw sample data'
      );
    }
    
    // Validate sample format is defined
    if (channel.rawData.sampleFormat.isEmpty) {
      throw StateError(
        'Invalid channel ${channel.targetGas}: missing sample format'
      );
    }
    
    // Validate all samples match the format length
    final expectedLength = channel.rawData.sampleFormat.length;
    for (var i = 0; i < channel.rawData.samples.length; i++) {
      if (channel.rawData.samples[i].length != expectedLength) {
        throw StateError(
          'Invalid channel ${channel.targetGas}: '
          'sample $i has ${channel.rawData.samples[i].length} values, '
          'expected $expectedLength (matching sample_format)'
        );
      }
    }
  }
  
  // Validate provenance exists
  if (measurement.provenance.creator.isEmpty) {
    throw StateError('Invalid record: missing provenance.creator');
  }
}

void _validateRestoredRecordStandalone(PneumaGeRecord record) {
  // Check version compatibility using semantic versioning
  if (!isSchemaCompatible(record.version, appVersion: kSchemaVersion)) {
    throw StateError(
      'Incompatible schema version ${record.version} '
      '(app supports $kSchemaVersion)'
    );
  }
  
  // Validate required data structures exist
  if (record.provenance.creator.isEmpty) {
    throw StateError('Missing required provenance data');
  }
  
  // Check for required measurement data
  if (record.measurementCycle.channels.isEmpty) {
    throw StateError('No flux channels in measurement');
  }
  
  // Basic data integrity check
  for (final channel in record.measurementCycle.channels) {
    if (channel.rawData.samples.isEmpty) {
      throw StateError('Channel ${channel.targetGas} has no data');
    }
  }
}
