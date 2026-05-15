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
import '../../providers/settings_provider.dart';

/// User profile panel for entering provenance metadata
/// This information is used to populate the Provenance section of measurements
class UserProfilePanel extends ConsumerStatefulWidget {
  const UserProfilePanel({super.key});

  @override
  ConsumerState<UserProfilePanel> createState() => _UserProfilePanelState();
}

class _UserProfilePanelState extends ConsumerState<UserProfilePanel> {
  final _creatorController = TextEditingController();
  final _organizationController = TextEditingController();
  final _operatorIdController = TextEditingController();
  final _creatorFocus = FocusNode();
  final _organizationFocus = FocusNode();
  final _operatorIdFocus = FocusNode();
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _creatorController.dispose();
    _organizationController.dispose();
    _operatorIdController.dispose();
    _creatorFocus.dispose();
    _organizationFocus.dispose();
    _operatorIdFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(appSettingsProvider.future);
    if (mounted) {
      setState(() {
        _creatorController.text = settings.creatorName;
        _organizationController.text = settings.organization;
        _operatorIdController.text = settings.operatorId;
      });
    }
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final settingsService = ref.read(settingsServiceProvider);
      final currentSettings = await ref.read(appSettingsProvider.future);
      final updatedSettings = currentSettings.copyWith(
        creatorName: _creatorController.text.trim(),
        organization: _organizationController.text.trim(),
        operatorId: _operatorIdController.text.trim(),
      );

      await settingsService.saveAppSettings(updatedSettings);
      
      // Invalidate provider to reload settings
      ref.invalidate(appSettingsProvider);

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
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

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.7,
        ),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'USER PROFILE',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This information is included in measurement metadata for data provenance.',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Creator Name
              Text('Creator Name', style: labelStyle),
              const SizedBox(height: 3),
              TextField(
                controller: _creatorController,
                focusNode: _creatorFocus,
                enabled: !_isSaving,
                style: valueStyle,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _onFieldChanged(),
                onSubmitted: (_) => _organizationFocus.requestFocus(),
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
                  hintText: 'e.g. Dr. Jane Smith',
                  hintStyle: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Organization
              Text('Organization', style: labelStyle),
              const SizedBox(height: 3),
              TextField(
                controller: _organizationController,
                focusNode: _organizationFocus,
                enabled: !_isSaving,
                style: valueStyle,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _onFieldChanged(),
                onSubmitted: (_) => _operatorIdFocus.requestFocus(),
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
                  hintText: 'e.g. University of Colorado',
                  hintStyle: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Operator ID
              Text('Operator ID', style: labelStyle),
              const SizedBox(height: 3),
              TextField(
                controller: _operatorIdController,
                focusNode: _operatorIdFocus,
                enabled: !_isSaving,
                style: valueStyle,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _onFieldChanged(),
                onSubmitted: (_) {
                  _operatorIdFocus.unfocus();
                  if (_hasUnsavedChanges) _saveProfile();
                },
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
                  hintText: 'e.g. email@example.com',
                  hintStyle: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSaving || !_hasUnsavedChanges) ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _hasUnsavedChanges ? 'SAVE CHANGES' : 'NO CHANGES',
                          style: const TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              
              // Information section
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Provenance Data',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This profile information is automatically included in all measurements you record. It helps establish data provenance and traceability for scientific research.',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 8,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
