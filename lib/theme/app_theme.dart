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

class AppTheme {
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF888888);
  static const Color accent = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726); // Amber for warnings
  static const Color statusBarBg = Color(0xFF111111);
  static const Color sidebarBg = Color(0xFF0F0F0F);
  static const Color divider = Color(0xFF333333);

  // Logo styling
  static const Color logoPneumaColor = Color(0xFF9CA3AF); // Light gray for "Pneuma"
  static const Color logoGeColor = Color(0xFF1F4E5F); // Dark teal for "Ge"
  static const Color logoGlowColor = Color(0xFF1F4E5F); // Glow color matches "Ge"

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        error: danger,
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 11,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 12,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 9,
          color: textSecondary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 20,
      ),
    );
  }
}
