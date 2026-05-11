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

import 'dart:math';

/// Represents a single data point for flux analysis.
/// Compatible with time series data from measurements.
class FluxPoint {
  final double timestamp;
  final double concentration;

  FluxPoint(this.timestamp, this.concentration);

  /// Create from DateTime and concentration value
  factory FluxPoint.fromDateTime(DateTime time, double concentration) {
    return FluxPoint(
      time.millisecondsSinceEpoch / 1000.0, // Convert to seconds
      concentration,
    );
  }
}

/// The output of the RANSAC linear regression process.
class FluxResult {
  /// Slope of the fitted line (concentration change per second)
  final double slope;
  
  /// Y-intercept of the fitted line
  final double intercept;
  
  /// Data points that were considered inliers in the fit
  final List<FluxPoint> inliers;
  
  /// R-squared value indicating quality of fit (0.0 to 1.0)
  /// Values closer to 1.0 indicate better fit
  final double rSquared;

  FluxResult({
    required this.slope,
    required this.intercept,
    required this.inliers,
    required this.rSquared,
  });

  /// Number of inliers used in the fit
  int get inlierCount => inliers.length;

  /// Fraction of data points that were inliers (0.0 to 1.0)
  double inlierFraction(int totalPoints) {
    return totalPoints > 0 ? inliers.length / totalPoints : 0.0;
  }

  /// Calculate flux in ppm/s
  double get fluxPpmPerSecond => slope;

  /// Calculate flux error estimate based on residuals
  double get fluxError {
    if (inliers.length < 2) return 0.0;
    
    double sumSquaredResiduals = 0.0;
    for (var point in inliers) {
      double predicted = slope * point.timestamp + intercept;
      double residual = point.concentration - predicted;
      sumSquaredResiduals += residual * residual;
    }
    
    // Standard error of the slope
    int n = inliers.length;
    double mse = sumSquaredResiduals / (n - 2);
    
    double sumSquaredX = 0.0;
    double meanX = inliers.map((p) => p.timestamp).reduce((a, b) => a + b) / n;
    for (var point in inliers) {
      sumSquaredX += pow(point.timestamp - meanX, 2);
    }
    
    return sumSquaredX > 0 ? sqrt(mse / sumSquaredX) : 0.0;
  }

  /// Predict concentration at a given timestamp
  double predict(double timestamp) {
    return slope * timestamp + intercept;
  }
}

/// Service for performing RANSAC-based linear regression on time series data.
/// 
/// RANSAC (RANdom SAmple Consensus) is a robust fitting method that handles
/// outliers and noisy data common in field measurements.
class RansacService {
  final Random _random = Random();

  /// Executes RANSAC with vertical distance minimization and Least Squares refinement.
  /// 
  /// Parameters:
  /// - [data]: List of flux data points to fit
  /// - [threshold]: Maximum vertical distance for a point to be considered an inlier
  /// - [iterations]: Number of RANSAC iterations (default: 200)
  /// 
  /// Returns a [FluxResult] containing the best-fit line parameters and quality metrics.
  /// 
  /// Throws [Exception] if insufficient data points (< 2) are provided.
  FluxResult calculateFluxRansac(
    List<FluxPoint> data,
    double threshold, {
    int iterations = 200,
  }) {
    if (data.length < 2) {
      throw Exception("Insufficient data points for RANSAC analysis.");
    }

    FluxResult? bestModel;
    int maxInliers = -1;

    for (int i = 0; i < iterations; i++) {
      // 1. Randomly sample two points to define a candidate line
      final p1 = data[_random.nextInt(data.length)];
      final p2 = data[_random.nextInt(data.length)];

      if (p1.timestamp == p2.timestamp) continue;

      // Candidate model: y = mx + c
      double slope = (p2.concentration - p1.concentration) / 
                     (p2.timestamp - p1.timestamp);
      double intercept = p1.concentration - (slope * p1.timestamp);

      // 2. Count inliers based on the vertical residual threshold
      List<FluxPoint> currentInliers = [];
      for (var point in data) {
        double predicted = (slope * point.timestamp) + intercept;
        double residual = (point.concentration - predicted).abs();

        if (residual <= threshold) {
          currentInliers.add(point);
        }
      }

      // 3. Keep the consensus set with the highest population
      if (currentInliers.length > maxInliers) {
        maxInliers = currentInliers.length;
        
        // Refine the best model using all identified inliers
        bestModel = _performLeastSquares(currentInliers);
      }
    }

    // Default to a standard fit if no consensus is found
    return bestModel ?? _performLeastSquares(data);
  }

  /// Perform RANSAC on a subset of data defined by start/end indices.
  /// 
  /// Useful for historical data viewing where user selects a time window.
  FluxResult calculateFluxRansacWindow(
    List<FluxPoint> data,
    int startIndex,
    int endIndex,
    double threshold, {
    int iterations = 200,
  }) {
    if (startIndex < 0 || endIndex >= data.length || startIndex >= endIndex) {
      throw Exception("Invalid window boundaries for RANSAC analysis.");
    }

    final windowData = data.sublist(startIndex, endIndex + 1);
    return calculateFluxRansac(windowData, threshold, iterations: iterations);
  }

  /// Standard Linear Regression to refine the model of the inlier set.
  /// 
  /// Uses Least Squares method to find the best-fit line through the given points.
  FluxResult _performLeastSquares(List<FluxPoint> points) {
    int n = points.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (var p in points) {
      sumX += p.timestamp;
      sumY += p.concentration;
      sumXY += p.timestamp * p.concentration;
      sumX2 += p.timestamp * p.timestamp;
    }

    double denominator = (n * sumX2 - sumX * sumX);
    double slope = denominator == 0 ? 0 : (n * sumXY - sumX * sumY) / denominator;
    double intercept = (sumY - slope * sumX) / n;

    // Calculate R-squared for quality assessment
    double meanY = sumY / n;
    double ssTot = 0, ssRes = 0;
    for (var p in points) {
      double predicted = slope * p.timestamp + intercept;
      ssTot += pow(p.concentration - meanY, 2);
      ssRes += pow(p.concentration - predicted, 2);
    }
    double rSquared = ssTot == 0 ? 0 : 1 - (ssRes / ssTot);

    return FluxResult(
      slope: slope,
      intercept: intercept,
      inliers: points,
      rSquared: rSquared,
    );
  }

  /// Convert a list of time series data points to FluxPoint format.
  /// 
  /// Helper method to bridge between UI data structures and RANSAC input.
  static List<FluxPoint> fromDataPoints(List<({DateTime timestamp, double value})> dataPoints) {
    return dataPoints
        .map((dp) => FluxPoint.fromDateTime(dp.timestamp, dp.value))
        .toList();
  }
}
