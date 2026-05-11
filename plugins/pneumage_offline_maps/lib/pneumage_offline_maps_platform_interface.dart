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

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pneumage_offline_maps_method_channel.dart';

abstract class PneumageOfflineMapsPlatform extends PlatformInterface {
  /// Constructs a PneumageOfflineMapsPlatform.
  PneumageOfflineMapsPlatform() : super(token: _token);

  static final Object _token = Object();

  static PneumageOfflineMapsPlatform _instance = MethodChannelPneumageOfflineMaps();

  /// The default instance of [PneumageOfflineMapsPlatform] to use.
  ///
  /// Defaults to [MethodChannelPneumageOfflineMaps].
  static PneumageOfflineMapsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PneumageOfflineMapsPlatform] when
  /// they register themselves.
  static set instance(PneumageOfflineMapsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
