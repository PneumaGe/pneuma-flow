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

class ExportPanel extends StatelessWidget {
  final List<ProjectExportItem> projects;
  final Set<String> selectedProjectIds;
  final ValueChanged<String> onProjectToggle;
  final String exportFormat;
  final ValueChanged<String?> onFormatChanged;
  final VoidCallback onExport;
  final VoidCallback onShare;

  const ExportPanel({
    super.key,
    required this.projects,
    required this.selectedProjectIds,
    required this.onProjectToggle,
    required this.exportFormat,
    required this.onFormatChanged,
    required this.onExport,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
      letterSpacing: 1.0,
    );
    final subtitleStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );
    final textStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 10,
      color: AppTheme.textPrimary,
    );

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EXPORT DATA', style: titleStyle),
          const SizedBox(height: 8),
          Text('Select Projects:', style: subtitleStyle),
          Expanded(
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, idx) {
                final item = projects[idx];
                final isSelected = selectedProjectIds.contains(item.id);
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  leading: item.isArchived
                      ? Icon(Icons.cloud_off, size: 16, color: AppTheme.textSecondary)
                      : Checkbox(
                          value: isSelected,
                          onChanged: item.isArchived
                              ? null
                              : (val) => onProjectToggle(item.id),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                  title: Text(item.name, style: textStyle),
                  subtitle: item.isArchived
                      ? Text('Archived (cloud only)',
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            color: AppTheme.textSecondary,
                            fontSize: 8))
                      : null,
                  enabled: !item.isArchived,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text('Format:', style: subtitleStyle),
          Row(
            children: [
              Radio<String>(
                value: 'json',
                groupValue: exportFormat,
                onChanged: onFormatChanged,
                visualDensity: VisualDensity.compact,
              ),
              Text('JSON', style: textStyle),
              const SizedBox(width: 6),
              Radio<String>(
                value: 'csv',
                groupValue: exportFormat,
                onChanged: onFormatChanged,
                visualDensity: VisualDensity.compact,
              ),
              Text('CSV', style: textStyle),
              const SizedBox(width: 6),
              Radio<String>(
                value: 'zip',
                groupValue: exportFormat,
                onChanged: onFormatChanged,
                visualDensity: VisualDensity.compact,
              ),
              Text('ZIP', style: textStyle),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: selectedProjectIds.isEmpty ? null : onExport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Export', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: selectedProjectIds.isEmpty ? null : onShare,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Share', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProjectExportItem {
  final String id;
  final String name;
  final bool isArchived;

  ProjectExportItem({required this.id, required this.name, required this.isArchived});
}
