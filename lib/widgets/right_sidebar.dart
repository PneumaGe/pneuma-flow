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
import '../theme/app_theme.dart';

class RightSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final VoidCallback? onRecordToggle;
  final VoidCallback? onPumpToggle;
  final bool isRecording;
  final bool pumpEnabled;

  const RightSidebar({
    super.key,
    this.selectedIndex = -1,
    this.onItemSelected,
    this.onRecordToggle,
    this.onPumpToggle,
    this.isRecording = false,
    this.pumpEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      color: AppTheme.sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.show_chart,
            label: 'Series',
            selected: selectedIndex == 0,
            onTap: () => onItemSelected?.call(0),
          ),
          _SidebarItem(
            icon: Icons.bar_chart,
            label: 'Hist',
            selected: selectedIndex == 1,
            onTap: () => onItemSelected?.call(1),
          ),
          const Spacer(),
          _RecordButton(
            isRecording: isRecording,
            onTap: onRecordToggle,
          ),
          const SizedBox(height: 12),
          _PumpButton(
            enabled: pumpEnabled,
            onTap: onPumpToggle,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accent : AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: selected
              ? const Border(right: BorderSide(color: AppTheme.accent, width: 2))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 8,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback? onTap;

  const _RecordButton({required this.isRecording, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isRecording ? AppTheme.danger : AppTheme.textSecondary,
            width: 2,
          ),
        ),
        child: Center(
          child: isRecording
              ? const Icon(Icons.stop, size: 20, color: AppTheme.danger)
              : Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.danger,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PumpButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _PumpButton({required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: enabled ? AppTheme.accent : AppTheme.danger,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'PUMP',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
