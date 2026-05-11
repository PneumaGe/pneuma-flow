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
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pneumage_offline_maps/pneumage_offline_maps.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Ready';
  double _progress = 0.0;
  String _progressDetails = '';
  bool _isDownloading = false;
  StreamSubscription<DownloadProgress>? _progressSubscription;

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _downloadSampleRegion() async {
    if (_isDownloading) return;

    setState(() {
      _status = 'Starting download...';
      _progress = 0.0;
      _isDownloading = true;
    });

    try {
      // San Francisco downtown area as example
      const regionId = 'sf_downtown_example';
      
      // Listen to progress updates
      _progressSubscription = PneumageOfflineMaps.getProgressStream(regionId).listen(
        (progress) {
          setState(() {
            _progress = progress.progress;
            _progressDetails = '${progress.percentageString}\n'
                '${progress.sizeString}\n'
                '${progress.completedTiles}/${progress.totalTiles} tiles';
          });
        },
        onError: (error) {
          setState(() {
            _status = 'Progress stream error: $error';
            _isDownloading = false;
          });
        },
        onDone: () {
          _progressSubscription = null;
        },
      );

      // Start download
      final result = await PneumageOfflineMaps.downloadRegion(
        north: 37.81,
        south: 37.77,
        east: -122.38,
        west: -122.42,
        minZoom: 12,
        maxZoom: 16,
        regionId: regionId,
      );

      setState(() {
        _status = 'Download complete!\n'
            'Region: ${result.id}\n'
            'Size: ${(result.sizeBytes / 1024 / 1024).toStringAsFixed(2)} MB\n'
            'Tiles: ${result.tileCount}\n'
            'Resources: ${result.completedResourceCount}/${result.requiredResourceCount}';
        _isDownloading = false;
      });
    } on PneumageOfflineMapsException catch (e) {
      setState(() {
        _status = 'Error: ${e.message}\nCode: ${e.code}';
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Unexpected error: $e';
        _isDownloading = false;
      });
    } finally {
      _progressSubscription?.cancel();
    }
  }

  Future<void> _deleteRegion() async {
    try {
      setState(() {
        _status = 'Deleting region...';
      });

      await PneumageOfflineMaps.deleteRegion('sf_downtown_example');

      setState(() {
        _status = 'Region deleted successfully';
        _progress = 0.0;
        _progressDetails = '';
      });
    } on PneumageOfflineMapsException catch (e) {
      setState(() {
        _status = 'Delete error: ${e.message}';
      });
    }
  }

  Future<void> _clearAll() async {
    try {
      setState(() {
        _status = 'Clearing all regions...';
      });

      await PneumageOfflineMaps.clearAllRegions();

      setState(() {
        _status = 'All regions cleared';
        _progress = 0.0;
        _progressDetails = '';
      });
    } on PneumageOfflineMapsException catch (e) {
      setState(() {
        _status = 'Clear error: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Offline Maps Plugin Example'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pneumage Offline Maps Plugin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Test downloading map tiles for San Francisco',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Progress indicator
              if (_isDownloading) ...[
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                Text(
                  _progressDetails,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              
              // Status text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadSampleRegion,
                icon: const Icon(Icons.download),
                label: const Text('Download Sample Region'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _deleteRegion,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Sample Region'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                ),
              ),
              
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _clearAll,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Regions'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                ),
              ),
              
              const Spacer(),
              
              const Text(
                'Region: SF Downtown (37.77-37.81, -122.42--122.38)\n'
                'Zoom levels: 12-16',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
