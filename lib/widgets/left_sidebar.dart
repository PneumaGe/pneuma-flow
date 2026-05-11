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

class LeftSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  const LeftSidebar({
    super.key,
    this.selectedIndex = -1,
    this.onItemSelected,
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
            icon: Icons.folder_outlined,
            label: 'Files',
            selected: selectedIndex == 0,
            onTap: () => onItemSelected?.call(0),
          ),
          _SidebarItem(
            icon: Icons.ios_share,
            label: 'Export',
            selected: selectedIndex == 4,
            onTap: () => onItemSelected?.call(4),
          ),
          _SidebarItem(
            textIcon: 'Stats',
            label: 'Stats',
            selected: selectedIndex == 1,
            onTap: () => onItemSelected?.call(1),
          ),
          _SidebarItem(
            icon: Icons.info_outline,
            label: 'Info',
            selected: selectedIndex == 2,
            onTap: () => onItemSelected?.call(2),
          ),
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            selected: selectedIndex == 3,
            onTap: () => onItemSelected?.call(3),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData? icon;
  final String? textIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    this.icon,
    this.textIcon,
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
              ? const Border(left: BorderSide(color: AppTheme.accent, width: 2))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 20, color: color),
            if (textIcon != null)
              Text(
                textIcon!,
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
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
