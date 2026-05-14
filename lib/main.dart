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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/scan_connect_screen.dart';
import 'screens/home_screen.dart';
import 'models/project.dart';
import 'models/measurement.dart';
import 'models/app_settings.dart';
import 'models/device_settings.dart';
import 'models/offline_region.dart';
import 'services/filter_service.dart';
import 'services/kalman_filter_service.dart';
import 'config/mapbox_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Mapbox with access token (Linux support is limited)
  try {
    MapboxOptions.setAccessToken(MapboxConfig.accessToken);
  } catch (e) {
    debugPrint('Mapbox initialization failed (may not be supported on this platform): $e');
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register type adapters
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(SyncStatusAdapter());
  
  // PneumaGe Master Schema v1.9.0 adapters
  Hive.registerAdapter(PneumaGeRecordAdapter());
  Hive.registerAdapter(ProvenanceAdapter());
  Hive.registerAdapter(SensorPayloadAdapter());
  Hive.registerAdapter(SiteContextAdapter());
  Hive.registerAdapter(CoordinatesAdapter());
  Hive.registerAdapter(EnvironmentalDataAdapter());
  Hive.registerAdapter(DomainSpecificsAdapter());
  Hive.registerAdapter(MeasurementCycleAdapter());
  Hive.registerAdapter(SystemVitalsAdapter());
  Hive.registerAdapter(FluxChannelAdapter());
  Hive.registerAdapter(CalibrationDataAdapter());
  Hive.registerAdapter(ChannelDataAdapter());
  Hive.registerAdapter(CalculatedFluxAdapter());
  
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(DeviceSettingsAdapter());
  Hive.registerAdapter(FilterConfigAdapter());
  Hive.registerAdapter(KalmanConfigAdapter());
  Hive.registerAdapter(OfflineRegionAdapter());
  
  // Open boxes (Phase 1: boxes exist but not used yet)
  await Hive.openBox<Project>('projects');
  await Hive.openBox<PneumaGeRecord>('measurements');
  await Hive.openBox('settings');
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ProviderScope(child: PneumageApp()));
}

class PneumageApp extends StatelessWidget {
  const PneumageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pneumage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const ScanConnectScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
