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

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../providers/ble_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pneumage_logo.dart';

class ScanConnectScreen extends ConsumerStatefulWidget {
  const ScanConnectScreen({super.key});

  @override
  ConsumerState<ScanConnectScreen> createState() => _ScanConnectScreenState();
}

class _ScanConnectScreenState extends ConsumerState<ScanConnectScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  int _scanTimeRemaining = 30;
  Timer? _scanTimer;
  String? _errorMessage;
  bool _isConnecting = false;
  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  Timer? _bluetoothCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkBluetoothAndStartScan();
    _listenToBluetoothState();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _bluetoothCheckTimer?.cancel();
    _adapterStateSubscription?.cancel();
    // Don't use ref in dispose - the BLE service is managed by Riverpod
    super.dispose();
  }

  /// Listen to Bluetooth adapter state changes
  void _listenToBluetoothState() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() {
          _bluetoothState = state;
        });

        // If Bluetooth just turned on and we're not scanning, start scanning
        if (state == BluetoothAdapterState.on && !_isScanning && _scanResults.isEmpty) {
          _startScan();
        }
      }
    });
  }

  /// Check Bluetooth state and start scanning when ready
  Future<void> _checkBluetoothAndStartScan() async {
    // Get current Bluetooth state
    final state = await FlutterBluePlus.adapterState.first;
    
    if (mounted) {
      setState(() {
        _bluetoothState = state;
      });
    }

    if (state == BluetoothAdapterState.on) {
      // Bluetooth is on, start scanning
      await _startScan();
    } else {
      // Bluetooth is off, start polling
      _startBluetoothPolling();
    }
  }

  /// Poll for Bluetooth to be turned on
  void _startBluetoothPolling() {
    _bluetoothCheckTimer?.cancel();
    _bluetoothCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final state = await FlutterBluePlus.adapterState.first;
      
      if (mounted) {
        setState(() {
          _bluetoothState = state;
        });
      }

      if (state == BluetoothAdapterState.on) {
        timer.cancel();
        if (mounted && !_isScanning) {
          await _startScan();
        }
      }
    });
  }

  /// Get user-friendly Bluetooth state message
  String _getBluetoothStateMessage() {
    switch (_bluetoothState) {
      case BluetoothAdapterState.off:
        return 'Bluetooth is turned off. Please enable Bluetooth to scan for devices.';
      case BluetoothAdapterState.turningOn:
        return 'Bluetooth is turning on...';
      case BluetoothAdapterState.turningOff:
        return 'Bluetooth is turning off...';
      case BluetoothAdapterState.unavailable:
        return 'Bluetooth is not available on this device.';
      case BluetoothAdapterState.unauthorized:
        return 'Bluetooth permissions not granted. Please enable Bluetooth permissions in settings.';
      default:
        return 'Checking Bluetooth status...';
    }
  }

  Future<void> _startScan() async {
    // Check if Bluetooth is on before scanning
    if (_bluetoothState != BluetoothAdapterState.on) {
      if (mounted) {
        setState(() {
          _errorMessage = _getBluetoothStateMessage();
          _isScanning = false;
        });
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanTimeRemaining = 30;
      _errorMessage = null;
      _scanResults = [];
    });

    try {
      // Start scanning
      final bleService = ref.read(bleServiceProvider);
      await bleService.startScan();

      // Listen to scan results
      bleService.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            _scanResults = results;
          });
        }
      });

      // Countdown timer
      _scanTimer?.cancel();
      _scanTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _scanTimeRemaining--;
          });

          if (_scanTimeRemaining <= 0) {
            timer.cancel();
            _stopScan();
          }
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _stopScan() async {
    _scanTimer?.cancel();
    await ref.read(bleServiceProvider).stopScan();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      // Get the BLE service from provider
      final bleService = ref.read(bleServiceProvider);
      
      // Stop scanning before connecting
      await _stopScan();

      // Show loading modal
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildLoadingDialog(device.platformName),
      );

      // Attempt connection
      await bleService.connect(device);

      // Device info is received during connection - check if it's available
      print("[SCAN] Checking for device info...");
      final deviceInfo = bleService.deviceInfo;
      
      if (deviceInfo == null) {
        // Not received yet - wait for stream with timeout
        print("[SCAN] Device info not ready, waiting for stream...");
        await bleService.deviceInfoStream.first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Device info not received within timeout'),
        );
        print("[SCAN] ✅ Device info received from stream!");
      } else {
        print("[SCAN] ✅ Device info already available!");
      }
      
      // Use the deviceInfo (it's definitely not null now)
      print("[SCAN] ✅ Device info received successfully!");
      print("[SCAN]   Device ID: ${bleService.deviceInfo!.deviceId}");
      print("[SCAN]   Device Name: ${bleService.deviceInfo!.deviceName}");
      print("[SCAN]   Firmware: ${bleService.deviceInfo!.firmwareVersion}");
      print("[SCAN]   Sensors: ${bleService.deviceInfo!.sensors.length}");
      print("[SCAN]   Total Channels: ${bleService.deviceInfo!.allChannels.length}");

      // Connection successful - navigate to home screen
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      // Connection failed
      print("[SCAN] ❌ Connection failed: $e");
      
      // Disconnect from device if connection was established
      try {
        await ref.read(bleServiceProvider).disconnect();
        print("[SCAN] Disconnected from device after error");
      } catch (disconnectError) {
        print("[SCAN] Error during disconnect: $disconnectError");
      }
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      setState(() {
        _isConnecting = false;
        _errorMessage = 'Connection failed: ${e.toString()}';
      });

      // Restart scanning
      _startScan();
    }
  }

  Widget _buildLoadingDialog(String deviceName) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connecting to $deviceName...',
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const PneumageLogo.large(),
              const SizedBox(height: 8),
              const Text(
                'DEVICE CONNECTION',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Bluetooth status warning
              if (_bluetoothState != BluetoothAdapterState.on) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    border: Border.all(color: AppTheme.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bluetooth_disabled,
                        size: 20,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bluetooth Required',
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warning,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getBluetoothStateMessage(),
                              style: const TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 11,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Scan status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (_isScanning)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                            ),
                          )
                        else
                          Icon(
                            _bluetoothState == BluetoothAdapterState.on
                                ? Icons.bluetooth_searching
                                : Icons.bluetooth_disabled,
                            size: 16,
                            color: _bluetoothState == BluetoothAdapterState.on
                                ? AppTheme.textSecondary
                                : AppTheme.warning,
                          ),
                        const SizedBox(width: 12),
                        Text(
                          _isScanning
                              ? 'Scanning... ($_scanTimeRemaining s)'
                              : (_bluetoothState == BluetoothAdapterState.on
                                  ? 'Scan Complete'
                                  : 'Waiting for Bluetooth...'),
                          style: const TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (!_isScanning && _bluetoothState == BluetoothAdapterState.on)
                      TextButton(
                        onPressed: _startScan,
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.surfaceLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text(
                          'RESCAN',
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 11,
                            color: AppTheme.accent,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    border: Border.all(color: AppTheme.danger),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppTheme.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 11,
                            color: AppTheme.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Device list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: _scanResults.isEmpty
                      ? Center(
                          child: Text(
                            _isScanning
                                ? 'Searching for devices...'
                                : 'No devices found',
                            style: const TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(0),
                          itemCount: _scanResults.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTheme.divider,
                          ),
                          itemBuilder: (context, index) {
                            final result = _scanResults[index];
                            final device = result.device;
                            final deviceName = device.platformName.isEmpty
                                ? 'Unknown Device'
                                : device.platformName;

                            return Container(
                              color: AppTheme.surface,
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: const Icon(
                                  Icons.bluetooth,
                                  color: AppTheme.accent,
                                  size: 20,
                                ),
                                title: Text(
                                  deviceName,
                                  style: const TextStyle(
                                    fontFamily: 'RobotoMono',
                                    fontSize: 12,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                trailing: TextButton(
                                  onPressed: _isConnecting
                                      ? null
                                      : () => _connectToDevice(device),
                                  style: TextButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                  child: const Text(
                                    'CONNECT',
                                    style: TextStyle(
                                      fontFamily: 'RobotoMono',
                                      fontSize: 11,
                                      color: AppTheme.background,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              
              // Skip button for reviewing data without device connection
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _skipToReviewMode,
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('SKIP - REVIEW DATA ONLY'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.divider),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Navigate to home screen without connecting to device (review mode)
  void _skipToReviewMode() {
    // Stop scanning if active
    if (_isScanning) {
      _stopScan();
    }
    
    // Navigate to home screen without connection
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
