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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ransac_service.dart';

/// Provider for the RANSAC service singleton
final ransacServiceProvider = Provider<RansacService>((ref) {
  return RansacService();
});

/// State notifier for managing real-time flux results
class FluxResultNotifier extends StateNotifier<FluxResult?> {
  FluxResultNotifier() : super(null);

  /// Update the current flux result
  void updateResult(FluxResult result) {
    state = result;
  }

  /// Clear the current result
  void clear() {
    state = null;
  }
}

/// Provider for the current flux result (real-time mode)
/// Updated by Time Series Panel when RANSAC runs on live data
final fluxResultProvider = StateNotifierProvider<FluxResultNotifier, FluxResult?>((ref) {
  return FluxResultNotifier();
});
