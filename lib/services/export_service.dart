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

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/measurement.dart';
import '../models/project.dart';

/// Handles exporting measurements and projects to JSON, CSV, and ZIP.
class ExportService {
  // ---------------------------------------------------------------------------
  // Single measurement exports
  // ---------------------------------------------------------------------------

  /// Export a single measurement as a JSON string.
  String measurementToJson(Measurement measurement) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(measurement.toJson());
  }

  /// Export a single measurement as a CSV string.
  ///
  /// Header comment block contains metadata, followed by a standard CSV table
  /// with timestamp and one column per channel.
  String measurementToCsv(Measurement measurement) {
    final buf = StringBuffer();

    // Metadata header
    buf.writeln('# measurement_id: ${measurement.id}');
    buf.writeln('# project_id: ${measurement.projectId}');
    buf.writeln('# device_id: ${measurement.deviceId}');
    buf.writeln(
      '# location: ${measurement.location.latitude}, '
      '${measurement.location.longitude}',
    );
    if (measurement.location.altitude != null) {
      buf.writeln('# altitude: ${measurement.location.altitude}');
    }
    buf.writeln('# start_time: ${measurement.startTime.toIso8601String()}');
    if (measurement.endTime != null) {
      buf.writeln('# end_time: ${measurement.endTime!.toIso8601String()}');
    }
    if (measurement.notes != null) {
      buf.writeln('# notes: ${measurement.notes}');
    }

    // Collect all channel IDs across samples to build consistent columns
    final channelIds = <String>{};
    for (final sample in measurement.samples) {
      channelIds.addAll(sample.channelValues.keys);
    }
    final sortedChannels = channelIds.toList()..sort();

    // CSV header row
    buf.writeln(['timestamp', ...sortedChannels].join(','));

    // Data rows
    for (final sample in measurement.samples) {
      final row = [
        sample.timestamp.toIso8601String(),
        ...sortedChannels.map(
          (ch) => sample.channelValues[ch]?.toString() ?? '',
        ),
      ];
      buf.writeln(row.join(','));
    }

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Project-level concatenated exports
  // ---------------------------------------------------------------------------

  /// Export all measurements in a project as a single concatenated JSON array.
  String projectToJson(Project project, List<Measurement> measurements) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'project': project.toJson(),
      'measurements': measurements.map((m) => m.toJson()).toList(),
    });
  }

  /// Export all measurements in a project as a single concatenated CSV.
  ///
  /// Adds a `measurement_id` column to distinguish rows from different
  /// measurements.
  String projectToCsv(Project project, List<Measurement> measurements) {
    final buf = StringBuffer();

    // Project metadata header
    buf.writeln('# project_id: ${project.id}');
    buf.writeln('# project_name: ${project.name}');
    buf.writeln('# filename_prefix: ${project.filenamePrefix}');
    buf.writeln('# created_at: ${project.createdAt.toIso8601String()}');

    // Collect all channel IDs across all measurements
    final channelIds = <String>{};
    for (final m in measurements) {
      for (final sample in m.samples) {
        channelIds.addAll(sample.channelValues.keys);
      }
    }
    final sortedChannels = channelIds.toList()..sort();

    // CSV header row with measurement_id prefix
    buf.writeln(['measurement_id', 'timestamp', ...sortedChannels].join(','));

    // Data rows
    for (final m in measurements) {
      for (final sample in m.samples) {
        final row = [
          m.id,
          sample.timestamp.toIso8601String(),
          ...sortedChannels.map(
            (ch) => sample.channelValues[ch]?.toString() ?? '',
          ),
        ];
        buf.writeln(row.join(','));
      }
    }

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // ZIP project export
  // ---------------------------------------------------------------------------

  /// Create a ZIP archive containing per-measurement JSON and CSV files,
  /// plus concatenated project-level JSON and CSV files.
  ///
  /// Returns the path to the generated ZIP file.
  Future<String> projectToZip(
    Project project,
    List<Measurement> measurements,
  ) async {
    final archive = Archive();

    // Per-measurement files
    for (var i = 0; i < measurements.length; i++) {
      final m = measurements[i];
      final index = (i + 1).toString().padLeft(3, '0');
      final baseName = '${project.filenamePrefix}_$index';

      final jsonContent = measurementToJson(m);
      archive.addFile(
        ArchiveFile.bytes(
          'measurements/$baseName.json',
          utf8.encode(jsonContent),
        ),
      );

      final csvContent = measurementToCsv(m);
      archive.addFile(
        ArchiveFile.bytes(
          'measurements/$baseName.csv',
          utf8.encode(csvContent),
        ),
      );
    }

    // Concatenated project-level files
    final projectJson = projectToJson(project, measurements);
    archive.addFile(
      ArchiveFile.bytes('project.json', utf8.encode(projectJson)),
    );

    final projectCsv = projectToCsv(project, measurements);
    archive.addFile(
      ArchiveFile.bytes('project.csv', utf8.encode(projectCsv)),
    );

    // Write ZIP to temp directory
    final dir = await getTemporaryDirectory();
    final zipPath = '${dir.path}/${project.filenamePrefix}_export.zip';
    final zipData = ZipEncoder().encode(archive);
    await File(zipPath).writeAsBytes(zipData);

    return zipPath;
  }

  // ---------------------------------------------------------------------------
  // Share via OS share sheet
  // ---------------------------------------------------------------------------

  /// Share a file using the platform's share sheet.
  Future<void> shareFile(String filePath) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)]),
    );
  }
}
