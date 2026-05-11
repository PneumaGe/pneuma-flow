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
import 'export_panel.dart';

class ExportPanelDemo extends StatefulWidget {
  const ExportPanelDemo({super.key});

  @override
  State<ExportPanelDemo> createState() => _ExportPanelDemoState();
}

class _ExportPanelDemoState extends State<ExportPanelDemo> {
  final List<ProjectExportItem> projects = [
    ProjectExportItem(id: '1', name: 'Yellowstone Survey', isArchived: false),
    ProjectExportItem(id: '2', name: 'Mammoth Lakes', isArchived: false),
    ProjectExportItem(id: '3', name: 'Hawaii 2024', isArchived: true),
  ];
  Set<String> selected = {};
  String format = 'json';

  void _toggleProject(String id) {
    setState(() {
      if (selected.contains(id)) {
        selected.remove(id);
      } else {
        selected.add(id);
      }
    });
  }

  void _changeFormat(String? f) {
    if (f != null) setState(() => format = f);
  }

  void _export() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${selected.length} project(s) as $format')),
    );
  }

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shared ${selected.length} project(s) as $format')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExportPanel(
      projects: projects,
      selectedProjectIds: selected,
      onProjectToggle: _toggleProject,
      exportFormat: format,
      onFormatChanged: _changeFormat,
      onExport: _export,
      onShare: _share,
    );
  }
}