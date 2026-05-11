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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/ble_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/kalman_provider.dart';
import '../../providers/offline_map_provider.dart';
import '../../services/filter_service.dart';
import '../../services/kalman_filter_service.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
      letterSpacing: 1.2,
    );

    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Text('SETTINGS', style: headerStyle),
          ),
          const SizedBox(height: 8),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(2),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 10,
              ),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'APP'),
                Tab(text: 'DEVICE'),
                Tab(text: 'FILTERS'),                Tab(text: 'OFFLINE'),              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.divider,
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AppSettingsTab(),
                _DeviceSettingsTab(),
                _FiltersSettingsTab(),
                _OfflineSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSettingsTab extends ConsumerStatefulWidget {
  const _AppSettingsTab();

  @override
  ConsumerState<_AppSettingsTab> createState() => _AppSettingsTabState();
}

class _AppSettingsTabState extends ConsumerState<_AppSettingsTab> {
  String _units = 'Metric';
  bool _volumeButtonsEnabled = true;
  String _filenamePrefix = 'PG';
  final Map<String, bool> _channelVisibility = {
    'CO2': true,
    'CH4': true,
    'Temperature': false,
    'Pressure': false,
  };
  final List<String> _collaborators = [];
  final _emailController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(appSettingsProvider.future);
    if (mounted) {
      setState(() {
        _units = settings.units == 'metric' ? 'Metric' : 'Imperial';
        _volumeButtonsEnabled = settings.volumeButtonsEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final service = ref.read(settingsServiceProvider);
    final settings = AppSettings(
      units: _units == 'Metric' ? 'metric' : 'imperial',
      volumeButtonsEnabled: _volumeButtonsEnabled,
    );
    await service.saveAppSettings(settings);
    
    // Invalidate provider to trigger reload
    ref.invalidate(appSettingsProvider);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );
    final valueStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 11,
      color: AppTheme.textPrimary,
    );

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Units
        Text('Default Units', style: labelStyle),
        const SizedBox(height: 4),
        _SegmentedControl(
          options: const ['Metric', 'Imperial'],
          selected: _units,
          onChanged: (val) {
            setState(() => _units = val);
            _saveSettings();
          },
        ),
        const SizedBox(height: 16),

        // Volume Buttons Control
        Text('Recording Controls', style: labelStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _volumeButtonsEnabled,
                onChanged: (val) {
                  setState(() => _volumeButtonsEnabled = val ?? true);
                  _saveSettings();
                },
                activeColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.textSecondary),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 6),
            Text('Use volume buttons to toggle recording', style: valueStyle),
          ],
        ),
        const SizedBox(height: 16),

        // Channel visibility
        Text('Channel Visibility', style: labelStyle),
        const SizedBox(height: 4),
        ..._channelVisibility.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: entry.value,
                  onChanged: (val) {
                    setState(() => _channelVisibility[entry.key] = val ?? false);
                  },
                  activeColor: AppTheme.accent,
                  side: const BorderSide(color: AppTheme.textSecondary),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              Text(entry.key, style: valueStyle),
            ],
          ),
        )),
        const SizedBox(height: 16),

        // Filename prefix
        Text('Filename Prefix', style: labelStyle),
        const SizedBox(height: 4),
        SizedBox(
          height: 28,
          child: TextField(
            controller: TextEditingController(text: _filenamePrefix),
            onChanged: (val) => _filenamePrefix = val,
            style: valueStyle,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.divider),
                borderRadius: BorderRadius.circular(2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.divider),
                borderRadius: BorderRadius.circular(2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.accent),
                borderRadius: BorderRadius.circular(2),
              ),
              hintText: 'PG',
              hintStyle: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Collaborators
        Text('Collaborators', style: labelStyle),
        const SizedBox(height: 4),
        if (_collaborators.isEmpty)
          Text('No collaborators added', style: labelStyle.copyWith(fontStyle: FontStyle.italic)),
        ..._collaborators.map((email) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Expanded(child: Text(email, style: valueStyle)),
              GestureDetector(
                onTap: () => setState(() => _collaborators.remove(email)),
                child: const Icon(Icons.close, size: 12, color: AppTheme.danger),
              ),
            ],
          ),
        )),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  style: valueStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.divider),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.divider),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.accent),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    hintText: 'email@example.com',
                    hintStyle: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  if (_emailController.text.isNotEmpty) {
                    setState(() {
                      _collaborators.add(_emailController.text);
                      _emailController.clear();
                    });
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceSettingsTab extends ConsumerStatefulWidget {
  const _DeviceSettingsTab();

  @override
  ConsumerState<_DeviceSettingsTab> createState() => _DeviceSettingsTabState();
}

class _DeviceSettingsTabState extends ConsumerState<_DeviceSettingsTab> {
  @override
  Widget build(BuildContext context) {
    final deviceSettings = ref.watch(deviceSettingsProvider);
    final deviceInfo = ref.watch(deviceInfoProvider);
    
    final labelStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );

    return deviceSettings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error loading settings: $err', style: labelStyle),
      ),
      data: (settings) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Pump Speed', style: labelStyle),
          const SizedBox(height: 4),
          _SegmentedControl(
            options: const ['LOW', 'MEDIUM', 'HIGH'],
            selected: settings.pumpSpeed,
            onChanged: (val) async {
              if (deviceInfo != null) {
                final service = ref.read(settingsServiceProvider);
                final updated = settings.copyWith(pumpSpeed: val);
                await service.saveDeviceSettings(updated);
                ref.invalidate(deviceSettingsProvider);
              }
            },
          ),
        const SizedBox(height: 16),
        Container(height: 1, color: AppTheme.divider),
        const SizedBox(height: 16),
        Text(
          'Additional device settings will appear here\nbased on the connected sensor type.',
          style: labelStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accent : AppTheme.surfaceLight,
              borderRadius: BorderRadius.horizontal(
                left: opt == options.first ? const Radius.circular(2) : Radius.zero,
                right: opt == options.last ? const Radius.circular(2) : Radius.zero,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FiltersSettingsTab extends ConsumerStatefulWidget {
  const _FiltersSettingsTab();

  @override
  ConsumerState<_FiltersSettingsTab> createState() => _FiltersSettingsTabState();
}

class _FiltersSettingsTabState extends ConsumerState<_FiltersSettingsTab> {
  final List<String> _alphaBetaChannels = ['co2', 'ch4', 'chamber_temp', 'chamber_pressure'];
  final List<String> _kalmanChannels = ['co2', 'ch4'];
  
  final Map<String, String> _channelDisplayNames = {
    'co2': 'CO2',
    'ch4': 'CH4',
    'chamber_temp': 'Temperature',
    'chamber_pressure': 'Pressure',
  };

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );
    final headerStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
      letterSpacing: 0.8,
    );
    final valueStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 10,
      color: AppTheme.textPrimary,
    );

    final alphaBetaConfigs = ref.watch(filterConfigProvider);
    final kalmanConfigs = ref.watch(kalmanConfigProvider);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Alpha-Beta Filter Section
        Row(
          children: [
            Text('ALPHA-BETA FILTER', style: headerStyle),
            const SizedBox(width: 8),
            Expanded(
              child: Container(height: 1, color: AppTheme.divider),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Real-time smoothing and velocity estimation',
          style: labelStyle.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),

        // Alpha-Beta channels
        ..._alphaBetaChannels.map((channelId) {
          final config = alphaBetaConfigs[channelId];
          final displayName = _channelDisplayNames[channelId] ?? channelId;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _AlphaBetaChannelControl(
              channelId: channelId,
              displayName: displayName,
              config: config,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
          );
        }),

        const SizedBox(height: 8),
        Container(height: 1, color: AppTheme.divider),
        const SizedBox(height: 16),

        // Kalman Filter Section
        Row(
          children: [
            Text('KALMAN FILTER', style: headerStyle),
            const SizedBox(width: 8),
            Expanded(
              child: Container(height: 1, color: AppTheme.divider),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Temperature/pressure compensation (gas channels)',
          style: labelStyle.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),

        // Kalman channels
        ..._kalmanChannels.map((channelId) {
          final config = kalmanConfigs[channelId];
          final displayName = _channelDisplayNames[channelId] ?? channelId;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _KalmanChannelControl(
              channelId: channelId,
              displayName: displayName,
              config: config,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
          );
        }),

        const SizedBox(height: 8),
        Container(height: 1, color: AppTheme.divider),
        const SizedBox(height: 16),

        // Info text
        Text(
          'NOTE: Filters are disabled by default. Enable per-channel '
          'filtering above. Calibration tools will be available in a future update.',
          style: labelStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _AlphaBetaChannelControl extends ConsumerWidget {
  final String channelId;
  final String displayName;
  final FilterConfig? config;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _AlphaBetaChannelControl({
    required this.channelId,
    required this.displayName,
    required this.config,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = config?.enabled ?? false;
    final alpha = config?.alpha ?? 0.85;
    final beta = config?.beta ?? 0.005;
    final dt = config?.dt ?? 1.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isEnabled ? AppTheme.accent.withValues(alpha: 0.3) : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel name and enable checkbox
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: isEnabled,
                  onChanged: (val) {
                    ref.read(filterConfigProvider.notifier).setEnabled(
                      channelId,
                      val ?? false,
                    );
                  },
                  activeColor: AppTheme.accent,
                  side: const BorderSide(color: AppTheme.textSecondary),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              Text(displayName, style: valueStyle.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              // Calibrate button (inactive)
              Opacity(
                opacity: 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'CALIBRATE',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (isEnabled) ...[
            const SizedBox(height: 12),
            
            // Alpha parameter
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text('Alpha', style: labelStyle),
                ),
                Expanded(
                  child: Slider(
                    value: alpha,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    onChanged: (val) {
                      ref.read(filterConfigProvider.notifier).updateConfig(
                        channelId,
                        alpha: val,
                      );
                    },
                    activeColor: AppTheme.accent,
                    inactiveColor: AppTheme.divider,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    alpha.toStringAsFixed(2),
                    style: valueStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),

            // Beta parameter
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text('Beta', style: labelStyle),
                ),
                Expanded(
                  child: Slider(
                    value: beta,
                    min: 0.0,
                    max: 0.1,
                    divisions: 100,
                    onChanged: (val) {
                      ref.read(filterConfigProvider.notifier).updateConfig(
                        channelId,
                        beta: val,
                      );
                    },
                    activeColor: AppTheme.accent,
                    inactiveColor: AppTheme.divider,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    beta.toStringAsFixed(3),
                    style: valueStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),

            // dt parameter
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text('dt (s)', style: labelStyle),
                ),
                Expanded(
                  child: Slider(
                    value: dt,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    onChanged: (val) {
                      ref.read(filterConfigProvider.notifier).updateConfig(
                        channelId,
                        dt: val,
                      );
                    },
                    activeColor: AppTheme.accent,
                    inactiveColor: AppTheme.divider,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    dt.toStringAsFixed(1),
                    style: valueStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _KalmanChannelControl extends ConsumerWidget {
  final String channelId;
  final String displayName;
  final KalmanConfig? config;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _KalmanChannelControl({
    required this.channelId,
    required this.displayName,
    required this.config,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = config?.enabled ?? false;
    final r = config?.r ?? 0.5;
    final baseQ = config?.baseQ ?? 0.01;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isEnabled ? AppTheme.accent.withValues(alpha: 0.3) : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel name and enable checkbox
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: isEnabled,
                  onChanged: (val) {
                    ref.read(kalmanConfigProvider.notifier).setEnabled(
                      channelId,
                      val ?? false,
                    );
                  },
                  activeColor: AppTheme.accent,
                  side: const BorderSide(color: AppTheme.textSecondary),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              Text(displayName, style: valueStyle.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              // Configure button (inactive)
              Opacity(
                opacity: 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'CONFIGURE',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (isEnabled) ...[
            const SizedBox(height: 12),
            
            // r parameter (measurement noise)
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text('Meas. Noise', style: labelStyle),
                ),
                Expanded(
                  child: Slider(
                    value: r,
                    min: 0.1,
                    max: 2.0,
                    divisions: 38,
                    onChanged: (val) {
                      ref.read(kalmanConfigProvider.notifier).updateConfig(
                        channelId,
                        r: val,
                      );
                    },
                    activeColor: AppTheme.accent,
                    inactiveColor: AppTheme.divider,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    r.toStringAsFixed(2),
                    style: valueStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),

            // baseQ parameter (process noise)
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text('Proc. Noise', style: labelStyle),
                ),
                Expanded(
                  child: Slider(
                    value: baseQ,
                    min: 0.001,
                    max: 0.1,
                    divisions: 99,
                    onChanged: (val) {
                      ref.read(kalmanConfigProvider.notifier).updateConfig(
                        channelId,
                        baseQ: val,
                      );
                    },
                    activeColor: AppTheme.accent,
                    inactiveColor: AppTheme.divider,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    baseQ.toStringAsFixed(3),
                    style: valueStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              'Requires Alpha-Beta filter on pressure channel',
              style: labelStyle.copyWith(
                fontSize: 8,
                fontStyle: FontStyle.italic,
                color: AppTheme.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Offline Maps Settings Tab
/// 
/// Displays cached offline map regions with management options:
/// - List all downloaded regions
/// - Show size and download date for each
/// - Delete individual regions
/// - Display total storage used
/// - Clear all cached regions
class _OfflineSettingsTab extends ConsumerWidget {
  const _OfflineSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionsAsync = ref.watch(offlineRegionsProvider);
    final storageAsync = ref.watch(offlineStorageDisplayProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL STORAGE',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    storageAsync.when(
                      data: (storage) => Text(
                        '$storage / 1.0 GB',
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                      loading: () => const Text('Loading...'),
                      error: (_, __) => const Text('Error'),
                    ),
                  ],
                ),
                regionsAsync.whenOrNull(
                  data: (regions) => regions.isNotEmpty
                      ? TextButton.icon(
                          onPressed: () => _showClearAllDialog(context, ref),
                          icon: const Icon(Icons.delete_sweep, size: 16),
                          label: const Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            textStyle: TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 11,
                            ),
                          ),
                        )
                      : null,
                ) ?? const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cached Regions Header
          Text(
            'CACHED REGIONS',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Regions List
          regionsAsync.when(
            data: (regions) {
              if (regions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No cached regions',
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Download map areas from the map view',
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: regions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final region = regions[index];
                  return _RegionTile(region: region);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppTheme.danger),
              ),
              child: Text(
                'Error loading regions: $error',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  color: AppTheme.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cached Maps?'),
        content: const Text(
          'This will delete all downloaded map tiles and free up storage space. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ref.read(offlineMapServiceProvider);
              final success = await service.deleteAllRegions();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'All cached maps cleared'
                          : 'Failed to clear cached maps',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) {
                  ref.invalidate(offlineRegionsProvider);
                  ref.invalidate(offlineTotalStorageProvider);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

/// Individual offline region tile widget
class _RegionTile extends ConsumerWidget {
  final dynamic region; // OfflineRegion

  const _RegionTile({required this.region});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          // Map icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              Icons.map,
              size: 24,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 12),

          // Region info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  region.name,
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${region.sizeDisplay} • ${_formatDate(region.downloadedAt)}',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Zoom ${region.minZoom}-${region.maxZoom}',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: () => _showDeleteDialog(context, ref),
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.danger,
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cached Region?'),
        content: Text(
          'This will delete "${region.name}" (${region.sizeDisplay}) and free up storage space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ref.read(offlineMapServiceProvider);
              final success = await service.deleteRegion(region.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Region deleted'
                          : 'Failed to delete region',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) {
                  ref.invalidate(offlineRegionsProvider);
                  ref.invalidate(offlineTotalStorageProvider);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
