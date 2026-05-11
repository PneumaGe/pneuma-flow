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
import '../theme/app_theme.dart';
import '../providers/ble_provider.dart';
import '../providers/data_provider.dart';
import '../providers/gps_provider.dart';
import 'pneumage_logo.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the providers for real-time updates
    final isConnected = ref.watch(isConnectedProvider);
    final batteryLevel = ref.watch(batteryLevelProvider);
    final chamberStats = ref.watch(chamberStatsProvider);
    final gpsQuality = ref.watch(gpsQualityProvider);
    final gpsEnabled = ref.watch(gpsEnabledProvider);
    
    final style = Theme.of(context).textTheme.bodySmall!;
    final labelStyle = Theme.of(context).textTheme.labelSmall!;
    
    // Get values from providers with default fallbacks
    final battery = (batteryLevel.asData?.value ?? 0.0) / 100.0; // Convert to 0.0-1.0
    final temp = chamberStats.asData?.value.temperature ?? 0.0;
    final pressure = chamberStats.asData?.value.pressure ?? 0.0;
    final airTemp = chamberStats.asData?.value.airTemperature ?? 0.0;
    final airPressure = chamberStats.asData?.value.airPressure ?? 0.0;
    final quality = gpsQuality.asData?.value ?? 0;
    final isGpsEnabled = gpsEnabled.asData?.value ?? false;

    // Placeholder values (not yet implemented)
    const hasUnsyncedChanges = false;
    const isSyncing = false;

    return Container(
      height: 36,
      color: AppTheme.statusBarBg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // PneumaGe Logo
          const PneumageLogo(size: PneumageLogoSize.small),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: AppTheme.divider),
          const SizedBox(width: 16),

          // Battery
          _BatteryIndicator(level: battery, style: labelStyle),
          const SizedBox(width: 16),

          // GPS
          _GpsIndicator(quality: quality, isEnabled: isGpsEnabled, style: labelStyle),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: AppTheme.divider),
          const SizedBox(width: 16),

          // Chamber Temp
          _ReadoutLabel(
            symbol: 'T',
            subscript: 'Chamber',
            value: '${temp.toStringAsFixed(1)} °C',
            style: style,
            labelStyle: labelStyle,
          ),
          const SizedBox(width: 16),

          // Chamber Pressure
          _ReadoutLabel(
            symbol: 'P',
            subscript: 'Chamber',
            value: '${pressure.toStringAsFixed(1)} mBar',
            style: style,
            labelStyle: labelStyle,
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: AppTheme.divider),
          const SizedBox(width: 16),

          // Air Temp
          _ReadoutLabel(
            symbol: 'T',
            subscript: 'Air',
            value: '${airTemp.toStringAsFixed(1)} °C',
            style: style,
            labelStyle: labelStyle,
          ),
          const SizedBox(width: 16),

          // Air Pressure
          _ReadoutLabel(
            symbol: 'P',
            subscript: 'Air',
            value: '${airPressure.toStringAsFixed(1)} mBar',
            style: style,
            labelStyle: labelStyle,
          ),

          const Spacer(),

          // Cloud sync status (placeholder)
          _CloudIndicator(
            hasUnsyncedChanges: hasUnsyncedChanges,
            isSyncing: isSyncing,
          ),
          const SizedBox(width: 12),

          // Bluetooth status
          Icon(
            Icons.bluetooth,
            size: 18,
            color: isConnected ? AppTheme.accent : AppTheme.danger,
          ),
        ],
      ),
    );
  }
}

class _ReadoutLabel extends StatelessWidget {
  final String symbol;
  final String subscript;
  final String value;
  final TextStyle style;
  final TextStyle labelStyle;

  const _ReadoutLabel({
    required this.symbol,
    required this.subscript,
    required this.value,
    required this.style,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: symbol,
                style: style.copyWith(color: AppTheme.textSecondary),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Transform.translate(
                  offset: const Offset(0, 2),
                  child: Text(
                    subscript,
                    style: labelStyle.copyWith(
                      fontSize: 7,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(value, style: style),
      ],
    );
  }
}

class _BatteryIndicator extends StatelessWidget {
  final double level;
  final TextStyle style;

  const _BatteryIndicator({required this.level, required this.style});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (level > 0.87) {
      icon = Icons.battery_full;
    } else if (level > 0.62) {
      icon = Icons.battery_5_bar;
    } else if (level > 0.37) {
      icon = Icons.battery_3_bar;
    } else if (level > 0.12) {
      icon = Icons.battery_1_bar;
    } else {
      icon = Icons.battery_0_bar;
    }

    Color color = level > 0.2 ? AppTheme.textSecondary : AppTheme.danger;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 2),
        Text('${(level * 100).toInt()}%', style: style.copyWith(color: color)),
      ],
    );
  }
}

class _GpsIndicator extends StatelessWidget {
  final int quality;
  final bool isEnabled;
  final TextStyle style;

  const _GpsIndicator({
    required this.quality,
    required this.isEnabled,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Gray when GPS is disabled, color-coded when enabled
    final Color color;
    if (!isEnabled) {
      color = AppTheme.textSecondary; // Gray
    } else if (quality >= 3) {
      color = AppTheme.accent; // Green (excellent)
    } else if (quality >= 2) {
      color = Colors.amber; // Amber (good)
    } else if (quality >= 1) {
      color = Colors.orange; // Orange (fair)
    } else {
      color = AppTheme.danger; // Red (poor)
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.gps_fixed, size: 16, color: color),
        const SizedBox(width: 2),
        Text('GPS', style: style.copyWith(color: color)),
      ],
    );
  }
}

class _CloudIndicator extends StatelessWidget {
  final bool hasUnsyncedChanges;
  final bool isSyncing;

  const _CloudIndicator({
    required this.hasUnsyncedChanges,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;

    if (isSyncing) {
      icon = Icons.cloud_sync_outlined;
      color = AppTheme.accent;
    } else if (hasUnsyncedChanges) {
      icon = Icons.cloud_off_outlined;
      color = Colors.amber;
    } else {
      icon = Icons.cloud_done_outlined;
      color = AppTheme.textSecondary;
    }

    return Icon(icon, size: 18, color: color);
  }
}
