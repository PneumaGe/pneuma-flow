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

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/device.dart';

/// Service for handling Bluetooth Low Energy communication with the PneumaGe device.
class BleService {
  // UUIDs from the device firmware
  static final Guid pneumaServiceUuid =
      Guid("19B10000-E8F2-537E-4F6C-D104768A1214");
  static final Guid gasConcentrationCharUuid =
      Guid("19B10001-E8F2-537E-4F6C-D104768A1214");
  static final Guid chamberStatsCharUuid =
      Guid("19B10002-E8F2-537E-4F6C-D104768A1214");
  static final Guid systemCommandCharUuid =
      Guid("19B10003-E8F2-537E-4F6C-D104768A1214");
  static final Guid systemStatusCharUuid =
      Guid("19B10005-E8F2-537E-4F6C-D104768A1214");
  static final Guid batteryLifeCharUuid =
      Guid("19B10006-E8F2-537E-4F6C-D104768A1214");
  static final Guid deviceInfoCharUuid =
      Guid("19B10007-E8F2-537E-4F6C-D104768A1214");

  // Command constants
  static const int cmdStopAll = 0x00;
  static const int cmdStartMeasurement = 0x01;
  static const int cmdPumpLow = 0x10;
  static const int cmdPumpMed = 0x11;
  static const int cmdPumpHigh = 0x12;
  static const int cmdTareGas = 0x20;
  static const int cmdSetLevel = 0x30;
  static const int cmdHeartbeat = 0xAA;

  // System status constants
  static const int statusOk = 0x00;
  static const int statusTilt = 0x01;
  static const int statusBump = 0x02;
  static const int statusHeartbeatTimeout = 0x07;

  // Heartbeat timer configuration (send every 15 seconds to be safe)
  static const Duration heartbeatInterval = Duration(seconds: 15);

  // Connection state
  BluetoothDevice? _connectedDevice;
  DeviceInfo? _deviceInfo;

  // Characteristics
  BluetoothCharacteristic? _gasConcentrationChar;
  BluetoothCharacteristic? _chamberStatsChar;
  BluetoothCharacteristic? _systemCommandChar;
  BluetoothCharacteristic? _systemStatusChar;
  BluetoothCharacteristic? _batteryLifeChar;
  BluetoothCharacteristic? _deviceInfoChar;

  // Heartbeat timer
  Timer? _heartbeatTimer;
  bool _sendingHeartbeat = false;

  // Subscription management
  List<StreamSubscription> _subscriptions = [];

  // Device info streaming state
  List<int> _deviceInfoBuffer = [];

  // Data streams
  final _gasConcentrationController = StreamController<double>.broadcast();
  final _chamberStatsController = StreamController<ChamberStats>.broadcast();
  final _systemStatusController = StreamController<int>.broadcast();
  final _batteryLevelController = StreamController<double>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _deviceInfoController = StreamController<DeviceInfo>.broadcast();

  // Public stream getters
  Stream<double> get gasConcentrationStream => _gasConcentrationController.stream;
  Stream<ChamberStats> get chamberStatsStream => _chamberStatsController.stream;
  Stream<int> get systemStatusStream => _systemStatusController.stream;
  Stream<double> get batteryLevelStream => _batteryLevelController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<DeviceInfo> get deviceInfoStream => _deviceInfoController.stream;

  // State streams from FlutterBluePlus
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // Current state getters
  bool get isConnected => _connectedDevice != null;
  DeviceInfo? get deviceInfo => _deviceInfo;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Start scanning for PneumaGe devices
  Future<void> startScan() async {
    // Request Bluetooth permissions if needed
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception("Bluetooth not supported on this device");
    }

    // Start scanning for devices advertising the PneumaGe service
    await FlutterBluePlus.startScan(
      withServices: [pneumaServiceUuid],
      timeout: const Duration(seconds: 15),
    );
  }

  /// Stop scanning for devices
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connect to a PneumaGe device
  Future<void> connect(BluetoothDevice device) async {
    try {
      // Cancel any existing subscriptions
      await _cleanupSubscriptions();

      // Stop heartbeat if running
      _stopHeartbeat();

      // Connect to the device
      await device.connect(license: License.free);
      _connectedDevice = device;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(true);
      }

      // Listen for disconnection
      final disconnectSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });
      _subscriptions.add(disconnectSub);

      // Discover services and characteristics
      final services = await device.discoverServices();
      final pneumaService = services.firstWhere(
        (s) => s.uuid == pneumaServiceUuid,
        orElse: () => throw Exception("PneumaGe service not found"),
      );

      // Find all characteristics
      print('[BLE] Discovering characteristics...');
      _gasConcentrationChar = _findCharacteristic(
          pneumaService, gasConcentrationCharUuid, 'Gas Concentration');
      _chamberStatsChar = _findCharacteristic(
          pneumaService, chamberStatsCharUuid, 'Chamber Stats');
      _systemCommandChar = _findCharacteristic(
          pneumaService, systemCommandCharUuid, 'System Command');
      _systemStatusChar = _findCharacteristic(
          pneumaService, systemStatusCharUuid, 'System Status');
      _batteryLifeChar = _findCharacteristic(
          pneumaService, batteryLifeCharUuid, 'Battery Life');
      _deviceInfoChar = _findCharacteristic(
          pneumaService, deviceInfoCharUuid, 'Device Info');
      print('[BLE] All characteristics found successfully');

      // Request maximum MTU for large device info transfers
      await _requestMtu(device);

      // Subscribe to notifications (including device info streaming)
      await _setupNotifications();

      // Send initial heartbeat to test command sending
      print('[BLE] Sending initial heartbeat to test command interface...');
      try {
        await sendCommand(cmdHeartbeat);
        print('[BLE] ✓ Initial heartbeat sent successfully!');
      } catch (e) {
        print('[BLE] ✗ Failed to send initial heartbeat: $e');
      }

      // Start heartbeat timer
      _startHeartbeat();

      print("Successfully connected to ${device.platformName}");
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    _stopHeartbeat();
    await _cleanupSubscriptions();

    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _deviceInfo = null;

      // Clear all characteristics
      _gasConcentrationChar = null;
      _chamberStatsChar = null;
      _systemCommandChar = null;
      _systemStatusChar = null;
      _batteryLifeChar = null;
      _deviceInfoChar = null;
    }

    // Clear device info buffer
    _deviceInfoBuffer.clear();

    // Notify disconnection (check if controller is still open)
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(false);
    }
  }

  /// Send a command to the device
  Future<void> sendCommand(int command) async {
    print('[BLE] sendCommand called with: 0x${command.toRadixString(16).padLeft(2, '0').toUpperCase()}');
    
    if (_systemCommandChar == null) {
      print('[BLE] ERROR: _systemCommandChar is NULL!');
      throw Exception("Not connected to device");
    }

    print("[BLE] _systemCommandChar is valid, preparing to write...");
    print("[BLE] Command byte array: [${command}]");
    
    try {
      await _systemCommandChar!.write([command], withoutResponse: true);
      print("[BLE] ✓ Command write completed successfully");
    } catch (e) {
      print('[BLE] ✗ Command write failed: $e');
      rethrow;
    }
  }

  // Disposal
  void dispose() {
    _stopHeartbeat();
    _cleanupSubscriptions();
    _gasConcentrationController.close();
    _chamberStatsController.close();
    _systemStatusController.close();
    _batteryLevelController.close();
    _connectionStateController.close();
    _deviceInfoController.close();
  }

  // ============================================================================
  // Private Methods
  // ============================================================================

  BluetoothCharacteristic _findCharacteristic(
      BluetoothService service, Guid uuid, [String? name]) {
    final char = service.characteristics.firstWhere(
      (c) => c.uuid == uuid,
      orElse: () => throw Exception("Characteristic $uuid not found"),
    );
    print('[BLE] Found characteristic: ${name ?? uuid.toString()}');
    return char;
  }

  Future<void> _requestMtu(BluetoothDevice device) async {
    try {
      // Request maximum MTU (512 bytes is typical max)
      // Some platforms may negotiate lower
      final mtu = await device.requestMtu(256);
      print("MTU negotiated: $mtu bytes (requested 512)");
      print("Usable payload: ~${mtu - 3} bytes (after 3-byte ATT overhead)");
    } catch (e) {
      print("Warning: MTU request failed: $e");
      print("Using default MTU (23 bytes, ~20 usable)");
    }
  }

  /// Handle streamed device info notifications
  void _handleDeviceInfoChunk(List<int> data) {
    if (data.isEmpty) {
      // Zero-length packet signals end of stream
      if (_deviceInfoBuffer.isNotEmpty) {
        print("Received end-of-stream signal (empty packet)");
        _parseCompleteDeviceInfo();
      }
    } else {
      // Accumulate chunk
      _deviceInfoBuffer.addAll(data);
      print("Received device info chunk: ${data.length} bytes (total: ${_deviceInfoBuffer.length})");
      
      // Try to parse after each chunk to detect completion
      _tryParseDeviceInfo();
    }
  }

  void _tryParseDeviceInfo() {
    if (_deviceInfoBuffer.isEmpty) return;
    
    try {
      // Attempt to decode and parse JSON
      final jsonString = utf8.decode(_deviceInfoBuffer, allowMalformed: false);
      final json = jsonDecode(jsonString);
      
      // If we got here, JSON is valid and complete!
      print("Device info JSON is complete and valid!");
      _deviceInfo = DeviceInfo.fromJson(json);
      if (!_deviceInfoController.isClosed) {
        _deviceInfoController.add(_deviceInfo!);
      }
      print("Device info loaded: ${_deviceInfo!.deviceName}");
      
      // Clear buffer
      _deviceInfoBuffer.clear();
    } catch (e) {
      // JSON not complete yet or malformed, wait for more chunks
      // This is expected and not an error
    }
  }

  void _parseCompleteDeviceInfo() {
    try {
      print("Parsing complete device info: ${_deviceInfoBuffer.length} bytes");
      
      final jsonString = utf8.decode(_deviceInfoBuffer);
      print("JSON string length: ${jsonString.length} characters");
      print("Device info JSON: $jsonString");
      
      final json = jsonDecode(jsonString);
      _deviceInfo = DeviceInfo.fromJson(json);
      if (!_deviceInfoController.isClosed) {
        _deviceInfoController.add(_deviceInfo!);
      }

      print("Device info loaded: ${_deviceInfo!.deviceName}");
    } catch (e) {
      print("Error parsing device info: $e");
    } finally {
      // Clear buffer for next connection
      _deviceInfoBuffer.clear();
    }
  }

  Future<void> _setupNotifications() async {
    // Subscribe to device info streaming (must be first to receive initial data)
    if (_deviceInfoChar != null) {
      // Clear any previous buffer
      _deviceInfoBuffer.clear();
      
      // CRITICAL: Use onValueReceived instead of lastValueStream to capture
      // notifications that arrive during subscription setup. lastValueStream
      // drops early packets that arrive before the descriptor write completes.
      final sub = _deviceInfoChar!.onValueReceived.listen((data) {
        print("Device info notification received: ${data.length} bytes");
        _handleDeviceInfoChunk(data);
      });
      _subscriptions.add(sub);
      
      // Now enable notifications - Arduino starts streaming immediately
      await _deviceInfoChar!.setNotifyValue(true);
      print("Device info notifications enabled - waiting for stream...");
    }

    // Subscribe to gas concentration
    if (_gasConcentrationChar != null) {
      final sub = _gasConcentrationChar!.onValueReceived.listen((data) {
        if (data.isNotEmpty) {
          final co2 = _parseFloat32(data);
          if (!_gasConcentrationController.isClosed) {
            _gasConcentrationController.add(co2);
          }
        }
      });
      _subscriptions.add(sub);
      await _gasConcentrationChar!.setNotifyValue(true);
    }

    // Subscribe to chamber stats
    if (_chamberStatsChar != null) {
      final sub = _chamberStatsChar!.onValueReceived.listen(
        (data) {
          if (data.length >= 18) {
            final stats = _parseChamberStats(data);
            if (!_chamberStatsController.isClosed) {
              _chamberStatsController.add(stats);
            }
          }
        },
        onError: (error) {
          print('[BLE] Chamber stats stream error: $error');
        },
        cancelOnError: false,
      );
      _subscriptions.add(sub);
      await _chamberStatsChar!.setNotifyValue(true);
    }

    // Subscribe to system status
    if (_systemStatusChar != null) {
      final sub = _systemStatusChar!.onValueReceived.listen((data) {
        if (data.isNotEmpty) {
          if (!_systemStatusController.isClosed) {
            _systemStatusController.add(data[0]);
          }
        }
      });
      _subscriptions.add(sub);
      await _systemStatusChar!.setNotifyValue(true);
    }

    // Subscribe to battery level
    if (_batteryLifeChar != null) {
      final sub = _batteryLifeChar!.onValueReceived.listen(
        (data) {
          if (data.length >= 4) {
            final soc = _parseFloat32(data);
            if (!_batteryLevelController.isClosed) {
              _batteryLevelController.add(soc);
            }
          }
        },
        onError: (error) {
          print('[BLE] Battery stream error: $error');
        },
        cancelOnError: false,
      );
      _subscriptions.add(sub);
      await _batteryLifeChar!.setNotifyValue(true);
    }
  }

  void _startHeartbeat() {
    print('[BLE] Starting heartbeat timer (${heartbeatInterval.inSeconds}s interval)');
    _heartbeatTimer?.cancel();
    _sendingHeartbeat = false;
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) {
      if (_sendingHeartbeat) {
        print('[BLE] ⚠ Skipping heartbeat - previous send still in progress');
        return;
      }
      
      _sendingHeartbeat = true;
      print('[BLE] Sending heartbeat...');
      
      sendCommand(cmdHeartbeat).then((_) {
        print('[BLE] Heartbeat sent successfully');
        _sendingHeartbeat = false;
      }).catchError((e) {
        print("[BLE] ERROR sending heartbeat: $e");
        _sendingHeartbeat = false;
        timer.cancel();
      });
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _sendingHeartbeat = false;
  }

  Future<void> _cleanupSubscriptions() async {
    for (var sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  void _handleDisconnection() {
    print("Device disconnected");
    _stopHeartbeat();
    _cleanupSubscriptions();
    _connectedDevice = null;
    _deviceInfo = null;
    
    // Clear device info buffer
    _deviceInfoBuffer.clear();
    
    // Notify disconnection (check if controller is still open)
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(false);
    }
  }

  // ============================================================================
  // Binary Data Parsers
  // ============================================================================

  /// Parse a 4-byte little-endian float (matches Arduino's float format)
  double _parseFloat32(List<int> data) {
    if (data.length < 4) return 0.0;

    final bytes = Uint8List.fromList(data.sublist(0, 4));
    final buffer = ByteData.sublistView(bytes);
    return buffer.getFloat32(0, Endian.little);
  }

  /// Parse the ChamberStats packed struct (18 bytes)
  /// struct __attribute__((packed)) ChamberStats {
  ///   int16_t airTemperature;      // 2 bytes - offset 0
  ///   int16_t chamberTemperature;  // 2 bytes - offset 2
  ///   uint32_t airPressure;        // 4 bytes - offset 4
  ///   uint32_t chamberPressure;    // 4 bytes - offset 8
  ///   uint16_t airHumidity;        // 2 bytes - offset 12
  ///   uint16_t chamberHumidity;    // 2 bytes - offset 14
  ///   uint16_t status;             // 2 bytes - offset 16
  /// };
  ChamberStats _parseChamberStats(List<int> data) {
    final bytes = Uint8List.fromList(data);
    final buffer = ByteData.sublistView(bytes);

    // Parse all air and chamber values from 18-byte struct
    final airTempRaw = buffer.getInt16(0, Endian.little);
    final chamberTempRaw = buffer.getInt16(2, Endian.little);
    final airPressRaw = buffer.getUint32(4, Endian.little);
    final chamberPressRaw = buffer.getUint32(8, Endian.little);
    final airHumRaw = buffer.getUint16(12, Endian.little);
    final chamberHumRaw = buffer.getUint16(14, Endian.little);
    final statusRaw = buffer.getUint16(16, Endian.little);

    return ChamberStats(
      temperature: chamberTempRaw / 100.0,
      pressure: chamberPressRaw / 1000.0,
      humidity: chamberHumRaw / 100.0,
      airTemperature: airTempRaw / 100.0,
      airPressure: airPressRaw / 1000.0,
      airHumidity: airHumRaw / 100.0,
      status: statusRaw,
    );
  }
}

/// Parsed chamber environmental statistics
class ChamberStats {
  final double temperature; // °C (chamber)
  final double pressure;    // hPa (chamber)
  final double humidity;    // % (chamber)
  final double airTemperature; // °C (ambient)
  final double airPressure;    // hPa (ambient)
  final double airHumidity;    // % (ambient)
  final int status;         // Status bitmask

  ChamberStats({
    required this.temperature,
    required this.pressure,
    required this.humidity,
    required this.airTemperature,
    required this.airPressure,
    required this.airHumidity,
    required this.status,
  });

  @override
  String toString() {
    return 'ChamberStats(T_chamber: ${temperature.toStringAsFixed(2)}°C, '
           'P_chamber: ${pressure.toStringAsFixed(2)}hPa, '
           'RH_chamber: ${humidity.toStringAsFixed(1)}%, '
           'T_air: ${airTemperature.toStringAsFixed(2)}°C, '
           'P_air: ${airPressure.toStringAsFixed(2)}hPa, '
           'RH_air: ${airHumidity.toStringAsFixed(1)}%)';
  }
}
