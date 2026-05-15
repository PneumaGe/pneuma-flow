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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/panel_state.dart';
import '../models/measurement.dart';
import '../services/ble_service.dart';
import '../services/gps_position_buffer_service.dart';
import '../providers/ble_provider.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/project_provider.dart';
import '../providers/gps_provider.dart';
import '../providers/volume_button_provider.dart';
import '../widgets/status_bar.dart';
import '../widgets/left_sidebar.dart';
import '../widgets/right_sidebar.dart';
import '../widgets/panels/info_panel.dart';
import '../widgets/panels/stats_panel.dart';
import '../widgets/panels/files_panel.dart';
import '../widgets/panels/time_series_panel.dart';
import '../widgets/panels/histogram_panel.dart';
import '../widgets/panels/settings_panel.dart';
import '../widgets/panels/export_panel_real.dart';
import '../widgets/map_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isRecording = false;
  bool _pumpEnabled = false;
  LeftPanel? _activeLeftPanel;
  RightPanel? _activeRightPanel;
  
  // Recording state
  List<Sample> _currentSamples = [];
  DateTime? _recordingStartTime;
  Timer? _sampleTimer;
  
  // Visual feedback for volume button
  bool _showRecordingFlash = false;
  
  // Store service reference for cleanup in dispose (cannot use ref in dispose)
  dynamic _volumeButtonService;
  
  @override
  void initState() {
    super.initState();
    
    // Set up volume button handler if enabled in settings
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = await ref.read(appSettingsProvider.future);
      if (settings.volumeButtonsEnabled) {
        _volumeButtonService = ref.read(volumeButtonServiceProvider);
        _volumeButtonService.onRecordToggle = _handleVolumeButtonPress;
        _volumeButtonService.startListening();
      }
    });
    
    // Listen for settings changes to enable/disable volume button control
    ref.listenManual(appSettingsProvider, (previous, next) {
      next.whenData((settings) {
        _volumeButtonService ??= ref.read(volumeButtonServiceProvider);
        if (settings.volumeButtonsEnabled && !_volumeButtonService.isListening) {
          _volumeButtonService.onRecordToggle = _handleVolumeButtonPress;
          _volumeButtonService.startListening();
        } else if (!settings.volumeButtonsEnabled && _volumeButtonService.isListening) {
          _volumeButtonService.stopListening();
        }
      });
    });
  }
  
  /// Handle volume button press for recording control
  void _handleVolumeButtonPress() {
    // Show visual feedback
    setState(() {
      _showRecordingFlash = true;
    });
    
    // Hide feedback after brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showRecordingFlash = false;
        });
      }
    });
    
    // Toggle recording (will be called through onRecordToggle callback)
    _toggleRecording();
  }
  
  /// Toggle recording state (shared by UI and volume buttons)
  void _toggleRecording() async {
    // Check if device is connected
    final isConnected = ref.read(isConnectedProvider);
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No device connected. Connect to a device to record measurements.'),
            backgroundColor: AppTheme.danger,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    if (!_isRecording) {
      // Starting recording - check if a project is selected
      final currentProject = await ref.read(currentProjectProvider.future);
      if (currentProject == null) {
        if (mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('No active project. Please select or create a project first.'),
              backgroundColor: AppTheme.danger,
              duration: Duration(seconds: 3),
            ),
          );
          // Auto-open Files panel
          setState(() => _activeLeftPanel = LeftPanel.files);
        }
        return;
      }
      
      // Start recording
      await _startRecording();
    } else {
      // Stopping recording - show confirmation dialog
      final confirmed = await _showStopRecordingDialog();
      if (confirmed) {
        await _stopRecording();
      }
    }
  }

  Future<void> _handleDisconnect() async {
    final bleService = ref.read(bleServiceProvider);
    final dataService = ref.read(dataServiceProvider);
    
    // Stop any ongoing measurement
    if (_isRecording) {
      await bleService.sendCommand(BleService.cmdStopAll);
    }

    // Clear cached data
    dataService.clear();

    // Disconnect from device
    await bleService.disconnect();

    // Navigate back to scan screen
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  void dispose() {
    _sampleTimer?.cancel();
    
    // Stop volume button listener (use stored reference, cannot use ref in dispose)
    _volumeButtonService?.stopListening();
    
    super.dispose();
  }

  /// Collect a single sample from DataService (called at 1Hz)
  void _collectSample() {
    final dataService = ref.read(dataServiceProvider);
    
    // TODO: Support multiple sensors/channels from deviceInfo.allChannels
    // Currently assumes single device with standard channels
    final sample = Sample(
      timestamp: DateTime.now(),
      channelValues: {
        'CO2': dataService.gasConcentration,
        'CH4': 0.0, // TODO: Get from second channel
        'Temperature': dataService.chamberTemp,
        'Pressure': dataService.chamberPressure,
      },
    );
    
    setState(() {
      _currentSamples.add(sample);
    });
  }

  /// Start recording measurement data
  Future<void> _startRecording() async {
    final bleService = ref.read(bleServiceProvider);
    final gpsBuffer = ref.read(gpsPositionBufferProvider.notifier);
    final pumpSpeed = ref.read(pumpSpeedProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Always send pump command (even if pump already running)
      // This allows user to change pump speed in settings and have it take effect
      int pumpCommand;
      switch (pumpSpeed) {
        case 'LOW':
          pumpCommand = BleService.cmdPumpLow;
          break;
        case 'HIGH':
          pumpCommand = BleService.cmdPumpHigh;
          break;
        case 'MEDIUM':
        default:
          pumpCommand = BleService.cmdPumpMed;
          break;
      }
      
      await bleService.sendCommand(pumpCommand);
      
      // Send START_MEASUREMENT command
      await bleService.sendCommand(BleService.cmdStartMeasurement);
      
      // Start GPS buffer
      await gpsBuffer.startCollecting();
      
      // Start 1Hz sample timer
      _recordingStartTime = DateTime.now();
      _sampleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _collectSample();
      });
      
      setState(() {
        _pumpEnabled = true;
        _isRecording = true;
      });
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  /// Stop recording and save measurement file
  Future<void> _stopRecording() async {
    final bleService = ref.read(bleServiceProvider);
    final dataService = ref.read(dataServiceProvider);
    final gpsBuffer = ref.read(gpsPositionBufferProvider.notifier);
    final gpsService = ref.read(gpsServiceProvider);
    final projectService = ref.read(projectServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Cancel sample timer
      _sampleTimer?.cancel();
      _sampleTimer = null;
      
      // Send STOP_ALL command
      await bleService.sendCommand(BleService.cmdStopAll);
      
      // Stop GPS buffer and get median position
      gpsBuffer.stopCollecting();
      var gpsPosition = gpsBuffer.getMeasurement(clearAfter: true);
      
      // Fallback: try current position if buffer is empty
      gpsPosition ??= gpsService.currentPosition;
      
      // Determine GPS status for user feedback
      String gpsStatus;
      if (gpsPosition == null) {
        gpsStatus = 'GPS unavailable - location saved as 0.0';
      } else if (gpsPosition.accuracy > 100) {
        gpsStatus = 'GPS accuracy poor (${gpsPosition.accuracy.toStringAsFixed(0)}m)';
      } else if (gpsPosition.accuracy > 50) {
        gpsStatus = 'GPS accuracy fair (${gpsPosition.accuracy.toStringAsFixed(0)}m)';
      } else {
        gpsStatus = 'GPS position recorded (${gpsPosition.accuracy.toStringAsFixed(0)}m accuracy)';
      }
      
      // Get current project
      final currentProject = await ref.read(currentProjectProvider.future);
      if (currentProject == null) {
        throw Exception('No active project');
      }
      
      // Generate measurement ID using filename format
      final measurementId = projectService.getNextMeasurementFilename(currentProject);
      
      // Create PneumaGeRecord using factory
      var measurement = PneumaGeRecordFactory.createLiveMeasurement(
        projectId: currentProject.id,
        operatorId: 'default_operator', // TODO: Get from user profile
        systemId: dataService.deviceInfo?.deviceId ?? 'unknown',
        latitude: gpsPosition?.latitude ?? 0.0,
        longitude: gpsPosition?.longitude ?? 0.0,
        elevation: gpsPosition?.altitude ?? 0.0,
        deviceId: dataService.deviceInfo?.deviceId ?? 'unknown',
        channelNames: ['CO2', 'CH4', 'Temperature', 'Pressure'],
      );
      
      // Update with proper ID and timestamps
      measurement = PneumaGeRecord(
        version: measurement.version,
        recordUuid: measurementId,
        provenance: measurement.provenance,
        siteContext: measurement.siteContext,
        measurementCycle: MeasurementCycle(
          cycleId: measurementId,
          timestampStart: _recordingStartTime!,
          chamberVolumeM3: measurement.measurementCycle.chamberVolumeM3,
          systemVolumeM3: measurement.measurementCycle.systemVolumeM3,
          systemVitals: measurement.measurementCycle.systemVitals,
          channels: measurement.measurementCycle.channels,
        ),
      );
      
      // Add all collected samples
      for (final sample in _currentSamples) {
        measurement = PneumaGeRecordFactory.addSample(
          measurement,
          sample.timestamp,
          sample.channelValues,
          useFiltered: false, // Store as raw data during collection
        );
      }
      
      // Save measurement
      await projectService.saveMeasurement(measurement);
      
      // Refresh projects notifier to update Files Panel UI
      await ref.read(projectsNotifierProvider.notifier).refresh();
      
      // Show success feedback with GPS status
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Measurement saved: $measurementId\n$gpsStatus'),
            backgroundColor: AppTheme.accent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Reset recording state
      setState(() {
        _pumpEnabled = false;
        _isRecording = false;
        _currentSamples = [];
        _recordingStartTime = null;
      });
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to save measurement: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      
      // Still reset recording state even on error
      setState(() {
        _pumpEnabled = false;
        _isRecording = false;
        _currentSamples = [];
        _recordingStartTime = null;
      });
    }
  }

  /// Show confirmation dialog before stopping recording
  Future<bool> _showStopRecordingDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'STOP RECORDING',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const Text(
          'This will stop the device and end the recording.\n\nDo you want to continue?',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'CONTINUE',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 10,
                color: AppTheme.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  void _toggleLeftPanel(LeftPanel panel) {
    setState(() {
      if (_activeLeftPanel == panel) {
        _activeLeftPanel = null;
      } else {
        _activeLeftPanel = panel;
      }
    });
  }

  void _toggleRightPanel(RightPanel panel) {
    setState(() {
      if (_activeRightPanel == panel) {
        _activeRightPanel = null;
      } else {
        _activeRightPanel = panel;
      }
    });
  }

  int _leftPanelIndexFromEnum(LeftPanel panel) {
    switch (panel) {
      case LeftPanel.files:
        return 0;
      case LeftPanel.stats:
        return 1;
      case LeftPanel.info:
        return 2;
      case LeftPanel.settings:
        return 3;
      case LeftPanel.export:
        return 4;
    }
  }

  Widget _buildLeftPanelContent(LeftPanel panel) {
    final dataService = ref.read(dataServiceProvider);
    
    switch (panel) {
      case LeftPanel.files:
        return const FilesPanel();
      case LeftPanel.stats:
        return const StatsPanel();
      case LeftPanel.info:
        return InfoPanel(dataService: dataService);
      case LeftPanel.settings:
        return const SizedBox.shrink(); // handled separately
      case LeftPanel.export:
        return const ExportPanelReal();
    }
  }

  Widget _buildRightPanelContent(RightPanel panel) {
    switch (panel) {
      case RightPanel.timeSeries:
        return const TimeSeriesPanel();
      case RightPanel.histogram:
        return const HistogramPanel();
    }
  }

  Widget _buildCenterArea() {
    final bool isSettings = _activeLeftPanel == LeftPanel.settings;

    if (isSettings) {
      return const Expanded(child: SettingsPanel());
    }

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final List<Widget> children = [];

          // Calculate number of dividers (1px each)
          int dividerCount = 0;
          if (_activeLeftPanel != null) dividerCount++;
          if (_activeRightPanel != null) dividerCount++;
          
          // Subtract divider widths from available space for panel calculations
          final availableWidth = totalWidth - dividerCount;

          // Left overlay panel — fixed width
          if (_activeLeftPanel != null) {
            final width = availableWidth * PanelConfig.leftFraction(_activeLeftPanel!);
            children.add(
              SizedBox(
                width: width,
                child: _buildLeftPanelContent(_activeLeftPanel!),
              ),
            );
            children.add(Container(width: 1, color: AppTheme.divider));
          }

          // Map fills remaining space
          children.add(
            const Expanded(
              child: InteractiveMapWidget(),
            ),
          );

          // Right overlay panel — fixed width
          if (_activeRightPanel != null) {
            children.add(Container(width: 1, color: AppTheme.divider));
            final width = availableWidth * PanelConfig.rightFraction(_activeRightPanel!);
            children.add(
              SizedBox(
                width: width,
                child: _buildRightPanelContent(_activeRightPanel!),
              ),
            );
          }

          return Row(children: children);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header with back button and status bar
                Container(
                  color: AppTheme.statusBarBg,
                  child: Row(
                    children: [
                      // Back/Disconnect button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleDisconnect,
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 36, color: AppTheme.divider),
                      const Expanded(child: StatusBar()),
                    ],
                  ),
                ),
                Container(height: 1, color: AppTheme.divider),

                Expanded(
                  child: Row(
                    children: [
                      LeftSidebar(
                        selectedIndex: _activeLeftPanel != null
                            ? _leftPanelIndexFromEnum(_activeLeftPanel!)
                            : -1,
                        onItemSelected: (index) {
                          final panels = [
                            LeftPanel.files,
                            LeftPanel.stats,
                            LeftPanel.info,
                            LeftPanel.settings,
                            LeftPanel.export,
                          ];
                          _toggleLeftPanel(panels[index]);
                    },
                  ),
                  Container(width: 1, color: AppTheme.divider),

                  _buildCenterArea(),

                  Container(width: 1, color: AppTheme.divider),
                  RightSidebar(
                    selectedIndex: _activeRightPanel != null
                        ? _activeRightPanel!.index
                        : -1,
                    isRecording: _isRecording,
                    pumpEnabled: _pumpEnabled,
                    onRecordToggle: _toggleRecording,
                    onPumpToggle: () async {
                      // Guard: check if device is connected
                      final isConnected = ref.read(isConnectedProvider);
                      if (!isConnected) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No device connected. Connect to a device to control the pump.'),
                              backgroundColor: AppTheme.danger,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                        return;
                      }
                      
                      // Guard: if recording is active, show dialog
                      if (_isRecording) {
                        final confirmed = await _showStopRecordingDialog();
                        if (confirmed) {
                          await _stopRecording();
                        }
                        return;
                      }
                      
                      // Normal pump toggle when not recording
                      final bleService = ref.read(bleServiceProvider);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      
                      try {
                        if (!_pumpEnabled) {
                          // Turning pump ON - get speed from settings
                          final pumpSpeed = ref.read(pumpSpeedProvider);
                          
                          // Map speed to BLE command
                          int command;
                          switch (pumpSpeed) {
                            case 'LOW':
                              command = BleService.cmdPumpLow;
                              break;
                            case 'HIGH':
                              command = BleService.cmdPumpHigh;
                              break;
                            case 'MEDIUM':
                            default:
                              command = BleService.cmdPumpMed;
                              break;
                          }
                          
                          await bleService.sendCommand(command);
                          setState(() => _pumpEnabled = true);
                        } else {
                          // Turning pump OFF
                          await bleService.sendCommand(BleService.cmdStopAll);
                          setState(() => _pumpEnabled = false);
                        }
                      } catch (e) {
                        // Show error and revert state
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to control pump: $e'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        }
                      }
                    },
                    onItemSelected: (index) {
                      final panels = [
                        RightPanel.timeSeries,
                        RightPanel.histogram,
                      ];
                      _toggleRightPanel(panels[index]);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Visual feedback overlay for volume button presses
      if (_showRecordingFlash)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: _isRecording 
                ? Colors.red.withValues(alpha: 0.3) 
                : Colors.green.withValues(alpha: 0.3),
            ),
          ),
        ),
    ],
      ),
    );
  }
}
