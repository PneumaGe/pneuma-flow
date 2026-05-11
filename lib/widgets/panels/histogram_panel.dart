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

class HistogramPanel extends StatefulWidget {
  const HistogramPanel({super.key});

  @override
  State<HistogramPanel> createState() => _HistogramPanelState();
}

class _HistogramPanelState extends State<HistogramPanel> {
  String _selectedChannel = 'CO2';
  bool _logScale = false;
  double _filterValue = 1.0;
  final List<String> _channels = ['CO2', 'CH4', 'Temperature', 'Pressure'];

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
      letterSpacing: 1.2,
    );
    final labelStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );

    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with channel selector and log toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Text('HISTOGRAM', style: headerStyle),
                const Spacer(),
                // Log scale toggle
                GestureDetector(
                  onTap: () => setState(() => _logScale = !_logScale),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _logScale ? AppTheme.accent : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'LOG',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _logScale ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ChannelSelector(
                  channels: _channels,
                  selected: _selectedChannel,
                  onChanged: (ch) => setState(() => _selectedChannel = ch),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.divider,
          ),

          // Histogram area with vertical filter slider
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Histogram plot area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: CustomPaint(
                        painter: _GridPainter(),
                        child: Center(
                          child: Text(
                            '$_selectedChannel${_logScale ? ' (log)' : ''}\nawaiting data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Vertical filter slider
                  Column(
                    children: [
                      Text('Filter', style: labelStyle),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              activeTrackColor: AppTheme.accent,
                              inactiveTrackColor: AppTheme.divider,
                              thumbColor: AppTheme.accent,
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            ),
                            child: Slider(
                              value: _filterValue,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) => setState(() => _filterValue = val),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelSelector extends StatelessWidget {
  final List<String> channels;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChannelSelector({
    required this.channels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: AppTheme.surfaceLight,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9,
            color: AppTheme.textPrimary,
          ),
          iconSize: 14,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          items: channels
              .map((ch) => DropdownMenuItem(value: ch, child: Text(ch)))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.divider.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
