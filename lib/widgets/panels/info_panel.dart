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
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../models/device.dart';

class InfoPanel extends StatelessWidget {
  final DataService dataService;

  const InfoPanel({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    final DeviceInfo? deviceInfo = dataService.deviceInfo;
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

    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              'DEVICE INFO',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: AppTheme.divider),
          Expanded(
            child: deviceInfo == null
                ? Center(
                    child: Text(
                      'No device info available',
                      style: valueStyle.copyWith(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _InfoRow(
                        label: 'Device Name',
                        value: deviceInfo.deviceName,
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Sensor Make',
                        value: deviceInfo.sensors.isNotEmpty
                            ? deviceInfo.sensors[0].make
                            : 'N/A',
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Sensor Model',
                        value: deviceInfo.sensors.isNotEmpty
                            ? deviceInfo.sensors[0].model
                            : 'N/A',
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Sensor S/N',
                        value: deviceInfo.sensors.isNotEmpty
                            ? deviceInfo.sensors[0].serialNumber
                            : 'N/A',
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: AppTheme.divider),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Processor Make',
                        value: deviceInfo.processorMake,
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Processor Model',
                        value: deviceInfo.processorModel,
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Processor S/N',
                        value: deviceInfo.processorSerial,
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: AppTheme.divider),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Firmware',
                        value: deviceInfo.firmwareVersion,
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Schema Version',
                        value: deviceInfo.dataModelVersion ?? 'Unknown',
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        Text(value, style: valueStyle),
      ],
    );
  }
}
