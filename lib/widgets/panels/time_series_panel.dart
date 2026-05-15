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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/data_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/ransac_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/measurement.dart';
import '../../services/ransac_service.dart';

class TimeSeriesPanel extends ConsumerStatefulWidget {
  const TimeSeriesPanel({super.key});

  @override
  ConsumerState<TimeSeriesPanel> createState() => _TimeSeriesPanelState();
}

/// Data point for the time series plot
class DataPoint {
  final DateTime timestamp;
  final double value;
  
  DataPoint(this.timestamp, this.value);
}

class _TimeSeriesPanelState extends ConsumerState<TimeSeriesPanel> {
  String _selectedChannel = 'CO2';
  final List<String> _channels = ['CO2', 'CH4', 'Temperature', 'Pressure'];
  
  // Separate data buffers for each channel (real-time mode)
  final Map<String, List<DataPoint>> _channelBuffers = {
    'CO2': [],
    'CH4': [],
    'Temperature': [],
    'Pressure': [],
  };
  
  // Historical mode: boundary indices for RANSAC fitting
  // null means use full dataset, otherwise use dataPoints[startIdx:endIdx]
  int? _historicalStartIdx;
  int? _historicalEndIdx;
  
  // Track which measurement is currently loaded to detect changes
  String? _currentMeasurementId;
  
  // Get current channel's buffer
  List<DataPoint> get _currentBuffer => _channelBuffers[_selectedChannel] ?? [];

  /// Run RANSAC on the current channel's buffer (real-time mode only)
  void _runRansacOnCurrentBuffer() {
    final buffer = _currentBuffer;
    
    // Need at least 10 points for meaningful RANSAC
    if (buffer.length < 10) return;
    
    // Convert DataPoints to FluxPoints using RELATIVE timestamps
    // First timestamp becomes t=0
    final startTime = buffer.first.timestamp;
    final fluxPoints = buffer.map((dp) {
      final relativeSeconds = dp.timestamp.difference(startTime).inMilliseconds / 1000.0;
      return FluxPoint(relativeSeconds, dp.value);
    }).toList();
    
    try {
      final ransacService = ref.read(ransacServiceProvider);
      
      // Calculate threshold based on data range (5% of range)
      final values = buffer.map((dp) => dp.value).toList();
      final minValue = values.reduce((a, b) => a < b ? a : b);
      final maxValue = values.reduce((a, b) => a > b ? a : b);
      final threshold = (maxValue - minValue) * 0.05;
      
      // Run RANSAC
      final result = ransacService.calculateFluxRansac(
        fluxPoints,
        threshold,
        iterations: 200,
      );
      
      // Update the flux result provider
      ref.read(fluxResultProvider.notifier).updateResult(result);
    } catch (e) {
      print('Error running RANSAC: $e');
    }
  }

  /// Run RANSAC on historical data with optional boundary constraints
  void _runRansacOnHistoricalData(List<DataPoint> allData) {
    if (allData.isEmpty) {
      ref.read(fluxResultProvider.notifier).clear();
      return;
    }
    
    // Determine the range to fit
    final startIdx = _historicalStartIdx ?? 0;
    final endIdx = _historicalEndIdx ?? allData.length - 1;
    
    // Validate indices
    if (startIdx < 0 || endIdx >= allData.length || startIdx >= endIdx) {
      ref.read(fluxResultProvider.notifier).clear();
      return;
    }
    
    // Extract subset
    final dataSubset = allData.sublist(startIdx, endIdx + 1);
    
    // Need at least 10 points for meaningful RANSAC
    if (dataSubset.length < 10) {
      ref.read(fluxResultProvider.notifier).clear();
      return;
    }
    
    // Convert to FluxPoints with RELATIVE timestamps
    final startTime = dataSubset.first.timestamp;
    final fluxPoints = dataSubset.map((dp) {
      final relativeSeconds = dp.timestamp.difference(startTime).inMilliseconds / 1000.0;
      return FluxPoint(relativeSeconds, dp.value);
    }).toList();
    
    try {
      final ransacService = ref.read(ransacServiceProvider);
      
      // Calculate threshold based on data range (5% of range)
      final values = dataSubset.map((dp) => dp.value).toList();
      final minValue = values.reduce((a, b) => a < b ? a : b);
      final maxValue = values.reduce((a, b) => a > b ? a : b);
      final threshold = (maxValue - minValue) * 0.05;
      
      // Run RANSAC
      final result = ransacService.calculateFluxRansac(
        fluxPoints,
        threshold,
        iterations: 200,
      );
      
      // Update the flux result provider
      ref.read(fluxResultProvider.notifier).updateResult(result);
      
      // Save statistics to measurement if in historical mode
      final selectedMeasurementAsync = ref.read(selectedMeasurementProvider);
      selectedMeasurementAsync.whenData((measurement) {
        if (measurement != null) {
          _saveStatisticsToMeasurement(measurement, _selectedChannel, result);
        }
      });
    } catch (e) {
      print('Error running RANSAC on historical data: $e');
      ref.read(fluxResultProvider.notifier).clear();
    }
  }

  /// Extract data points from a measurement's samples for the selected channel
  List<DataPoint> _getHistoricalData(PneumaGeRecord measurement, String channel) {
    // Check if filters are enabled in settings
    final filtersEnabled = ref.watch(filtersEnabledProvider);
    
    // Use compatibility layer to get samples
    // Use filtered data if filters are enabled, otherwise use raw data
    final samples = measurement.getSamples(useFiltered: filtersEnabled);
    
    return samples
        .where((sample) => sample.channelValues.containsKey(channel))
        .map((sample) => DataPoint(sample.timestamp, sample.channelValues[channel]!))
        .toList();
  }
  
  // Boundary dragging state
  String? _draggingBoundary; // 'start' or 'end' or null
  
  void _handleBoundaryDragStart(DragStartDetails details, List<DataPoint> dataPoints) {
    // Determine if user clicked near a boundary marker
    // This will be refined once we know the actual screen positions
    // For now, just detect which boundary is closer
    _draggingBoundary = null; // Will be set in drag update based on position
  }
  
  void _handleBoundaryDragUpdate(DragUpdateDetails details, List<DataPoint> dataPoints) {
    // Convert screen position to data index
    // This requires knowing the plot dimensions and leftMargin
    // For now, we'll implement a simple version that works with the painter's coordinate system
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final size = renderBox.size;
    final localPosition = details.localPosition;
    
    // Account for plot margins (matching painter's leftMargin)
    const double leftMargin = _TimeSeriesPlotPainter.leftMargin;
    final plotWidth = size.width - leftMargin;
    
    if (localPosition.dx < leftMargin || localPosition.dx > size.width) return;
    
    // Convert x position to data index
    final normalizedX = (localPosition.dx - leftMargin) / plotWidth;
    final newIdx = (normalizedX * dataPoints.length).round().clamp(0, dataPoints.length - 1);
    
    // Determine which boundary to move (or initialize dragging)
    if (_draggingBoundary == null) {
      // First drag update - determine which boundary is closer
      final startIdx = _historicalStartIdx ?? 0;
      final endIdx = _historicalEndIdx ?? (dataPoints.length - 1);
      
      final distToStart = (newIdx - startIdx).abs();
      final distToEnd = (newIdx - endIdx).abs();
      
      _draggingBoundary = (distToStart < distToEnd) ? 'start' : 'end';
    }
    
    setState(() {
      if (_draggingBoundary == 'start') {
        _historicalStartIdx = newIdx.clamp(0, (_historicalEndIdx ?? dataPoints.length - 1) - 10);
      } else if (_draggingBoundary == 'end') {
        _historicalEndIdx = newIdx.clamp((_historicalStartIdx ?? 0) + 10, dataPoints.length - 1);
      }
    });
    
    // Re-run RANSAC with new boundaries
    _runRansacOnHistoricalData(dataPoints);
  }
  
  void _handleBoundaryDragEnd(DragEndDetails details, List<DataPoint> dataPoints) {
    _draggingBoundary = null;
    
    // Save boundaries to measurement if in historical mode
    final selectedMeasurementAsync = ref.read(selectedMeasurementProvider);
    selectedMeasurementAsync.whenData((measurement) {
      if (measurement != null && _historicalStartIdx != null && _historicalEndIdx != null) {
        _saveBoundariesToMeasurement(measurement, _selectedChannel, _historicalStartIdx!, _historicalEndIdx!);
      }
    });
  }
  
  /// Save the current boundary values to the measurement
  /// Save fit boundaries for a specific channel to the measurement
  Future<void> _saveBoundariesToMeasurement(
    PneumaGeRecord measurement,
    String channel,
    int startIdx,
    int endIdx,
  ) async {
    try {
      final projectService = ref.read(projectServiceProvider);
      // Use factory helper to update channel stats
      final stats = MeasurementStats(
        flux: 0.0,
        fluxError: 0.0,
        rSquared: 0.0,
        slope: 0.0,
        inlierCount: endIdx - startIdx,
      );
      final updatedMeasurement = PneumaGeRecordFactory.updateChannelStats(
        measurement, channel, startIdx, endIdx, stats);
      await projectService.updateMeasurement(updatedMeasurement);
      // Invalidate the measurement provider to reflect changes
      ref.invalidate(selectedMeasurementProvider);
    } catch (e) {
      print('Error saving fit boundaries: $e');
    }
  }

  /// Save statistics for a specific channel to the measurement
  Future<void> _saveStatisticsToMeasurement(
    PneumaGeRecord measurement,
    String channel,
    FluxResult result,
  ) async {
    try {
      final projectService = ref.read(projectServiceProvider);
      final stats = MeasurementStats(
        flux: result.fluxPpmPerSecond,
        fluxError: result.fluxError,
        rSquared: result.rSquared,
        slope: result.slope,
        inlierCount: result.inlierCount,
      );
      // Get saved boundaries to pass along
      final bounds = measurement.getFitBoundaries(channel) ?? [0, 0];
      
      print('Saving stats for $channel: flux=${stats.flux.toStringAsFixed(3)}, '
            'r²=${stats.rSquared.toStringAsFixed(3)}, boundaries=$bounds');
      
      final updatedMeasurement = PneumaGeRecordFactory.updateChannelStats(
        measurement, channel, bounds[0], bounds[1], stats);
      await projectService.updateMeasurement(updatedMeasurement);
      
      // Verify it was saved
      final verifyStats = updatedMeasurement.getStatistics(channel);
      print('Verified saved stats: flux=${verifyStats?.flux.toStringAsFixed(3)}, '
            'r²=${verifyStats?.rSquared.toStringAsFixed(3)}');
      
      // Invalidate the measurement provider to reflect changes
      ref.invalidate(selectedMeasurementProvider);
    } catch (e) {
      print('Error saving statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if a measurement is selected (historical mode)
    final selectedMeasurementAsync = ref.watch(selectedMeasurementProvider);
    
    // Determine if we're in historical mode
    final isHistoricalMode = selectedMeasurementAsync.maybeWhen(
      data: (measurement) => measurement != null,
      orElse: () => false,
    );
    
    // In real-time mode, listen to data streams
    if (!isHistoricalMode) {
      // Listen to gas concentration stream and update CO2/CH4 buffers
      // Note: In a real system, you'd differentiate between CO2 and CH4
      // For now, we'll add to both buffers (you may want to adjust this logic)
      ref.listen(gasConcentrationProvider, (previous, next) {
        next.whenData((value) {
          setState(() {
            final timestamp = DateTime.now();
            // Add to both CO2 and CH4 buffers (adjust if you have separate streams)
            _channelBuffers['CO2']!.add(DataPoint(timestamp, value));
            _channelBuffers['CH4']!.add(DataPoint(timestamp, value));
            
            // Keep last 1000 points per channel
            if (_channelBuffers['CO2']!.length > 1000) {
              _channelBuffers['CO2']!.removeAt(0);
            }
            if (_channelBuffers['CH4']!.length > 1000) {
              _channelBuffers['CH4']!.removeAt(0);
            }
            
            // Run RANSAC on CO2/CH4 data (gas concentration channels)
            if (_selectedChannel == 'CO2' || _selectedChannel == 'CH4') {
              _runRansacOnCurrentBuffer();
            }
          });
        });
      });
      
      // Listen to chamber stats stream and update Temperature/Pressure buffers
      ref.listen(chamberStatsProvider, (previous, next) {
        next.whenData((stats) {
          setState(() {
            final timestamp = DateTime.now();
            _channelBuffers['Temperature']!.add(DataPoint(timestamp, stats.temperature));
            _channelBuffers['Pressure']!.add(DataPoint(timestamp, stats.pressure));
            
            // Keep last 1000 points per channel
            if (_channelBuffers['Temperature']!.length > 1000) {
              _channelBuffers['Temperature']!.removeAt(0);
            }
            if (_channelBuffers['Pressure']!.length > 1000) {
              _channelBuffers['Pressure']!.removeAt(0);
            }
            
            // Run RANSAC on Temperature/Pressure data if selected
            if (_selectedChannel == 'Temperature' || _selectedChannel == 'Pressure') {
              _runRansacOnCurrentBuffer();
            }
          });
        });
      });
    }

    final headerStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
      letterSpacing: 1.2,
    );

    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with channel selector
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Text('TIME SERIES', style: headerStyle),
                const Spacer(),
                _ChannelSelector(
                  channels: _channels,
                  selected: _selectedChannel,
                  onChanged: (ch) {
                    setState(() {
                      _selectedChannel = ch;
                      // Reset boundaries when switching channels in historical mode
                      _historicalStartIdx = null;
                      _historicalEndIdx = null;
                    });
                    // Re-run RANSAC on the newly selected channel's buffer (real-time mode)
                    _runRansacOnCurrentBuffer();
                  },
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.divider,
          ),

          // Plot area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: selectedMeasurementAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error loading measurement',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  data: (measurement) {
                    // Detect measurement change and reset boundaries
                    if (measurement != null && _currentMeasurementId != measurement.id) {
                      // This will be executed synchronously before the rest of the build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _currentMeasurementId = measurement.id;
                          _historicalStartIdx = null;
                          _historicalEndIdx = null;
                        });
                      });
                    } else if (measurement == null && _currentMeasurementId != null) {
                      // Switched to real-time mode
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _currentMeasurementId = null;
                          _historicalStartIdx = null;
                          _historicalEndIdx = null;
                        });
                      });
                    }
                    
                    // Determine which data to display
                    final dataPoints = measurement != null
                        ? _getHistoricalData(measurement, _selectedChannel)
                        : _currentBuffer;
                    
                    // Handle historical mode boundary initialization and RANSAC
                    if (measurement != null && dataPoints.isNotEmpty) {
                      // Load saved boundaries from measurement, or initialize to full dataset
                      final savedBounds = measurement.getFitBoundaries(_selectedChannel);
                      
                      if (_historicalStartIdx == null || _historicalEndIdx == null ||
                          _historicalEndIdx! >= dataPoints.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            if (savedBounds != null && savedBounds.length == 2) {
                              // Restore saved boundaries, clamped to valid range
                              _historicalStartIdx = savedBounds[0].clamp(0, dataPoints.length - 1);
                              _historicalEndIdx = savedBounds[1].clamp(_historicalStartIdx! + 1, dataPoints.length - 1);
                            } else {
                              // Default to full dataset
                              _historicalStartIdx = 0;
                              _historicalEndIdx = dataPoints.length - 1;
                            }
                          });
                          _runRansacOnHistoricalData(dataPoints);
                        });
                      } else {
                        // Boundaries are set, ensure RANSAC is current
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _runRansacOnHistoricalData(dataPoints);
                        });
                      }
                    }
                    
                    // Get flux result for fitted line (both modes now)
                    final fluxResult = ref.watch(fluxResultProvider);
                    
                    final emptyMessage = measurement != null
                        ? '$_selectedChannel — no data in this measurement'
                        : '$_selectedChannel — awaiting data';
                    
                    return GestureDetector(
                      onPanStart: (details) {
                        if (measurement != null && dataPoints.isNotEmpty) {
                          _handleBoundaryDragStart(details, dataPoints);
                        }
                      },
                      onPanUpdate: (details) {
                        if (measurement != null && dataPoints.isNotEmpty) {
                          _handleBoundaryDragUpdate(details, dataPoints);
                        }
                      },
                      onPanEnd: (details) {
                        if (measurement != null && dataPoints.isNotEmpty) {
                          _handleBoundaryDragEnd(details, dataPoints);
                        }
                      },
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _TimeSeriesPlotPainter(
                          dataPoints: dataPoints,
                          startTime: dataPoints.isNotEmpty 
                              ? dataPoints.first.timestamp 
                              : DateTime.now(),
                          fluxResult: fluxResult,
                          isHistoricalMode: measurement != null,
                          boundaryStartIdx: _historicalStartIdx,
                          boundaryEndIdx: _historicalEndIdx,
                        ),
                        child: dataPoints.isEmpty
                            ? Center(
                                child: Text(
                                  emptyMessage,
                                  style: TextStyle(
                                    fontFamily: 'RobotoMono',
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelSelector extends StatelessWidget {
  final List<String> channels;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChannelSelector({
    required this.channels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: AppTheme.surfaceLight,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9,
            color: AppTheme.textPrimary,
          ),
          iconSize: 14,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          items: channels
              .map((ch) => DropdownMenuItem(value: ch, child: Text(ch)))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

class _TimeSeriesPlotPainter extends CustomPainter {
  final List<DataPoint> dataPoints;
  final DateTime startTime;
  final FluxResult? fluxResult;
  final bool isHistoricalMode;
  final int? boundaryStartIdx;
  final int? boundaryEndIdx;
  static const double leftMargin = 45.0; // Space for y-axis labels

  _TimeSeriesPlotPainter({
    required this.dataPoints,
    required this.startTime,
    this.fluxResult,
    this.isHistoricalMode = false,
    this.boundaryStartIdx,
    this.boundaryEndIdx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid first
    _drawGrid(canvas, size);
    
    // Draw data if available
    if (dataPoints.isEmpty) return;
    
    final minValue = dataPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxValue = dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final valueRange = maxValue - minValue;
    
    // Add 10% padding to value range
    final paddedMin = minValue - (valueRange * 0.1);
    final paddedMax = maxValue + (valueRange * 0.1);
    final paddedRange = paddedMax - paddedMin;
    
    // Avoid division by zero
    if (paddedRange == 0) return;
    
    // Draw y-axis labels
    _drawYAxisLabels(canvas, size, paddedMin, paddedMax);
    
    // Draw data line
    final linePaint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final plotWidth = size.width - leftMargin;
    final path = Path();
    bool firstPoint = true;
    
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      // X is based on index position, evenly distributed across plot width
      final xRatio = i / (dataPoints.length - 1);
      final x = leftMargin + (xRatio * plotWidth);
      final normalizedValue = (point.value - paddedMin) / paddedRange;
      final y = size.height - (normalizedValue * size.height);
      
      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, linePaint);
    
    // Draw data points
    final pointPaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      // X is based on index position
      final xRatio = i / (dataPoints.length - 1);
      final x = leftMargin + (xRatio * plotWidth);
      final normalizedValue = (point.value - paddedMin) / paddedRange;
      final y = size.height - (normalizedValue * size.height);
      
      canvas.drawCircle(Offset(x, y), 2.0, pointPaint);
    }
    
    // Draw fitted line if available
    if (fluxResult != null && dataPoints.length >= 2) {
      _drawFittedLine(canvas, size, paddedMin, paddedMax, paddedRange);
    }
    
    // Draw boundary markers in historical mode
    if (isHistoricalMode && boundaryStartIdx != null && boundaryEndIdx != null) {
      _drawBoundaryMarkers(canvas, size, plotWidth);
    }
  }
  
  void _drawBoundaryMarkers(Canvas canvas, Size size, double plotWidth) {
    if (dataPoints.isEmpty || boundaryStartIdx == null || boundaryEndIdx == null) return;
    
    final boundaryPaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final handlePaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.fill;
    
    // Calculate x positions for boundaries
    final startXRatio = boundaryStartIdx! / (dataPoints.length - 1);
    final endXRatio = boundaryEndIdx! / (dataPoints.length - 1);
    
    final startX = leftMargin + (startXRatio * plotWidth);
    final endX = leftMargin + (endXRatio * plotWidth);
    
    // Draw vertical lines
    canvas.drawLine(Offset(startX, 0), Offset(startX, size.height), boundaryPaint);
    canvas.drawLine(Offset(endX, 0), Offset(endX, size.height), boundaryPaint);
    
    // Draw draggable handles (triangles at top and bottom)
    const handleSize = 8.0;
    
    // Start boundary handles
    final startTopPath = Path()
      ..moveTo(startX, 0)
      ..lineTo(startX - handleSize, handleSize)
      ..lineTo(startX + handleSize, handleSize)
      ..close();
    canvas.drawPath(startTopPath, handlePaint);
    
    final startBottomPath = Path()
      ..moveTo(startX, size.height)
      ..lineTo(startX - handleSize, size.height - handleSize)
      ..lineTo(startX + handleSize, size.height - handleSize)
      ..close();
    canvas.drawPath(startBottomPath, handlePaint);
    
    // End boundary handles
    final endTopPath = Path()
      ..moveTo(endX, 0)
      ..lineTo(endX - handleSize, handleSize)
      ..lineTo(endX + handleSize, handleSize)
      ..close();
    canvas.drawPath(endTopPath, handlePaint);
    
    final endBottomPath = Path()
      ..moveTo(endX, size.height)
      ..lineTo(endX - handleSize, size.height - handleSize)
      ..lineTo(endX + handleSize, size.height - handleSize)
      ..close();
    canvas.drawPath(endBottomPath, handlePaint);
  }
  
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.divider.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    final plotWidth = size.width - leftMargin;

    // Horizontal grid lines
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    for (int i = 1; i < 8; i++) {
      final x = leftMargin + (plotWidth * i / 8);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }
  
  void _drawYAxisLabels(Canvas canvas, Size size, double minValue, double maxValue) {
    const numLabels = 6; // 0%, 20%, 40%, 60%, 80%, 100%
    final textStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: AppTheme.textSecondary,
    );
    
    for (int i = 0; i < numLabels; i++) {
      final fraction = i / (numLabels - 1);
      final value = minValue + (maxValue - minValue) * fraction;
      final y = size.height - (fraction * size.height);
      
      // Format value to 1 decimal place
      final valueText = value.toStringAsFixed(1);
      
      final textSpan = TextSpan(
        text: valueText,
        style: textStyle,
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      // Position text to the left of the plot area
      textPainter.paint(
        canvas,
        Offset(4, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_TimeSeriesPlotPainter oldDelegate) {
    return dataPoints != oldDelegate.dataPoints || 
           fluxResult != oldDelegate.fluxResult;
  }
  
  /// Draw the fitted line from RANSAC with color-coded dashing
  void _drawFittedLine(Canvas canvas, Size size, double paddedMin, double paddedMax, double paddedRange) {
    if (fluxResult == null || dataPoints.isEmpty) return;
    
    // Determine color based on R² quality
    // Excellent: > 0.95 (green)
    // Good: 0.90-0.95 (amber)
    // Fair: 0.80-0.90 (orange)
    // Poor: < 0.80 (red)
    final Color lineColor;
    final rSquared = fluxResult!.rSquared;
    if (rSquared >= 0.95) {
      lineColor = AppTheme.accent; // Green
    } else if (rSquared >= 0.90) {
      lineColor = Colors.amber; // Amber
    } else if (rSquared >= 0.80) {
      lineColor = Colors.orange; // Orange
    } else {
      lineColor = AppTheme.danger; // Red
    }
    
    // Create paint with dashed line
    final fitPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final plotWidth = size.width - leftMargin;
    
    // Determine the data range for the fit
    // In historical mode with boundaries, use only the subset
    final int fitStartIdx;
    final int fitEndIdx;
    
    if (isHistoricalMode && boundaryStartIdx != null && boundaryEndIdx != null) {
      fitStartIdx = boundaryStartIdx!;
      fitEndIdx = boundaryEndIdx!;
    } else {
      fitStartIdx = 0;
      fitEndIdx = dataPoints.length - 1;
    }
    
    if (fitStartIdx >= fitEndIdx || fitEndIdx >= dataPoints.length) return;
    
    // Get the subset of data used for fitting
    final fitStartTime = dataPoints[fitStartIdx].timestamp;
    final fitEndTime = dataPoints[fitEndIdx].timestamp;
    final timeRangeSeconds = fitEndTime.difference(fitStartTime).inMilliseconds / 1000.0;
    
    if (timeRangeSeconds == 0) return;
    
    // Calculate y values at start and end using y = mx + c
    // At start: t=0 (relative to fit start)
    // At end: t=timeRangeSeconds
    final slope = fluxResult!.slope;
    final intercept = fluxResult!.intercept;
    
    final yStart = slope * 0.0 + intercept;  // t=0 at start
    final yEnd = slope * timeRangeSeconds + intercept;  // t=duration at end
    
    // Map to screen coordinates
    // X positions should match the data indices
    final startXRatio = fitStartIdx / (dataPoints.length - 1);
    final endXRatio = fitEndIdx / (dataPoints.length - 1);
    
    final xStart = leftMargin + (startXRatio * plotWidth);
    final xEnd = leftMargin + (endXRatio * plotWidth);
    
    final normalizedYStart = (yStart - paddedMin) / paddedRange;
    final normalizedYEnd = (yEnd - paddedMin) / paddedRange;
    
    final screenYStart = size.height - (normalizedYStart * size.height);
    final screenYEnd = size.height - (normalizedYEnd * size.height);
    
    // Clip line to plot boundaries (0 to size.height)
    final clippedPoints = _clipLineToRect(
      xStart, screenYStart,
      xEnd, screenYEnd,
      leftMargin, 0, // top-left of plot area
      leftMargin + plotWidth, size.height, // bottom-right of plot area
    );
    
    if (clippedPoints == null) return; // Line is completely outside
    
    // Draw dashed line
    _drawDashedLine(
      canvas,
      Offset(clippedPoints.$1, clippedPoints.$2),
      Offset(clippedPoints.$3, clippedPoints.$4),
      fitPaint,
      dashWidth: 8.0,
      dashSpace: 4.0,
    );
  }
  
  /// Clip a line segment to a rectangular region (Cohen-Sutherland algorithm)
  /// Returns (x1, y1, x2, y2) of clipped line, or null if completely outside
  (double, double, double, double)? _clipLineToRect(
    double x1, double y1,
    double x2, double y2,
    double xMin, double yMin,
    double xMax, double yMax,
  ) {
    // Cohen-Sutherland outcodes
    const int INSIDE = 0; // 0000
    const int LEFT = 1;   // 0001
    const int RIGHT = 2;  // 0010
    const int BOTTOM = 4; // 0100
    const int TOP = 8;    // 1000
    
    int computeOutCode(double x, double y) {
      int code = INSIDE;
      if (x < xMin) code |= LEFT;
      else if (x > xMax) code |= RIGHT;
      if (y < yMin) code |= TOP;
      else if (y > yMax) code |= BOTTOM;
      return code;
    }
    
    int outcode1 = computeOutCode(x1, y1);
    int outcode2 = computeOutCode(x2, y2);
    
    while (true) {
      if ((outcode1 | outcode2) == 0) {
        // Both endpoints inside
        return (x1, y1, x2, y2);
      } else if ((outcode1 & outcode2) != 0) {
        // Both endpoints outside on same side
        return null;
      } else {
        // Line crosses boundary - clip it
        int outcodeOut = outcode1 != 0 ? outcode1 : outcode2;
        double x, y;
        
        if ((outcodeOut & TOP) != 0) {
          x = x1 + (x2 - x1) * (yMin - y1) / (y2 - y1);
          y = yMin;
        } else if ((outcodeOut & BOTTOM) != 0) {
          x = x1 + (x2 - x1) * (yMax - y1) / (y2 - y1);
          y = yMax;
        } else if ((outcodeOut & RIGHT) != 0) {
          y = y1 + (y2 - y1) * (xMax - x1) / (x2 - x1);
          x = xMax;
        } else { // LEFT
          y = y1 + (y2 - y1) * (xMin - x1) / (x2 - x1);
          x = xMin;
        }
        
        if (outcodeOut == outcode1) {
          x1 = x;
          y1 = y;
          outcode1 = computeOutCode(x1, y1);
        } else {
          x2 = x;
          y2 = y;
          outcode2 = computeOutCode(x2, y2);
        }
      }
    }
  }
  
  /// Helper to draw a dashed line
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 5.0,
    double dashSpace = 3.0,
  }) {
    final path = Path();
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    
    final dx = (end.dx - start.dx) / distance;
    final dy = (end.dy - start.dy) / distance;
    
    for (int i = 0; i < dashCount; i++) {
      final dashStart = Offset(
        start.dx + dx * (i * (dashWidth + dashSpace)),
        start.dy + dy * (i * (dashWidth + dashSpace)),
      );
      final dashEnd = Offset(
        start.dx + dx * (i * (dashWidth + dashSpace) + dashWidth),
        start.dy + dy * (i * (dashWidth + dashSpace) + dashWidth),
      );
      
      path.moveTo(dashStart.dx, dashStart.dy);
      path.lineTo(dashEnd.dx, dashEnd.dy);
    }
    
    canvas.drawPath(path, paint);
  }
}
