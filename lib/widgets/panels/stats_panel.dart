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
import '../../providers/ransac_provider.dart';
import '../../providers/data_provider.dart';

class StatsPanel extends ConsumerWidget {
  const StatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current flux result from RANSAC
    final fluxResult = ref.watch(fluxResultProvider);
    
    // Watch the current gas concentration value
    final gasConcentrationAsync = ref.watch(gasConcentrationProvider);
    final currentValue = gasConcentrationAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0.0,
    );
    
    // Extract values from flux result (or use defaults if not available)
    final flux = fluxResult?.fluxPpmPerSecond ?? 0.0;
    final fluxError = fluxResult?.fluxError ?? 0.0;
    final rSquared = fluxResult?.rSquared ?? 0.0;
    final slope = fluxResult?.slope ?? 0.0;
    final inlierCount = fluxResult?.inlierCount ?? 0;
    final labelStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );
    final valueStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
    );
    final unitStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATISTICS',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: AppTheme.divider),
          const SizedBox(height: 12),
          _StatRow(label: 'Current Value', value: currentValue.toStringAsFixed(2), unit: 'ppm', labelStyle: labelStyle, valueStyle: valueStyle, unitStyle: unitStyle),
          const SizedBox(height: 12),
          _StatRow(label: 'Flux', value: flux.toStringAsFixed(4), unit: 'g/m\u00B2/d', labelStyle: labelStyle, valueStyle: valueStyle, unitStyle: unitStyle),
          const SizedBox(height: 12),
          _StatRow(label: 'Flux Error', value: fluxError.toStringAsFixed(4), unit: 'g/m\u00B2/d', labelStyle: labelStyle, valueStyle: valueStyle, unitStyle: unitStyle),
          const SizedBox(height: 12),
          _StatRow(label: 'R\u00B2', value: rSquared.toStringAsFixed(6), unit: '', labelStyle: labelStyle, valueStyle: valueStyle, unitStyle: unitStyle),
          const SizedBox(height: 12),
          _StatRow(label: 'Slope', value: slope.toStringAsFixed(4), unit: 'ppm/s', labelStyle: labelStyle, valueStyle: valueStyle, unitStyle: unitStyle),
          const SizedBox(height: 12),
          _StatRow(label: 'Inliers', value: inlierCount.toString(), unit: 'points', labelStyle: labelStyle, valueStyle: valueStyle, unitStyle: unitStyle),
          const Spacer(),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final TextStyle unitStyle;

  const _StatRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.labelStyle,
    required this.valueStyle,
    required this.unitStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: valueStyle),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(unit, style: unitStyle),
            ],
          ],
        ),
      ],
    );
  }
}
