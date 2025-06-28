import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_alarm_manager_poc/hive/models/alarm_action.dart';
import 'package:flutter_alarm_manager_poc/hive/service/database_service.dart';
import 'package:flutter_alarm_manager_poc/hive/service/settings_service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

/// A simple class to encapsulate the result of a service operation.
class ServiceResult {
  ServiceResult({required this.success, required this.message});
  final bool success;
  final String message;
}

class ExportService {
  final SettingsService _settingsService = SettingsService.instance;
  final DatabaseService _databaseService = DatabaseService.instance;

  Future<ServiceResult> _getAndSetExportPath() async {
    final PermissionStatus status;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      return ServiceResult(
          success: false,
          message: 'Storage permission is required to select a path.');
    }

    final path = await FilePicker.platform.getDirectoryPath();

    if (path != null) {
      await _settingsService.setExportPath(path);
      return ServiceResult(success: true, message: 'Export path set to: $path');
    } else {
      return ServiceResult(
          success: false, message: 'Path selection cancelled.');
    }
  }

  // This method now returns a result for the UI to handle.
  Future<ServiceResult> changeExportPath() async {
    return _getAndSetExportPath();
  }

  // The main export method, also refactored to return a ServiceResult.
  Future<ServiceResult> exportData() async {
    var exportPath = _settingsService.getExportPath();

    if (exportPath == null || exportPath.isEmpty) {
      final pathResult = await _getAndSetExportPath();
      if (!pathResult.success) {
        return pathResult; // Propagate the message (e.g., "permission denied")
      }
      exportPath = pathResult.message.replaceFirst('Export path set to: ', '');
    }

    final directory = Directory(exportPath);
    if (!directory.existsSync()) {
      return ServiceResult(
          success: false,
          message: 'Error: The selected directory does not exist.');
    }

    var lastExportedId = -1;
    try {
      final files = directory.listSync();
      for (final file in files) {
        if (file is File) {
          final filename = file.path.split(Platform.pathSeparator).last;
          if (filename.startsWith('tracky_export_prefix_')) {
            final parts = filename.split('_');
            if (parts.length > 3) {
              final id = int.tryParse(parts[3]);
              if (id != null && id > lastExportedId) {
                lastExportedId = id;
              }
            }
          }
        }
      }
    } on Exception catch (e) {
      log('Error scanning directory: $e');
      return ServiceResult(
          success: false,
          message: 'Error scanning directory. Please check permissions.');
    }

    final allActions =
        _databaseService.getAllAlarmActionsMap().cast<int, AlarmAction>();
    final newActions = allActions.entries
        .where((entry) => entry.key > lastExportedId)
        .toList();

    if (newActions.isEmpty) {
      return ServiceResult(
          success: true,
          message:
              'No new data to export. Already up to date (last ID: $lastExportedId).');
    }

    final lowestNewId = newActions.first.key;
    final highestNewId = newActions.last.key;

    log(
      'Previous export found up to ID: $lastExportedId. '
      'Exporting new items from ID $lowestNewId to $highestNewId.',
    );

    // --- DYNAMIC CSV GENERATION ---

    // 1. Find all unique answer keys to create dynamic columns
    final answerKeys = <String>{};
    for (final entry in newActions) {
      if (entry.value.answers != null) {
        answerKeys.addAll(entry.value.answers!.keys);
      }
    }
    final sortedAnswerKeys = answerKeys.toList()..sort();

    // 2. Prepare CSV content with a dynamic header
    // Use the highest *new* ID for the filename
    final timestamp = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
    final fileName = 'tracky_export_prefix_${highestNewId}_$timestamp.csv';

    final csvBuffer = StringBuffer()
      // CSV Header
      ..write('id,actionType,timestamp');
    if (sortedAnswerKeys.isNotEmpty) {
      csvBuffer.write(',${sortedAnswerKeys.join(',')}');
    }
    csvBuffer.writeln(); // End of header line

    // 3. CSV Rows
    for (final entry in newActions) {
      final action = entry.value;
      // Convert timestamp back to ISO string for the export file
      final timestampString =
          DateTime.fromMillisecondsSinceEpoch(action.timestamp)
              .toIso8601String();
      final row = [
        entry.key,
        action.actionType.name, // Use .name for the enum
        '"$timestampString"', // Quote the timestamp string
      ];

      // Add values for each dynamic answer column
      for (final key in sortedAnswerKeys) {
        // Append the answer if it exists, otherwise append an empty string
        row.add(action.answers?[key]?.toString() ?? '');
      }
      csvBuffer.writeln(row.join(','));
    }

    // 4. Write file
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    try {
      await file.writeAsString(csvBuffer.toString());
      log('Export successful to ${file.path}');
      return ServiceResult(
          success: true,
          message:
              'Exported ${newActions.length} items (IDs $lowestNewId-$highestNewId) to $fileName');
    } on Exception catch (e) {
      log('Error writing file: $e');
      return ServiceResult(
          success: false, message: 'Failed to write export file.');
    }
  }
}
