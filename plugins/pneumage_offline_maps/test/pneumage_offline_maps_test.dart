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

import 'package:flutter_test/flutter_test.dart';
import 'package:pneumage_offline_maps/pneumage_offline_maps.dart';

void main() {
  test('OfflineRegionResult can be created from map', () {
    final map = {
      'id': 'test_region',
      'sizeBytes': 1024000,
      'tileCount': 150,
      'completedResourceCount': 150,
      'requiredResourceCount': 150,
    };

    final result = OfflineRegionResult.fromMap(map);

    expect(result.id, 'test_region');
    expect(result.sizeBytes, 1024000);
    expect(result.tileCount, 150);
    expect(result.completedResourceCount, 150);
    expect(result.requiredResourceCount, 150);
  });

  test('DownloadProgress can be created from map', () {
    final map = {
      'progress': 0.75,
      'loadedBytes': 750000,
      'totalBytes': 1000000,
      'completedTiles': 75,
      'totalTiles': 100,
    };

    final progress = DownloadProgress.fromMap(map);

    expect(progress.progress, 0.75);
    expect(progress.loadedBytes, 750000);
    expect(progress.totalBytes, 1000000);
    expect(progress.completedTiles, 75);
    expect(progress.totalTiles, 100);
    expect(progress.percentageString, '75%');
  });

  test('PneumageOfflineMapsException formatting', () {
    final exceptionWithCode = PneumageOfflineMapsException(
      'Test error',
      code: 'TEST_ERROR',
    );
    expect(exceptionWithCode.toString(), contains('TEST_ERROR'));
    expect(exceptionWithCode.toString(), contains('Test error'));

    final exceptionWithoutCode = PneumageOfflineMapsException('Simple error');
    expect(exceptionWithoutCode.toString(), contains('Simple error'));
  });
}
