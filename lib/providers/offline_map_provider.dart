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
import '../models/offline_region.dart';
import '../services/offline_map_service.dart';

/// Provider for the OfflineMapService instance
final offlineMapServiceProvider = Provider<OfflineMapService>((ref) {
  final service = OfflineMapService();
  service.initialize();
  return service;
});

/// Provider for the list of all cached offline regions
final offlineRegionsProvider = FutureProvider<List<OfflineRegion>>((ref) async {
  final service = ref.watch(offlineMapServiceProvider);
  return await service.getAllRegions();
});

/// Provider for total storage used by offline maps (in bytes)
final offlineTotalStorageProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(offlineMapServiceProvider);
  return await service.getTotalStorageBytes();
});

/// Provider for formatted total storage display (e.g., "45.2 MB")
final offlineStorageDisplayProvider = FutureProvider<String>((ref) async {
  final totalBytes = await ref.watch(offlineTotalStorageProvider.future);
  final mb = totalBytes / (1024 * 1024);
  return '${mb.toStringAsFixed(1)} MB';
});
