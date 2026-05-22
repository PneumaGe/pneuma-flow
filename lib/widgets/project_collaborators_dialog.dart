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
import '../models/project.dart';
import 'collaborator_manager.dart';

/// Dialog for managing project collaborators
/// 
/// Shows current project name and allows adding/removing collaborators
class ProjectCollaboratorsDialog extends StatefulWidget {
  final Project project;
  final Future<void> Function(List<String> collaborators) onSave;

  const ProjectCollaboratorsDialog({
    super.key,
    required this.project,
    required this.onSave,
  });

  @override
  State<ProjectCollaboratorsDialog> createState() => _ProjectCollaboratorsDialogState();
}

class _ProjectCollaboratorsDialogState extends State<ProjectCollaboratorsDialog> {
  late List<String> _collaborators;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _collaborators = List.from(widget.project.collaboratorEmails);
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      await widget.onSave(_collaborators);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaborators updated successfully'),
            backgroundColor: AppTheme.accent,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update collaborators: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 18,
                  color: AppTheme.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MANAGE COLLABORATORS',
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.project.name,
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _isSaving ? null : () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: _isSaving ? AppTheme.textSecondary.withValues(alpha: 0.5) : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: AppTheme.divider,
            ),
            const SizedBox(height: 16),

            // Collaborator manager
            CollaboratorManager(
              collaborators: _collaborators,
              onChanged: (collaborators) {
                setState(() {
                  _collaborators = collaborators;
                });
              },
              enabled: !_isSaving,
            ),

            const SizedBox(height: 16),
            Container(
              height: 1,
              color: AppTheme.divider,
            ),
            const SizedBox(height: 16),

            // Help text
            Text(
              'Collaborators can view and download this project when synced to cloud. Only you can edit the project.',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 9,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
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
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SAVE',
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
    );
  }
}
