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
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pneumage_logo.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  int _selectedTab = 0;
  bool _isLoading = false;

  // Register tab controllers
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  // Login tab controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  @override
  void dispose() {
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  /// Show error message in a SnackBar
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 11),
        ),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Handle registration
  Future<void> _handleRegister() async {
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final confirmPassword = _registerConfirmPasswordController.text;

    // Validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.registerWithEmail(email, password);
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/scan_connect');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle login
  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    // Validation
    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(email, password);
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/scan_connect');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle guest sign in
  Future<void> _handleGuest() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInAsGuest();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/scan_connect');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Simple email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  const Center(
                    child: PneumageLogo(size: PneumageLogoSize.large),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  const Text(
                    'Soil Gas Flux Measurement System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 9,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Tab selector
                  _buildTabSelector(),
                  const SizedBox(height: 24),
                  
                  // Tab content
                  if (_selectedTab == 0) _buildRegisterTab(),
                  if (_selectedTab == 1) _buildLoginTab(),
                  if (_selectedTab == 2) _buildGuestTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build tab selector buttons
  Widget _buildTabSelector() {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'REGISTER',
            isSelected: _selectedTab == 0,
            onTap: _isLoading ? null : () => setState(() => _selectedTab = 0),
          ),
        ),
        Expanded(
          child: _TabButton(
            label: 'LOGIN',
            isSelected: _selectedTab == 1,
            onTap: _isLoading ? null : () => setState(() => _selectedTab = 1),
          ),
        ),
        Expanded(
          child: _TabButton(
            label: 'GUEST',
            isSelected: _selectedTab == 2,
            onTap: _isLoading ? null : () => setState(() => _selectedTab = 2),
          ),
        ),
      ],
    );
  }

  /// Build register tab content
  Widget _buildRegisterTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _registerEmailController,
          label: 'Email',
          hint: 'your.email@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _registerPasswordController,
          label: 'Password',
          hint: 'Min 6 characters',
          obscureText: true,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _registerConfirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter password',
          obscureText: true,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
          onSubmitted: (_) => _handleRegister(),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: 'CREATE ACCOUNT',
          onPressed: _isLoading ? null : _handleRegister,
          color: AppTheme.accent,
        ),
        const SizedBox(height: 16),
        _buildFooterText(
          'Already have an account? ',
          'Switch to Login',
          () => setState(() => _selectedTab = 1),
        ),
      ],
    );
  }

  /// Build login tab content
  Widget _buildLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _loginEmailController,
          label: 'Email',
          hint: 'your.email@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _loginPasswordController,
          label: 'Password',
          hint: 'Your password',
          obscureText: true,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: 'SIGN IN',
          onPressed: _isLoading ? null : _handleLogin,
          color: AppTheme.accent,
        ),
        const SizedBox(height: 16),
        _buildFooterText(
          'Need an account? ',
          'Switch to Register',
          () => setState(() => _selectedTab = 0),
        ),
      ],
    );
  }

  /// Build guest tab content
  Widget _buildGuestTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        const Icon(
          Icons.person_outline,
          size: 48,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(height: 16),
        
        // Title
        const Text(
          'CONTINUE AS GUEST',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        
        // Description
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.divider),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletPoint('Full access to BLE device connection'),
              const SizedBox(height: 6),
              _buildBulletPoint('Record measurements locally'),
              const SizedBox(height: 6),
              _buildBulletPoint('Export data to JSON/CSV/ZIP'),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.cloud_off, size: 14, color: AppTheme.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cloud sync disabled',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 9,
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Guest mode cannot upload or restore projects from Firebase.',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 8,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: 'CONTINUE AS GUEST',
          onPressed: _isLoading ? null : _handleGuest,
          color: AppTheme.divider,
        ),
        const SizedBox(height: 16),
        _buildFooterText(
          'Want cloud sync? ',
          'Register or Login',
          () => setState(() => _selectedTab = 0),
        ),
      ],
    );
  }

  /// Build a bullet point text widget
  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 10,
            color: AppTheme.accent,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 10,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build a text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool enabled = true,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 11,
            color: AppTheme.textPrimary,
          ),
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
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.accent, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build action button
  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.3),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  /// Build footer text with clickable link
  Widget _buildFooterText(String prefix, String linkText, VoidCallback onTap) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            prefix,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ),
          GestureDetector(
            onTap: _isLoading ? null : onTap,
            child: Text(
              linkText,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 9,
                color: _isLoading ? AppTheme.textSecondary : AppTheme.accent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom tab button widget
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.surface,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.accent : AppTheme.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
