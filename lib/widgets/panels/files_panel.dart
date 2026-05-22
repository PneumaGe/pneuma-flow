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
import '../../models/project.dart';
import '../../providers/project_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/domain_config.dart';
import '../collaborator_manager.dart';
import '../project_collaborators_dialog.dart';

// Import selectedMeasurementIdProvider for measurement selection
// (imported from project_provider.dart above)

class FilesPanel extends ConsumerStatefulWidget {
  const FilesPanel({super.key});

  @override
  ConsumerState<FilesPanel> createState() => _FilesPanelState();
}

class _FilesPanelState extends ConsumerState<FilesPanel> {
  int _selectedProjectIndex = -1;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsNotifierProvider);
    final currentProjectIdAsync = ref.watch(currentProjectIdProvider);
    
    final headerStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
      letterSpacing: 1.2,
    );
    final subtitleStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );

    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Text('PROJECTS', style: headerStyle),
                const Spacer(),
                GestureDetector(
                  onTap: _createProject,
                  child: const Icon(Icons.add, size: 16, color: AppTheme.accent),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.divider,
          ),

          // Project list
          Expanded(
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error: $err', style: subtitleStyle),
              ),
              data: (projects) {
                return currentProjectIdAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text('Error: $err', style: subtitleStyle),
                  ),
                  data: (currentProjectId) => ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final selected = index == _selectedProjectIndex;
                      final isActive = project.id == currentProjectId;
                      
                      return _ProjectTile(
                        project: project,
                        selected: selected,
                        isActive: isActive,
                        onTap: () {
                          // Set as current project when project name is tapped
                          ref.read(projectsNotifierProvider.notifier)
                              .setCurrentProject(project.id);
                        },
                        onExpand: () {
                          // Toggle expansion when arrow is tapped
                          // Also clear selected measurement when collapsing
                          setState(() {
                            _selectedProjectIndex = selected ? -1 : index;
                          });
                          if (selected) {
                            // Clear selected measurement when collapsing project
                            ref.read(selectedMeasurementIdProvider.notifier).state = null;
                          }
                        },
                        onSync: () => _syncProject(project),
                        onArchive: () => _archiveProject(project),
                        onRestore: () => _restoreProject(project),
                        onManageCollaborators: () => _manageCollaborators(project),
                        files: selected && project.syncStatus != SyncStatus.archived
                            ? _buildFileList(project, subtitleStyle)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(Project project, TextStyle subtitleStyle) {
    // Get the currently selected measurement ID to highlight it
    final selectedMeasurementId = ref.watch(selectedMeasurementIdProvider);
    
    // Placeholder files based on measurement IDs
    final files = project.measurementIds
        .asMap()
        .entries
        .map((e) =>
            '${project.filenamePrefix}_${(e.key + 1).toString().padLeft(3, '0')}.csv')
        .toList();

    if (files.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Text('No measurements', style: subtitleStyle),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < files.length; i++)
          GestureDetector(
            onTap: () {
              // Set the selected measurement ID in the provider
              final measurementId = project.measurementIds[i];
              ref.read(selectedMeasurementIdProvider.notifier).state = measurementId;
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              color: project.measurementIds[i] == selectedMeasurementId
                  ? AppTheme.surfaceLight
                  : Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 12,
                    color: project.measurementIds[i] == selectedMeasurementId
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    files[i],
                    style: subtitleStyle.copyWith(
                      color: project.measurementIds[i] == selectedMeasurementId
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _createProject() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateProjectBottomSheet(ref: ref),
    );
  }

  void _syncProject(Project project) async {
    // Check if user profile is complete before syncing
    final appSettingsAsync = await ref.read(appSettingsProvider.future);
    
    final missingFields = <String>[];
    if (appSettingsAsync.creatorName.trim().isEmpty) {
      missingFields.add('Creator Name');
    }
    if (appSettingsAsync.operatorId.trim().isEmpty) {
      missingFields.add('Operator ID');
    }
    
    if (missingFields.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_outlined,
                color: AppTheme.danger,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Profile Incomplete',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please complete your user profile before syncing projects to the cloud.',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Missing fields:',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...missingFields.map((field) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: AppTheme.danger,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      field,
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 10,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Text(
                'Go to Settings > User Profile to complete your profile.',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    
    // Placeholder — will call SyncService.syncProject()
    ref.read(projectsNotifierProvider.notifier).updateProject(
      project.copyWith(
        syncStatus: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
      ),
    );
  }

  void _archiveProject(Project project) {
    // Placeholder — will call SyncService.canArchive() then remove local data
    ref.read(projectsNotifierProvider.notifier).updateProject(
      project.copyWith(
        syncStatus: SyncStatus.archived,
      ),
    );
    setState(() {
      _selectedProjectIndex = -1;
    });
    // Clear selected measurement when archiving project
    ref.read(selectedMeasurementIdProvider.notifier).state = null;
  }

  void _restoreProject(Project project) {
    // Placeholder — will call SyncService.restoreProject()
    ref.read(projectsNotifierProvider.notifier).updateProject(
      project.copyWith(
        syncStatus: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
      ),
    );
  }

  void _manageCollaborators(Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectCollaboratorsDialog(
        project: project,
        onSave: (collaborators) async {
          // Update project with new collaborators
          final updatedProject = project.copyWith(
            collaboratorEmails: collaborators,
            syncStatus: SyncStatus.local, // Mark as local to trigger sync
          );
          await ref.read(projectsNotifierProvider.notifier).updateProject(updatedProject);
        },
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  final bool selected;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onExpand;
  final VoidCallback onSync;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onManageCollaborators;
  final Widget? files;

  const _ProjectTile({
    required this.project,
    required this.selected,
    required this.isActive,
    required this.onTap,
    required this.onExpand,
    required this.onSync,
    required this.onArchive,
    required this.onRestore,
    required this.onManageCollaborators,
    this.files,
  });

  @override
  Widget build(BuildContext context) {
    final itemStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 11,
      color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
    );
    final subtitleStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );

    final isArchived = project.syncStatus == SyncStatus.archived;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: selected ? AppTheme.surfaceLight : Colors.transparent,
          child: Row(
            children: [
              // Folder icon
              Icon(
                isArchived
                    ? Icons.cloud_outlined
                    : selected
                        ? Icons.folder_open
                        : Icons.folder_outlined,
                size: 16,
                color: isArchived
                    ? AppTheme.textSecondary
                    : selected
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),

              // Project name and status (tappable to set active)
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Active dot indicator
                          if (isActive) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              project.name,
                              style: itemStyle.copyWith(
                                color: isArchived
                                    ? AppTheme.textSecondary
                                    : itemStyle.color,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.accent.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 7,
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          _SyncBadge(status: project.syncStatus),
                        ],
                      ),
                      if (selected && project.lastSyncedAt != null)
                        Text(
                          'Synced ${_formatDate(project.lastSyncedAt!)}',
                          style: subtitleStyle,
                        ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Row(
                children: [
                  // Collaborators button (always visible when not loading)
                  if (project.syncStatus != SyncStatus.syncing &&
                      project.syncStatus != SyncStatus.restoring)
                    _ActionButton(
                      icon: Icons.people_outline,
                      tooltip: 'Manage collaborators',
                      onTap: onManageCollaborators,
                    ),
                  // Sync/Archive/Restore button
                  _buildActions(),
                ],
              ),

              // Expand/collapse indicator (only for non-archived)
              if (!isArchived)
                GestureDetector(
                  onTap: onExpand,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      selected ? Icons.expand_less : Icons.expand_more,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (files != null) files!,
      ],
    );
  }

  Widget _buildActions() {
    switch (project.syncStatus) {
      case SyncStatus.local:
        return _ActionButton(
          icon: Icons.cloud_upload_outlined,
          tooltip: 'Sync to cloud',
          onTap: onSync,
        );
      case SyncStatus.synced:
        return _ActionButton(
          icon: Icons.archive_outlined,
          tooltip: 'Archive',
          onTap: onArchive,
        );
      case SyncStatus.archived:
        return _ActionButton(
          icon: Icons.cloud_download_outlined,
          tooltip: 'Restore',
          onTap: onRestore,
        );
      case SyncStatus.syncing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accent,
            ),
          ),
        );
      case SyncStatus.restoring:
        return const SizedBox(
          width: 24,
          height: 24,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accent,
            ),
          ),
        );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(icon, size: 16, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final SyncStatus status;

  const _SyncBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (status) {
      SyncStatus.local => ('LOCAL', AppTheme.textSecondary),
      SyncStatus.syncing => ('SYNCING', AppTheme.accent),
      SyncStatus.synced => ('SYNCED', AppTheme.accent),
      SyncStatus.archived => ('CLOUD', const Color(0xFF5C9CE6)),
      SyncStatus.restoring => ('RESTORING', AppTheme.accent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 7,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CreateProjectBottomSheet extends StatefulWidget {
  final WidgetRef ref;

  const _CreateProjectBottomSheet({required this.ref});

  @override
  State<_CreateProjectBottomSheet> createState() => _CreateProjectBottomSheetState();
}

class _CreateProjectBottomSheetState extends State<_CreateProjectBottomSheet> {
  final _nameController = TextEditingController();
  final _prefixController = TextEditingController(text: 'PG');
  String _selectedDomain = DomainConfig.none;
  final Map<String, TextEditingController> _domainFieldControllers = {};
  List<String> _collaborators = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _prefixController.dispose();
    for (var controller in _domainFieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Get or create a text controller for a domain field
  TextEditingController _getFieldController(String key) {
    if (!_domainFieldControllers.containsKey(key)) {
      _domainFieldControllers[key] = TextEditingController();
    }
    return _domainFieldControllers[key]!;
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

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final domainFields = DomainConfig.getFieldsForDomain(_selectedDomain);
    
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.7,
        ),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text(
              'CREATE NEW PROJECT',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            
            // Project Name
            Text('Project Name', style: labelStyle),
            const SizedBox(height: 3),
            TextField(
              controller: _nameController,
              enabled: !_isCreating,
              autofocus: true,
              style: valueStyle,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                hintText: 'e.g. Yellowstone Survey',
                hintStyle: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Filename Prefix
            Text('Filename Prefix', style: labelStyle),
            const SizedBox(height: 3),
            TextField(
              controller: _prefixController,
              enabled: !_isCreating,
              style: valueStyle,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                hintText: 'PG',
                hintStyle: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Domain Type Dropdown
            Text('Domain Type', style: labelStyle),
            const SizedBox(height: 3),
            DropdownButtonFormField<String>(
              value: _selectedDomain,
              onChanged: _isCreating ? null : (value) {
                setState(() {
                  _selectedDomain = value ?? DomainConfig.none;
                });
              },
              style: valueStyle,
              dropdownColor: AppTheme.surface,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              items: DomainConfig.allDomains.map((domain) {
                return DropdownMenuItem<String>(
                  value: domain,
                  child: Text(
                    DomainConfig.domainDisplayNames[domain] ?? domain,
                    style: valueStyle,
                  ),
                );
              }).toList(),
            ),
            
            // Collaborators
            const SizedBox(height: 8),
            CollaboratorManager(
              collaborators: _collaborators,
              onChanged: (collaborators) {
                setState(() {
                  _collaborators = collaborators;
                });
              },
              enabled: !_isCreating,
            ),
            
            // Domain-specific fields
            if (domainFields.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'DOMAIN METADATA',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ...domainFields.map((field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(field.label, style: labelStyle),
                      if (field.required)
                        Text(
                          ' *',
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 9,
                            color: AppTheme.danger,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  TextField(
                    controller: _getFieldController(field.key),
                    enabled: !_isCreating,
                    style: valueStyle,
                    keyboardType: field.isNumeric ? TextInputType.number : TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      hintText: field.hint,
                      hintStyle: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              )).toList(),
            ],
            
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isCreating ? null : _handleCreateProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'CREATE',
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _handleCreateProject() async {
    final name = _nameController.text.trim();
    final prefix = _prefixController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project name is required'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    // Validate required domain fields
    final domainFields = DomainConfig.getFieldsForDomain(_selectedDomain);
    for (final field in domainFields) {
      if (field.required) {
        final value = _domainFieldControllers[field.key]?.text.trim() ?? '';
        if (value.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${field.label} is required'),
              backgroundColor: AppTheme.danger,
            ),
          );
          return;
        }
      }
    }

    // Collect domain metadata
    final domainMetadata = <String, dynamic>{};
    for (final field in domainFields) {
      final value = _domainFieldControllers[field.key]?.text.trim() ?? '';
      if (value.isNotEmpty) {
        // Parse numeric values
        if (field.isNumeric) {
          final numValue = double.tryParse(value);
          if (numValue != null) {
            domainMetadata[field.key] = numValue;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${field.label} must be a number'),
                backgroundColor: AppTheme.danger,
              ),
            );
            return;
          }
        } else {
          domainMetadata[field.key] = value;
        }
      }
    }

    setState(() => _isCreating = true);

    try {
      await widget.ref.read(projectsNotifierProvider.notifier).createProject(
        name: name,
        ownerId: 'user1', // TODO: Replace with actual user ID from auth
        filenamePrefix: prefix.isEmpty ? 'PG' : prefix,
        collaboratorEmails: _collaborators,
        domain: _selectedDomain,
        domainMetadata: domainMetadata,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
        setState(() => _isCreating = false);
      }
    }
  }
}
