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

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';

/// Service for handling volume button presses to control recording
class VolumeButtonService {
  final VolumeController _volumeController = VolumeController();
  StreamSubscription<double>? _volumeSubscription;
  double? _lastVolume;
  bool _isListening = false;
  
  // Callback for when recording should be toggled
  Function()? onRecordToggle;
  
  /// Start listening to volume button presses
  Future<void> startListening() async {
    if (_isListening) return;
    
    try {
      // Store initial volume
      _lastVolume = await _volumeController.getVolume();
      
      // Hide volume UI while listening
      _volumeController.showSystemUI = false;
      
      // Listen for volume changes
      _volumeSubscription = _volumeController.listener((volume) {
        _handleVolumeChange(volume);
      });
      
      _isListening = true;
    } catch (e) {
      print('Error starting volume button listener: $e');
    }
  }
  
  /// Handle volume change events
  void _handleVolumeChange(double newVolume) {
    if (_lastVolume == null) {
      _lastVolume = newVolume;
      return;
    }
    
    // Detect button press (volume changed)
    if (newVolume != _lastVolume) {
      // Restore volume to previous level immediately
      _volumeController.setVolume(_lastVolume!);
      
      // Trigger haptic feedback
      HapticFeedback.mediumImpact();
      
      // Call the recording toggle callback
      onRecordToggle?.call();
    }
    
    _lastVolume = newVolume;
  }
  
  /// Stop listening to volume button presses
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      // Cancel subscription
      await _volumeSubscription?.cancel();
      _volumeSubscription = null;
      
      // Show volume UI again
      _volumeController.showSystemUI = true;
      
      _isListening = false;
      _lastVolume = null;
    } catch (e) {
      print('Error stopping volume button listener: $e');
    }
  }
  
  /// Clean up resources
  void dispose() {
    stopListening();
  }
  
  /// Check if currently listening
  bool get isListening => _isListening;
}
