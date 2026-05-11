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
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// A reusable widget for displaying the PneumaGe logo with consistent styling.
///
/// The logo uses a two-tone color scheme with "Pneuma" in light gray and
/// "Ge" in dark teal, rendered in Montserrat font. This widget ensures
/// consistent branding across the entire app.
///
/// **Basic Usage:**
/// ```dart
/// // Large logo with default styling
/// PneumageLogo.large()
///
/// // Small logo for status bars
/// PneumageLogo.small()
/// ```
///
/// **Custom Styling:**
/// ```dart
/// // With glow effect
/// PneumageLogo(withGlow: true)
///
/// // Custom letter spacing
/// PneumageLogo(letterSpacing: 1.0)
///
/// // Combine options
/// PneumageLogo.large(
///   withGlow: true,
///   textAlign: TextAlign.left,
/// )
/// ```
class PneumageLogo extends StatelessWidget {
  /// The size variant of the logo
  final PneumageLogoSize size;

  /// Optional custom letter spacing override
  final double? letterSpacing;

  /// Whether to apply a glow effect
  final bool withGlow;

  /// Optional text alignment
  final TextAlign? textAlign;

  const PneumageLogo({
    super.key,
    this.size = PneumageLogoSize.large,
    this.letterSpacing,
    this.withGlow = false,
    this.textAlign,
  });

  /// Convenience constructor for large logo
  const PneumageLogo.large({
    super.key,
    this.letterSpacing,
    this.withGlow = false,
    this.textAlign,
  }) : size = PneumageLogoSize.large;

  /// Convenience constructor for small logo
  const PneumageLogo.small({
    super.key,
    this.letterSpacing,
    this.withGlow = false,
    this.textAlign,
  }) : size = PneumageLogoSize.small;

  @override
  Widget build(BuildContext context) {
    // Size-specific font sizes
    final double fontSize = size == PneumageLogoSize.large ? 24.0 : 12.0;

    // Build shadows for glow effect if enabled
    final List<Shadow>? shadows = withGlow
        ? [
            Shadow(
              color: AppTheme.logoGlowColor,
              blurRadius: 8,
            ),
            Shadow(
              color: AppTheme.logoGeColor.withOpacity(0.5),
              blurRadius: 16,
            ),
          ]
        : null;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Pneuma',
            style: GoogleFonts.montserrat(
              color: AppTheme.logoPneumaColor,
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
              shadows: shadows,
            ),
          ),
          TextSpan(
            text: 'Ge',
            style: GoogleFonts.montserrat(
              color: AppTheme.logoGeColor,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
              shadows: shadows,
            ),
          ),
        ],
      ),
      textAlign: textAlign ?? TextAlign.center,
    );
  }
}

/// Logo size variants
enum PneumageLogoSize {
  large,
  small,
}

