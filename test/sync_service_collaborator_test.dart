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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pneumage_app/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService collaborator project listing', () {
    late SyncService syncService;
    const testUserId = 'test-collaborator@example.com';
    const ownerId = 'owner@example.com';
    const projectId = 'project-123';

    setUpAll(() async {
      // Initialize Firebase for testing (mock or emulator recommended)
      await Firebase.initializeApp();
      syncService = SyncService();
    });

    test('getCloudProjects returns projects where user is collaborator', () async {
      // Insert a project with testUserId as collaborator
      final projectData = {
        'id': projectId,
        'ownerId': ownerId,
        'collaboratorEmails': [testUserId],
        'name': 'Test Project',
        'syncStatus': 'synced',
      };
      await FirebaseFirestore.instance.collection('projects').doc(projectId).set(projectData);

      final projects = await syncService.getCloudProjects(testUserId);
      expect(projects.any((p) => p.id == projectId), isTrue);
    });
  });
}
