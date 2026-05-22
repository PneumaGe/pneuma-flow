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

/// Reusable widget for managing project collaborators
/// 
/// Displays a list of collaborator emails with ability to add and remove
class CollaboratorManager extends StatefulWidget {
  final List<String> collaborators;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  const CollaboratorManager({
    super.key,
    required this.collaborators,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<CollaboratorManager> createState() => _CollaboratorManagerState();
}

class _CollaboratorManagerState extends State<CollaboratorManager> {
  final _emailController = TextEditingController();
  late List<String> _localCollaborators;

  @override
  void initState() {
    super.initState();
    _localCollaborators = List.from(widget.collaborators);
  }

  @override
  void didUpdateWidget(CollaboratorManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collaborators != widget.collaborators) {
      _localCollaborators = List.from(widget.collaborators);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _addCollaborator() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    // Basic email validation
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    // Check for duplicates
    if (_localCollaborators.contains(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This collaborator is already added'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() {
      _localCollaborators.add(email);
      _emailController.clear();
    });
    widget.onChanged(_localCollaborators);
  }

  void _removeCollaborator(String email) {
    setState(() {
      _localCollaborators.remove(email);
    });
    widget.onChanged(_localCollaborators);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Collaborators', style: labelStyle),
        const SizedBox(height: 4),
        
        // List of existing collaborators
        if (_localCollaborators.isEmpty)
          Text(
            'No collaborators added',
            style: labelStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        ..._localCollaborators.map((email) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  email,
                  style: valueStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.enabled)
                GestureDetector(
                  onTap: () => _removeCollaborator(email),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppTheme.danger,
                  ),
                ),
            ],
          ),
        )),
        
        if (widget.enabled) ...[
          const SizedBox(height: 6),
          // Add collaborator input
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    style: valueStyle,
                    onSubmitted: (_) => _addCollaborator(),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppTheme.accent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      hintText: 'email@example.com',
                      hintStyle: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _addCollaborator,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
