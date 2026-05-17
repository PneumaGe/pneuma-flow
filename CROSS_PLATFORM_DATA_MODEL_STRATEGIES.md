# Cross-Platform Data Model Strategies for PneumaGe

**Last Updated:** May 17, 2026  
**Context:** Achieving consistency between Arduino firmware and Flutter app data models

---

## Overview

The PneumaGe system spans two platforms:
- **Microcontroller (Arduino Nano 33 BLE)**: Embedded C++ firmware with BLE GATT characteristics
- **Mobile App (Flutter/Dart)**: PneumaGe Master Schema v1.9.0 with hierarchical data structures

This document outlines strategies to maintain data model consistency, versioning, and interoperability across these platforms.

---

## Strategy 1: JSON Schema Definition

### Concept
Define a single source of truth as a JSON Schema that describes the complete data model. Both platforms consume this schema to generate their respective code.

### Implementation

#### 1.1 Create Master JSON Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "PneumaGe Master Schema",
  "version": "1.9.0",
  "description": "Complete data model for PneumaGe soil gas flux measurements",
  "type": "object",
  "required": ["version", "record_uuid", "provenance", "site_context", "measurement_cycle"],
  "properties": {
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$",
      "description": "Schema version (semantic versioning)"
    },
    "record_uuid": {
      "type": "string",
      "format": "uuid",
      "description": "Unique identifier for this measurement record"
    },
    "provenance": {"$ref": "#/definitions/Provenance"},
    "site_context": {"$ref": "#/definitions/SiteContext"},
    "measurement_cycle": {"$ref": "#/definitions/MeasurementCycle"}
  },
  "definitions": {
    "Provenance": {
      "type": "object",
      "required": ["creator", "organization", "project", "system_id"],
      "properties": {
        "creator": {"type": "string", "description": "Researcher name"},
        "organization": {"type": "string", "description": "Institution or research group"},
        "project": {"type": "string", "description": "Project identifier"},
        "operator_id": {"type": "string", "description": "Field operator ID"},
        "system_id": {"type": "string", "description": "Device serial or MAC address"},
        "compute_platform": {"type": "string", "description": "Hardware platform (e.g., Arduino Nano 33 BLE)"},
        "firmware_version": {"type": "string", "description": "Firmware semantic version"},
        "sensor_payload": {
          "type": "array",
          "items": {"$ref": "#/definitions/SensorPayload"}
        }
      }
    },
    "SensorPayload": {
      "type": "object",
      "required": ["type", "model"],
      "properties": {
        "type": {"type": "string", "description": "Sensor category (NDIR, PRESSURE, HUMIDITY)"},
        "model": {"type": "string", "description": "Sensor model identifier"},
        "serial": {"type": "string", "description": "Serial number"},
        "precision": {"type": "string", "description": "Measurement precision spec"}
      }
    },
    "SiteContext": {
      "type": "object",
      "required": ["coordinates", "environmental_data"],
      "properties": {
        "active_domain": {"type": "string", "enum": ["NONE", "AGRICULTURE", "ARCTIC", "MARITIME", "VOLCANOLOGY"]},
        "standards_compliance": {
          "type": "array",
          "items": {"type": "string"}
        },
        "coordinates": {"$ref": "#/definitions/Coordinates"},
        "environmental_data": {"$ref": "#/definitions/EnvironmentalData"},
        "domain_specifics": {"$ref": "#/definitions/DomainSpecifics"}
      }
    },
    "Coordinates": {
      "type": "object",
      "required": ["lat", "lon", "elevation_m"],
      "properties": {
        "lat": {"type": "number", "minimum": -90, "maximum": 90},
        "lon": {"type": "number", "minimum": -180, "maximum": 180},
        "elevation_m": {"type": "number", "description": "Altitude in meters"}
      }
    },
    "EnvironmentalData": {
      "type": "object",
      "properties": {
        "ambient_temp_c": {"type": "number", "description": "Air temperature in Celsius"},
        "barometric_pressure_pa": {"type": "number", "description": "Atmospheric pressure in Pascals"},
        "relative_humidity_pct": {"type": "number", "minimum": 0, "maximum": 100}
      }
    },
    "DomainSpecifics": {
      "type": "object",
      "properties": {
        "agriculture": {"type": "object", "additionalProperties": true},
        "arctic": {"type": "object", "additionalProperties": true},
        "maritime": {"type": "object", "additionalProperties": true},
        "volcanology": {"type": "object", "additionalProperties": true}
      }
    },
    "MeasurementCycle": {
      "type": "object",
      "required": ["cycle_id", "timestamp_start", "system_vitals", "channels"],
      "properties": {
        "cycle_id": {"type": "string", "description": "Unique cycle identifier"},
        "timestamp_start": {"type": "string", "format": "date-time"},
        "chamber_volume_m3": {"type": "number", "minimum": 0},
        "system_volume_m3": {"type": "number", "minimum": 0},
        "system_vitals": {"$ref": "#/definitions/SystemVitals"},
        "channels": {
          "type": "array",
          "items": {"$ref": "#/definitions/FluxChannel"}
        }
      }
    },
    "SystemVitals": {
      "type": "object",
      "required": ["battery_mv", "pump_pwm_duty_pct"],
      "properties": {
        "battery_mv": {"type": "integer", "minimum": 0, "description": "Battery voltage in millivolts"},
        "pump_pwm_duty_pct": {"type": "integer", "minimum": 0, "maximum": 100},
        "chamber_tilt_pitch": {"type": "number", "description": "Pitch angle in degrees"},
        "chamber_tilt_roll": {"type": "number", "description": "Roll angle in degrees"},
        "shock_detected": {"type": "boolean", "description": "IMU shock detection flag"}
      }
    },
    "FluxChannel": {
      "type": "object",
      "required": ["target_gas", "raw_data"],
      "properties": {
        "target_gas": {"type": "string", "description": "Gas species (CO2, CH4, etc.)"},
        "sensor_reference": {"type": "string", "description": "Reference to sensor in payload"},
        "calibration": {"$ref": "#/definitions/CalibrationData"},
        "algorithms": {"type": "object", "description": "Processing algorithm metadata"},
        "raw_data": {"$ref": "#/definitions/ChannelData"},
        "filtered_data": {"$ref": "#/definitions/ChannelData"}
      }
    },
    "CalibrationData": {
      "type": "object",
      "properties": {
        "curve_id": {"type": "string"},
        "type": {"type": "string", "description": "Calibration curve type (linear, polynomial)"},
        "coefficients": {
          "type": "array",
          "items": {"type": "number"}
        },
        "saturation_threshold_ppm": {"type": "number"},
        "last_calibrated": {"type": "string", "format": "date-time"}
      }
    },
    "ChannelData": {
      "type": "object",
      "required": ["sample_format", "samples", "calculated_flux"],
      "properties": {
        "sample_format": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Column headers for sample arrays (e.g., ['timestamp_ms', 'ppm'])"
        },
        "sample_count": {"type": "integer", "minimum": 0},
        "file_sha256": {"type": "string", "description": "Hash for data integrity"},
        "samples": {
          "type": "array",
          "items": {
            "type": "array",
            "description": "Row of values matching sample_format"
          }
        },
        "calculated_flux": {"$ref": "#/definitions/CalculatedFlux"}
      }
    },
    "CalculatedFlux": {
      "type": "object",
      "required": ["slope_ppm_s", "flux_rate_mg_m2_h", "r_squared"],
      "properties": {
        "boundary_left_s": {"type": "number", "description": "RANSAC fit start time (seconds)"},
        "boundary_right_s": {"type": "number", "description": "RANSAC fit end time (seconds)"},
        "slope_ppm_s": {"type": "number", "description": "Linear regression slope (ppm/s)"},
        "flux_rate_mg_m2_h": {"type": "number", "description": "Calculated flux (mg/m²/h)"},
        "flux_error": {"type": "number", "description": "Uncertainty estimate"},
        "r_squared": {"type": "number", "minimum": 0, "maximum": 1},
        "qa_qc_flag": {"type": "integer", "description": "Quality flag (0=good, >0=issues)"},
        "qa_qc_reason": {"type": "string"}
      }
    }
  }
}
```

#### 1.2 Example Exported JSON
Here's what an actual PneumaGe measurement looks like when exported:

```json
{
  "version": "1.9.0",
  "record_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "provenance": {
    "creator": "Dr. Jane Smith",
    "organization": "University Arctic Research Lab",
    "project": "Alaska Permafrost Study 2026",
    "operator_id": "JS-001",
    "system_id": "F4:12:FA:AB:CD:EF",
    "compute_platform": "Arduino Nano 33 BLE",
    "firmware_version": "1.2.0",
    "sensor_payload": [
      {
        "type": "NDIR",
        "model": "GSS SprintIR-W",
        "serial": "SPRINT-12345",
        "precision": "±30ppm"
      },
      {
        "type": "PRESSURE",
        "model": "Bosch BMP390"
      },
      {
        "type": "HUMIDITY",
        "model": "Sensirion SHT45"
      }
    ]
  },
  "site_context": {
    "active_domain": "ARCTIC",
    "standards_compliance": ["ISO-11083:2020"],
    "coordinates": {
      "lat": 68.9916,
      "lon": -133.7506,
      "elevation_m": 12.5
    },
    "environmental_data": {
      "ambient_temp_c": -2.3,
      "barometric_pressure_pa": 101325,
      "relative_humidity_pct": 75.2
    },
    "domain_specifics": {
      "agriculture": {},
      "arctic": {
        "permafrostDepth": 45,
        "activeLayerThickness": 65,
        "snowCoverDepth": 12,
        "thawStatus": "Thawing"
      },
      "maritime": {},
      "volcanology": {}
    }
  },
  "measurement_cycle": {
    "cycle_id": "20260517-143022-550e8400",
    "timestamp_start": "2026-05-17T14:30:22.000Z",
    "chamber_volume_m3": 0.025,
    "system_volume_m3": 0.028,
    "system_vitals": {
      "battery_mv": 3850,
      "pump_pwm_duty_pct": 60,
      "chamber_tilt_pitch": 0.5,
      "chamber_tilt_roll": -0.3,
      "shock_detected": false
    },
    "channels": [
      {
        "target_gas": "CO2",
        "sensor_reference": "SPRINT-12345",
        "calibration": {
          "curve_id": "factory-2024-03",
          "type": "linear",
          "coefficients": [1.0, 0.0],
          "saturation_threshold_ppm": 10000.0,
          "last_calibrated": "2024-03-15T10:00:00.000Z"
        },
        "algorithms": {
          "ransac_threshold": 50.0,
          "min_samples": 10
        },
        "raw_data": {
          "sample_format": ["timestamp_ms", "ppm"],
          "sample_count": 120,
          "samples": [
            [0, 420.5],
            [1000, 425.3],
            [2000, 431.8],
            [3000, 438.2],
            [4000, 445.1]
          ],
          "calculated_flux": {
            "boundary_left_s": 5.0,
            "boundary_right_s": 115.0,
            "slope_ppm_s": 0.084,
            "flux_rate_mg_m2_h": 156.3,
            "flux_error": 8.2,
            "r_squared": 0.987,
            "qa_qc_flag": 0,
            "qa_qc_reason": "good"
          }
        },
        "filtered_data": {
          "sample_format": ["timestamp_ms", "ppm"],
          "sample_count": 118,
          "samples": [
            [0, 420.5],
            [1000, 425.3],
            [2000, 431.8]
          ],
          "calculated_flux": {
            "boundary_left_s": 5.0,
            "boundary_right_s": 115.0,
            "slope_ppm_s": 0.086,
            "flux_rate_mg_m2_h": 159.1,
            "flux_error": 6.5,
            "r_squared": 0.992,
            "qa_qc_flag": 0,
            "qa_qc_reason": "good"
          }
        }
      }
    ]
  }
}
```

#### 1.3 Code Generation
- **Dart**: Use `json_serializable` or `freezed` to generate Flutter models
- **C++**: Use `quicktype` or custom scripts to generate structs
- **BLE Mapping**: Define explicit field-to-characteristic mappings

#### 1.4 Pros & Cons
**Pros:**
- Human-readable and well-documented
- Easy to validate against the schema
- Good tooling support (VSCode extensions, validators)
- Natural fit for JSON export/import

**Cons:**
- Requires build-time code generation
- JSON parsing overhead on microcontroller (if used for serialization)
- Schema updates require regenerating code on both platforms

---

## Strategy 2: Protocol Buffers (Protobuf)

### Concept
Use Protocol Buffers to define strongly-typed message formats that compile to efficient binary serialization for both platforms.

### Implementation

#### 2.1 Define .proto File
```protobuf
syntax = "proto3";

package pneumage;

// Top-level record matching PneumaGe Master Schema v1.9.0
message PneumaGeRecord {
  string version = 1;                    // Schema version (e.g., "1.9.0")
  string record_uuid = 2;                // Unique identifier
  Provenance provenance = 3;             // Attribution and hardware metadata
  SiteContext site_context = 4;          // Location and environmental context
  MeasurementCycle measurement_cycle = 5; // The actual measurement data
}

// ==========================================
// PROVENANCE & HARDWARE METADATA
// ==========================================

message Provenance {
  string creator = 1;                    // Researcher name
  string organization = 2;               // Institution or research group
  string project = 3;                    // Project identifier
  string operator_id = 4;                // Field operator ID
  string system_id = 5;                  // Device serial or MAC address
  string compute_platform = 6;           // Hardware platform (e.g., "Arduino Nano 33 BLE")
  string firmware_version = 7;           // Firmware semantic version
  repeated SensorPayload sensor_payload = 8; // Array of sensor specifications
}

message SensorPayload {
  string type = 1;        // Sensor category: "NDIR", "PRESSURE", "HUMIDITY", etc.
  string model = 2;       // Sensor model identifier (e.g., "SprintIR-W", "BMP390")
  string serial = 3;      // Serial number (optional)
  string precision = 4;   // Measurement precision spec (optional)
}

// ==========================================
// SITE CONTEXT & DOMAINS
// ==========================================

message SiteContext {
  string active_domain = 1;              // "NONE", "AGRICULTURE", "ARCTIC", "MARITIME", "VOLCANOLOGY"
  repeated string standards_compliance = 2; // e.g., ["ISO-11083:2020"]
  Coordinates coordinates = 3;           // GPS location
  EnvironmentalData environmental_data = 4; // Ambient conditions
  DomainSpecifics domain_specifics = 5;  // Domain-specific metadata
}

message Coordinates {
  double lat = 1;          // Latitude (-90 to 90)
  double lon = 2;          // Longitude (-180 to 180)
  double elevation_m = 3;  // Altitude in meters
}

message EnvironmentalData {
  double ambient_temp_c = 1;           // Air temperature in Celsius
  double barometric_pressure_pa = 2;   // Atmospheric pressure in Pascals
  double relative_humidity_pct = 3;    // Relative humidity (0-100%)
}

message DomainSpecifics {
  map<string, string> agriculture = 1;   // Agriculture-specific fields (key-value pairs)
  map<string, string> arctic = 2;        // Arctic-specific fields
  map<string, string> maritime = 3;      // Maritime-specific fields
  map<string, string> volcanology = 4;   // Volcanology-specific fields
}

// ==========================================
// MEASUREMENT CYCLE & MULTI-CHANNEL DATA
// ==========================================

message MeasurementCycle {
  string cycle_id = 1;                   // Unique cycle identifier
  int64 timestamp_start_ms = 2;          // Start time (milliseconds since epoch)
  double chamber_volume_m3 = 3;          // Chamber volume (cubic meters)
  double system_volume_m3 = 4;           // Total system volume including tubing
  SystemVitals system_vitals = 5;        // Real-time system health
  repeated FluxChannel channels = 6;     // Multi-channel measurement data (CO2, CH4, etc.)
}

message SystemVitals {
  uint32 battery_mv = 1;               // Battery voltage in millivolts
  uint32 pump_pwm_duty_pct = 2;        // Pump PWM duty cycle (0-100%)
  double chamber_tilt_pitch = 3;       // Pitch angle in degrees
  double chamber_tilt_roll = 4;        // Roll angle in degrees
  bool shock_detected = 5;             // IMU shock detection flag
}

message FluxChannel {
  string target_gas = 1;               // Gas species: "CO2", "CH4", "Temperature", "Pressure"
  string sensor_reference = 2;         // Reference to sensor in payload (e.g., serial number)
  CalibrationData calibration = 3;     // Calibration curve information
  map<string, double> algorithms = 4;  // Processing algorithm parameters (e.g., RANSAC threshold)
  ChannelData raw_data = 5;            // Unfiltered time series data
  ChannelData filtered_data = 6;       // Filtered time series data
}

message CalibrationData {
  string curve_id = 1;                 // Calibration curve identifier
  string type = 2;                     // Curve type: "linear", "polynomial", etc.
  repeated double coefficients = 3;    // Calibration coefficients
  double saturation_threshold_ppm = 4; // Sensor saturation limit
  int64 last_calibrated_ms = 5;        // Last calibration timestamp (ms since epoch)
}

message ChannelData {
  repeated string sample_format = 1;   // Column headers (e.g., ["timestamp_ms", "ppm"])
  uint32 sample_count = 2;             // Number of samples (optional, for redundancy checking)
  string file_sha256 = 3;              // Hash for data integrity (optional)
  repeated SampleRow samples = 4;      // Time series data
  CalculatedFlux calculated_flux = 5;  // RANSAC fit results
}

// Flexible row format to match sample_format
message SampleRow {
  repeated double values = 1;          // Array of values matching sample_format
}

message CalculatedFlux {
  double boundary_left_s = 1;          // RANSAC fit start time (seconds)
  double boundary_right_s = 2;         // RANSAC fit end time (seconds)
  double slope_ppm_s = 3;              // Linear regression slope (ppm/s)
  double flux_rate_mg_m2_h = 4;        // Calculated flux rate (mg/m²/h)
  double flux_error = 5;               // Uncertainty estimate
  double r_squared = 6;                // Coefficient of determination (0-1)
  int32 qa_qc_flag = 7;                // Quality flag (0=good, >0=issues)
  string qa_qc_reason = 8;             // Human-readable quality note
}
```

#### 2.2 Code Generation
```bash
# For C++ (Arduino) - using nanopb for embedded systems
protoc --nanopb_out=./src pneumage.proto

# For Dart (Flutter)
protoc --dart_out=./lib/models pneumage.proto
```

#### 2.3 Usage Examples

**Arduino (C++ with nanopb):**
```cpp
#include "pneumage.pb.h"
#include <pb_encode.h>

void createMeasurementRecord() {
    // Allocate message
    PneumaGeRecord record = PneumaGeRecord_init_zero;
    
    // Set version and UUID
    strcpy(record.version, "1.9.0");
    strcpy(record.record_uuid, "550e8400-e29b-41d4-a716-446655440000");
    
    // Populate provenance
    strcpy(record.provenance.creator, "Dr. Jane Smith");
    strcpy(record.provenance.system_id, deviceMacAddress);
    strcpy(record.provenance.firmware_version, FIRMWARE_VERSION);
    
    // Add sensor payload
    record.provenance.sensor_payload_count = 2;
    strcpy(record.provenance.sensor_payload[0].type, "NDIR");
    strcpy(record.provenance.sensor_payload[0].model, "SprintIR-W");
    
    // System vitals
    record.measurement_cycle.system_vitals.battery_mv = batteryVoltageMv;
    record.measurement_cycle.system_vitals.pump_pwm_duty_pct = pumpPwmPct;
    
    // Encode to binary
    uint8_t buffer[1024];
    pb_ostream_t stream = pb_ostream_from_buffer(buffer, sizeof(buffer));
    pb_encode(&stream, PneumaGeRecord_fields, &record);
    
    // Send over BLE or save to SD card
    size_t message_length = stream.bytes_written;
    sendData(buffer, message_length);
}
```

**Flutter (Dart):**
```dart
import 'pneumage.pb.dart';

Future<void> receiveMeasurement(List<int> data) async {
  // Decode protobuf binary
  final record = PneumaGeRecord.fromBuffer(data);
  
  // Access strongly-typed fields
  print('Version: ${record.version}');
  print('Creator: ${record.provenance.creator}');
  print('System ID: ${record.provenance.systemId}');
  
  // Process channels
  for (final channel in record.measurementCycle.channels) {
    print('Gas: ${channel.targetGas}');
    print('Flux: ${channel.rawData.calculatedFlux.fluxRateMgM2H} mg/m²/h');
    print('R²: ${channel.rawData.calculatedFlux.rSquared}');
    
    // Process samples
    for (final row in channel.rawData.samples) {
      final timestamp = row.values[0];
      final ppm = row.values[1];
      print('$timestamp ms: $ppm ppm');
    }
  }
  
  // Save to local database (Hive)
  await recordBox.add(record);
}
```

#### 2.4 BLE Integration
- **Option A**: Stream protobuf binary directly over BLE characteristics
- **Option B**: Use protobuf for internal representation, convert to packed structs for BLE
- **Option C**: Hybrid - use protobuf for complete records (export/sync), keep current BLE protocol for real-time streaming

#### 2.5 Pros & Cons
**Pros:**
- Extremely efficient binary serialization (minimal overhead)
- Strong typing with automatic validation
- Built-in versioning and backward compatibility
- Excellent cross-language support
- Smaller payload sizes (critical for BLE MTU limits)
- Field numbers allow schema evolution without breaking existing code

**Cons:**
- Adds complexity and build dependencies
- Limited memory on Arduino (nanopb library required with specific configuration)
- Less human-readable than JSON (requires protobuf tools to inspect)
- Debugging requires protobuf tools (protoc, protobuf inspector)
- Fixed array sizes needed for nanopb (must set `max_count` options)
- Learning curve for team members unfamiliar with protobuf

**Arduino-Specific Considerations:**
- Use nanopb (lightweight protobuf implementation for embedded systems)
- Define maximum array sizes in .proto file: `[(nanopb).max_count = 2000]`
- Careful memory management required (stack vs. heap allocation)
- Test with actual hardware to ensure memory constraints are met

---

## Strategy 3: FlatBuffers

### Concept
Similar to Protobuf but optimized for zero-copy access, ideal for memory-constrained embedded systems.

### Implementation

#### 3.1 Define .fbs Schema
```fbs
namespace PneumaGe;

// Top-level record
table PneumaGeRecord {
  version: string;
  record_uuid: string;
  provenance: Provenance;
  site_context: SiteContext;
  measurement_cycle: MeasurementCycle;
}

table Provenance {
  creator: string;
  organization: string;
  project: string;
  operator_id: string;
  system_id: string;
  compute_platform: string;
  firmware_version: string;
  sensor_payload: [SensorPayload];
}

table SensorPayload {
  type: string;
  model: string;
  serial: string;
  precision: string;
}

table SiteContext {
  active_domain: string;
  standards_compliance: [string];
  coordinates: Coordinates;
  environmental_data: EnvironmentalData;
  domain_specifics: DomainSpecifics;
}

table Coordinates {
  lat: double;
  lon: double;
  elevation_m: double;
}

table EnvironmentalData {
  ambient_temp_c: double;
  barometric_pressure_pa: double;
  relative_humidity_pct: double;
}

table DomainSpecifics {
  agriculture: [KeyValue];
  arctic: [KeyValue];
  maritime: [KeyValue];
  volcanology: [KeyValue];
}

table KeyValue {
  key: string;
  value: string;
}

table MeasurementCycle {
  cycle_id: string;
  timestamp_start_ms: int64;
  chamber_volume_m3: double;
  system_volume_m3: double;
  system_vitals: SystemVitals;
  channels: [FluxChannel];
}

table SystemVitals {
  battery_mv: uint32;
  pump_pwm_duty_pct: uint32;
  chamber_tilt_pitch: double;
  chamber_tilt_roll: double;
  shock_detected: bool;
}

table FluxChannel {
  target_gas: string;
  sensor_reference: string;
  calibration: CalibrationData;
  raw_data: ChannelData;
  filtered_data: ChannelData;
}

table CalibrationData {
  curve_id: string;
  type: string;
  coefficients: [double];
  saturation_threshold_ppm: double;
  last_calibrated_ms: int64;
}

table ChannelData {
  sample_format: [string];
  sample_count: uint32;
  file_sha256: string;
  samples: [SampleRow];
  calculated_flux: CalculatedFlux;
}

table SampleRow {
  values: [double];
}

table CalculatedFlux {
  boundary_left_s: double;
  boundary_right_s: double;
  slope_ppm_s: double;
  flux_rate_mg_m2_h: double;
  flux_error: double;
  r_squared: double;
  qa_qc_flag: int32;
  qa_qc_reason: string;
}

root_type PneumaGeRecord;
```

#### 3.2 Pros & Cons
**Pros:**
- Zero-copy access (no parsing overhead)
- Even more efficient than Protobuf for embedded systems
- Direct memory mapping

**Cons:**
- Less mature than Protobuf
- Steeper learning curve
- Fewer ecosystem tools

---

## Strategy 4: Shared Header Files with Code Generation

### Concept
Maintain a single C header file with struct definitions and use transpilation to generate Dart classes.

### Implementation

#### 4.1 Master Header File (pneumage_types.h)
```c
#ifndef PNEUMAGE_TYPES_H
#define PNEUMAGE_TYPES_H

#include <stdint.h>

#define SCHEMA_VERSION_MAJOR 1
#define SCHEMA_VERSION_MINOR 9
#define SCHEMA_VERSION_PATCH 0

// Maximum array sizes for fixed-size strings
#define MAX_STRING_LENGTH 64
#define MAX_SENSORS 8
#define MAX_CHANNELS 8
#define MAX_SAMPLES 2000

// ==========================================
// PROVENANCE & HARDWARE METADATA
// ==========================================

typedef struct {
    char type[32];      // "NDIR", "PRESSURE", "HUMIDITY"
    char model[64];     // "SprintIR-W", "BMP390", etc.
    char serial[32];    // Serial number
    char precision[32]; // Measurement precision spec
} SensorPayload;

typedef struct {
    char creator[MAX_STRING_LENGTH];
    char organization[MAX_STRING_LENGTH];
    char project[MAX_STRING_LENGTH];
    char operatorId[MAX_STRING_LENGTH];
    char systemId[MAX_STRING_LENGTH];      // MAC address or device ID
    char computePlatform[MAX_STRING_LENGTH]; // "Arduino Nano 33 BLE"
    char firmwareVersion[16];              // "1.2.0"
    SensorPayload sensors[MAX_SENSORS];
    uint8_t sensorCount;
} Provenance;

// ==========================================
// SITE CONTEXT & ENVIRONMENT
// ==========================================

typedef struct {
    double lat;
    double lon;
    double elevationM;
} Coordinates;

typedef struct {
    double ambientTempC;
    double barometricPressurePa;
    double relativeHumidityPct;
} EnvironmentalData;

typedef struct {
    char activeDomain[32];  // "AGRICULTURE", "ARCTIC", etc.
    Coordinates coordinates;
    EnvironmentalData environmentalData;
    // Domain-specific fields stored as JSON string for flexibility
    char domainMetadataJson[256];
} SiteContext;

// ==========================================
// MEASUREMENT CYCLE & DATA
// ==========================================

typedef struct {
    uint32_t batteryMv;           // Battery voltage in millivolts
    uint8_t pumpPwmDutyPct;       // PWM duty cycle (0-100%)
    float chamberTiltPitch;       // Pitch angle in degrees
    float chamberTiltRoll;        // Roll angle in degrees
    bool shockDetected;           // IMU shock flag
} SystemVitals;

typedef struct {
    char curveId[32];
    char type[16];                // "linear", "polynomial"
    double coefficients[8];       // Calibration coefficients
    uint8_t coefficientCount;
    double saturationThresholdPpm;
    uint64_t lastCalibratedMs;    // Unix timestamp
} CalibrationData;

typedef struct {
    double boundaryLeftS;
    double boundaryRightS;
    double slopePpmS;
    double fluxRateMgM2H;
    double fluxError;
    double rSquared;
    int32_t qaQcFlag;
    char qaQcReason[64];
} CalculatedFlux;

typedef struct {
    uint32_t timestampMs;         // Relative timestamp
    double value;                 // Concentration in ppm
} Sample;

typedef struct {
    char targetGas[16];           // "CO2", "CH4", etc.
    char sensorReference[32];     // Serial number reference
    CalibrationData calibration;
    
    // Raw data
    Sample rawSamples[MAX_SAMPLES];
    uint16_t rawSampleCount;
    CalculatedFlux rawFlux;
    
    // Filtered data
    Sample filteredSamples[MAX_SAMPLES];
    uint16_t filteredSampleCount;
    CalculatedFlux filteredFlux;
} FluxChannel;

typedef struct {
    char cycleId[MAX_STRING_LENGTH];
    uint64_t timestampStartMs;
    double chamberVolumeM3;
    double systemVolumeM3;
    SystemVitals systemVitals;
    FluxChannel channels[MAX_CHANNELS];
    uint8_t channelCount;
} MeasurementCycle;

// ==========================================
// TOP-LEVEL RECORD
// ==========================================

typedef struct {
    char version[16];             // "1.9.0"
    char recordUuid[37];          // UUID string
    Provenance provenance;
    SiteContext siteContext;
    MeasurementCycle measurementCycle;
} PneumaGeRecord;

#endif
```

#### 4.2 Transpilation Script
```python
#!/usr/bin/env python3
# generate_dart_models.py

def c_to_dart_type(c_type):
    mapping = {
        'uint8_t': 'int',
        'uint16_t': 'int',
        'uint32_t': 'int',
        'int32_t': 'int',
        'float': 'double',
        'char[]': 'String',
    }
    return mapping.get(c_type, 'dynamic')

def parse_header_and_generate_dart(header_path, output_path):
    # Parse pneumage_types.h and generate Dart classes
    # with matching field names and types
    pass
```

#### 4.3 Pros & Cons
**Pros:**
- Direct control over memory layout
- Familiar C syntax for firmware developers
- Easy to maintain alignment between platforms

**Cons:**
- Custom tooling required
- Limited to simple data structures
- No built-in serialization

---

## Strategy 5: Manual Mirroring with Versioned Documentation

### Concept
Maintain parallel implementations with strict documentation and validation tests. **This is the current approach.**

### Implementation

#### 5.1 Current State
- **Flutter**: Dart classes with Hive annotations (PneumaGeRecord, SystemVitals, etc.)
- **Firmware**: C++ structs packed into BLE characteristics
- **Documentation**: DATA_MODEL_STATUS.md, REQUIREMENTS.md

#### 5.2 Enhancement: Add Version Checking
```cpp
// Arduino firmware
#define DATA_MODEL_VERSION "1.9.0"

void sendDeviceInfo() {
    StaticJsonDocument<512> doc;
    doc["firmwareVersion"] = FIRMWARE_VERSION;
    doc["dataModelVersion"] = DATA_MODEL_VERSION;
    doc["sensors"] = sensorsArray;
    
    String output;
    serializeJson(doc, output);
    deviceInfoChar.writeValue(output.c_str());
}
```

```dart
// Flutter app
class DeviceInfo {
  final String firmwareVersion;
  final String dataModelVersion;  // NEW
  final List<SensorPayload> sensors;
  
  bool isCompatible() {
    return dataModelVersion == '1.9.0';
  }
}
```

#### 5.3 Pros & Cons
**Pros:**
- No additional dependencies or build complexity
- Full control over implementation details
- Flexibility for platform-specific optimizations

**Cons:**
- Manual synchronization required
- Higher risk of drift between platforms
- Requires discipline and thorough testing

---

## Strategy 6: Hybrid Approach (Recommended)

### Concept
Combine multiple strategies to balance efficiency, maintainability, and simplicity.

### Implementation

#### 6.1 Tiered Strategy
1. **Core BLE Protocol**: Use packed binary structs (current approach) for real-time data
   - Gas concentrations, chamber stats → Binary packed for efficiency
   - Keep current GATT characteristic layout

2. **Device Info / Metadata**: Use JSON for complex, infrequent data
   - Device info (already JSON)
   - Sensor specifications
   - Configuration data

3. **Validation Layer**: JSON Schema for documentation and testing
   - Define expected data structures in schema
   - Use schema to generate validation tests
   - Automated tests verify firmware output matches schema

4. **Version Negotiation**: Semantic versioning in BLE advertising
   - Embed schema version in device name or manufacturer data
   - App checks compatibility before connecting

#### 6.2 Example Architecture
```
┌─────────────────────────────────────────────────────┐
│          JSON Schema (Single Source of Truth)       │
│                 pneumage-schema.json                │
└─────────────────┬───────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
┌───────────────┐   ┌──────────────────┐
│   C++ Structs │   │   Dart Classes   │
│   (Firmware)  │   │   (Flutter App)  │
└───────┬───────┘   └─────────┬────────┘
        │                     │
        │   ┌─────────────────┘
        │   │
        ▼   ▼
    ┌───────────┐
    │ BLE GATT  │
    │ Protocol  │
    └───────────┘
```

#### 6.3 Benefits
- Minimal firmware complexity (stick with C structs)
- Formal documentation via JSON Schema
- Automated validation possible
- Version checking for compatibility
- Easy to extend without breaking existing code

---

## Recommendations for PneumaGe

### Short Term (Immediate Actions)
1. **Add Version Field to Device Info**
   - Include `dataModelVersion: "1.9.0"` in firmware's Device Info JSON
   - App validates version on connection

2. **Document BLE Characteristic Mapping**
   - Create explicit mapping table: BLE Characteristic → PneumaGe Schema Field
   - Include in REQUIREMENTS.md or new BLE_PROTOCOL.md

3. **Create JSON Schema for Documentation**
   - Start with high-level schema defining core types
   - Use for documentation and onboarding
   - No code generation required initially

### Medium Term (Future Enhancements)
4. **Implement Validation Tests**
   - Unit tests that verify firmware BLE output structure
   - Integration tests that decode BLE data into Dart models

5. **Consider Protobuf for Extensions**
   - If adding complex features (e.g., calibration sync, configuration updates)
   - Use protobuf only for new features, keep existing BLE protocol

### Long Term (If Scaling)
6. **Full Protobuf Migration**
   - If supporting multiple hardware platforms
   - If payload sizes become problematic
   - If adding bidirectional complex data exchange

---

## Schema Completeness Note

All data model definitions in this document (JSON Schema, Protobuf, FlatBuffers, and C Headers) now reflect the **complete PneumaGe Master Schema v1.9.0** structure, including:

- ✅ Full provenance tracking (creator, organization, sensor specifications)
- ✅ Geographic and environmental context (GPS, ambient conditions)
- ✅ Domain-specific metadata (Agriculture, Arctic, Maritime, Volcanology)
- ✅ Multi-channel architecture with separate raw/filtered data streams
- ✅ Comprehensive calibration data and QA/QC flags
- ✅ RANSAC flux calculation results with uncertainty estimates
- ✅ System vitals and IMU sensor integration

This comprehensive structure ensures scientific reproducibility and supports advanced features like:
- Data attribution for publications
- Site-specific analysis and filtering
- Quality assurance validation
- Cross-study comparisons
- Long-term data archival

---

## Comparison Matrix

| Strategy | Complexity | Efficiency | Maintainability | Best For |
|:---------|:-----------|:-----------|:----------------|:---------|
| JSON Schema | Low | Medium | High | Documentation, validation |
| Protocol Buffers | High | Very High | High | Production systems, multiple platforms |
| FlatBuffers | High | Extreme | Medium | Ultra-constrained embedded systems |
| Shared Headers | Medium | High | Medium | Small teams, simple data |
| Manual Mirroring | Low | High | Low | Prototypes, single developer |
| Hybrid | Medium | High | High | **Recommended for PneumaGe** |

---

## Next Steps

1. **Decision Point**: Choose a strategy based on:
   - Team size and expertise
   - Project maturity (prototype vs. production)
   - Performance requirements
   - Maintenance burden tolerance

2. **Prototype**: Implement chosen strategy for a subset of data (e.g., SystemVitals only)

3. **Validate**: Test cross-platform data exchange with real hardware

4. **Document**: Update architecture docs with chosen approach

5. **Iterate**: Expand to full data model once validated

---

## References

- PneumaGe Master Schema v1.9.0: [DATA_MODEL_STATUS.md](DATA_MODEL_STATUS.md)
- BLE Protocol Specification: [pneuma-core/REQUIREMENTS.md](../pneuma-core/REQUIREMENTS.md)
- JSON Schema: https://json-schema.org/
- JSON Schema Validator: https://www.jsonschemavalidator.net/
- Protocol Buffers: https://developers.google.com/protocol-buffers
- nanopb (Protobuf for embedded systems): https://jpa.kapsi.fi/nanopb/
- FlatBuffers: https://google.github.io/flatbuffers/
- QuickType (Schema to code generator): https://quicktype.io/

---

*This document captures strategies for maintaining data model consistency between the PneumaGe microcontroller firmware and Flutter mobile application. All schemas reflect the complete PneumaGe Master Schema v1.9.0 structure.*
