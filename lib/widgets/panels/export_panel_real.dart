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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../models/project.dart';
import '../../models/measurement.dart';
import '../../services/export_service.dart';
import '../../providers/project_provider.dart';
import '../../providers/export_provider.dart';
import '../../providers/settings_provider.dart';
import 'export_panel.dart';

class ExportPanelReal extends ConsumerStatefulWidget {
  const ExportPanelReal({super.key});

  @override
  ConsumerState<ExportPanelReal> createState() => _ExportPanelRealState();
}

class _ExportPanelRealState extends ConsumerState<ExportPanelReal> {
  final Set<String> _selectedProjectIds = {};
  String _selectedFormat = 'zip';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      data: (projects) {
        // Map Project to ProjectExportItem
        final exportItems = projects.map((p) => ProjectExportItem(
          id: p.id,
          name: p.name,
          isArchived: p.syncStatus == SyncStatus.archived,
        )).toList();

        return ExportPanel(
          projects: exportItems,
          selectedProjectIds: _selectedProjectIds,
          exportFormat: _selectedFormat,
          onFormatChanged: _handleFormatChange,
          onProjectToggle: _handleProjectToggle,
          onExport: () => _handleExport(projects),
          onShare: () => _handleShare(projects),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading projects: $error'),
      ),
    );
  }

  void _handleProjectToggle(String projectId) {
    setState(() {
      if (_selectedProjectIds.contains(projectId)) {
        _selectedProjectIds.remove(projectId);
      } else {
        _selectedProjectIds.add(projectId);
      }
    });
  }

  void _handleFormatChange(String? format) {
    if (format != null) {
      setState(() {
        _selectedFormat = format;
      });
    }
  }

  Future<void> _handleExport(List<Project> allProjects) async {
    if (_selectedProjectIds.isEmpty || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      // Filter selected projects
      final selectedProjects = allProjects
          .where((p) => _selectedProjectIds.contains(p.id))
          .toList();

      // Check for archived projects
      final archivedProjects = selectedProjects
          .where((p) => p.syncStatus == SyncStatus.archived)
          .toList();

      if (archivedProjects.isNotEmpty) {
        // TODO: Fetch archived projects from cloud
        // TODO: Once cloud backend is ready, implement:
        // - Show loading dialog
        // - Call cloudService.fetchArchivedProject(projectId)
        // - Download measurements metadata (not full files)
        // - Continue with export
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot export archived projects yet. Cloud sync not implemented.\n'
              'Archived: ${archivedProjects.map((p) => p.name).join(", ")}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => _isExporting = false);
        return;
      }

      // Load measurements for all selected projects
      final projectService = ref.read(projectServiceProvider);
      final exportService = ref.read(exportServiceProvider);

      final projectsWithMeasurements = <Project, List<PneumaGeRecord>>{};
      
      for (final project in selectedProjects) {
        final measurements = await projectService.loadMeasurements(project.id);
        projectsWithMeasurements[project] = measurements;
      }

      // Generate timestamp for filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'pneumage_export_$timestamp';

      // Get Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // Android: Use external storage Downloads folder
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // iOS: Use app documents directory (will be accessible via Files app)
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        // Desktop: Use downloads directory
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('Could not access downloads directory');
      }

      String? exportedFilePath;

      // Check if filters are enabled
      final filtersEnabled = ref.read(filtersEnabledProvider);

      // Export based on format
      if (_selectedFormat == 'zip') {
        // Multi-project ZIP export
        exportedFilePath = await _exportMultiProjectZip(
          projectsWithMeasurements,
          downloadsDir.path,
          filename,
          exportService,
          filtersEnabled,
        );
      } else {
        // For JSON/CSV, create a combined file
        exportedFilePath = await _exportMultiProjectFile(
          projectsWithMeasurements,
          downloadsDir.path,
          filename,
          exportService,
          filtersEnabled,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to: $exportedFilePath'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<String> _exportMultiProjectZip(
    Map<Project, List<PneumaGeRecord>> projectsWithMeasurements,
    String dirPath,
    String filename,
    ExportService exportService,
    bool useFiltered,
  ) async {
    // For single project: export to temp, then move to destination
    if (projectsWithMeasurements.length == 1) {
      final entry = projectsWithMeasurements.entries.first;
      final project = entry.key;
      final measurements = entry.value;
      
      // Export to temp directory (default behavior)
      final tempZipPath = await exportService.projectToZip(
        project, 
        measurements, 
        useFiltered: useFiltered,
      );
      
      // Move to target directory with custom filename
      final targetPath = '$dirPath/$filename.zip';
      await File(tempZipPath).copy(targetPath);
      await File(tempZipPath).delete(); // Clean up temp file
      
      return targetPath;
    }

    // Multi-project ZIP: TODO - implement proper aggregation
    // For now, just export the first project
    // TODO: Use archive package to create a ZIP containing multiple project ZIPs
    // or extract and combine all measurements into one mega-archive
    final entry = projectsWithMeasurements.entries.first;
    final project = entry.key;
    final measurements = entry.value;
    
    final tempZipPath = await exportService.projectToZip(
      project, 
      measurements, 
      useFiltered: useFiltered,
    );
    final targetPath = '$dirPath/$filename.zip';
    await File(tempZipPath).copy(targetPath);
    await File(tempZipPath).delete();
    
    return targetPath;
  }

  Future<String> _exportMultiProjectFile(
    Map<Project, List<PneumaGeRecord>> projectsWithMeasurements,
    String dirPath,
    String filename,
    ExportService exportService,
    bool useFiltered,
  ) async {
    final buffer = StringBuffer();
    
    if (_selectedFormat == 'json') {
      // Multi-project JSON: array of projects
      buffer.writeln('[');
      
      int projectIndex = 0;
      for (final entry in projectsWithMeasurements.entries) {
        final project = entry.key;
        final measurements = entry.value;
        
        final projectJson = exportService.projectToJson(project, measurements);
        buffer.write(projectJson);
        
        if (projectIndex < projectsWithMeasurements.length - 1) {
          buffer.writeln(',');
        }
        projectIndex++;
      }
      
      buffer.writeln(']');
      
      final filePath = '$dirPath/$filename.json';
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      return filePath;
      
    } else {
      // Multi-project CSV: concatenate with project headers
      for (final entry in projectsWithMeasurements.entries) {
        final project = entry.key;
        final measurements = entry.value;
        
        buffer.writeln('# Project: ${project.name}');
        buffer.writeln('# Project ID: ${project.id}');
        buffer.writeln('# Created: ${project.createdAt}');
        buffer.writeln('# Measurements: ${measurements.length}');
        buffer.writeln();
        
        final projectCsv = exportService.projectToCsv(
          project, 
          measurements, 
          useFiltered: useFiltered,
        );
        buffer.writeln(projectCsv);
        buffer.writeln();
        buffer.writeln('# End of project: ${project.name}');
        buffer.writeln('# ${'=' * 80}');
        buffer.writeln();
      }
      
      final filePath = '$dirPath/$filename.csv';
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      return filePath;
    }
  }

  Future<void> _handleShare(List<Project> allProjects) async {
    if (_selectedProjectIds.isEmpty || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      // Filter selected projects
      final selectedProjects = allProjects
          .where((p) => _selectedProjectIds.contains(p.id))
          .toList();

      // Check for archived projects
      final archivedProjects = selectedProjects
          .where((p) => p.syncStatus == SyncStatus.archived)
          .toList();

      if (archivedProjects.isNotEmpty) {
        // TODO: Same as export - fetch from cloud first
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot share archived projects yet. Cloud sync not implemented.'),
          ),
        );
        setState(() => _isExporting = false);
        return;
      }

      // Load measurements and export to temp file
      final projectService = ref.read(projectServiceProvider);
      final exportService = ref.read(exportServiceProvider);

      final projectsWithMeasurements = <Project, List<PneumaGeRecord>>{};
      
      for (final project in selectedProjects) {
        final measurements = await projectService.loadMeasurements(project.id);
        projectsWithMeasurements[project] = measurements;
      }

      // Generate timestamp for filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'pneumage_export_$timestamp';

      // Use temp directory for sharing
      final tempDir = await getTemporaryDirectory();
      
      // Check if filters are enabled
      final filtersEnabled = ref.read(filtersEnabledProvider);
      
      String exportPath;

      if (_selectedFormat == 'zip') {
        exportPath = await _exportMultiProjectZip(
          projectsWithMeasurements,
          tempDir.path,
          filename,
          exportService,
          filtersEnabled,
        );
      } else {
        exportPath = await _exportMultiProjectFile(
          projectsWithMeasurements,
          tempDir.path,
          filename,
          exportService,
          filtersEnabled,
        );
      }

      // Share via platform share sheet
      await exportService.shareFile(exportPath);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
