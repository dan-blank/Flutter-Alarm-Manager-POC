import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_alarm_manager_poc/hive/models/alarm_action.dart';
import 'package:flutter_alarm_manager_poc/hive/service/database_service.dart';
import 'package:flutter_alarm_manager_poc/hive/service/settings_service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ExportService {
  final SettingsService _settingsService = SettingsService.instance;
  final DatabaseService _databaseService = DatabaseService.instance;

  Future<void> showSnackBar(BuildContext context, String message) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String?> _getAndSetExportPath(BuildContext context) async {
    final PermissionStatus status;
    // For Android 11 (API 30) and above, request MANAGE_EXTERNAL_STORAGE
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      // For iOS and other platforms, storage permission is generally handled by the picker.
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      await showSnackBar(
          context, 'Storage permission is required to select a path.');
      return null;
    }

    final path = await FilePicker.platform.getDirectoryPath();

    if (path != null) {
      await _settingsService.setExportPath(path);
      await showSnackBar(context, 'Export path set to: $path');
      return path;
    } else {
      await showSnackBar(context, 'Path selection cancelled.');
      return null;
    }
  }

  Future<void> changeExportPath(BuildContext context) async {
    await _getAndSetExportPath(context);
  }

  Future<void> exportData(BuildContext context) async {
    var exportPath = _settingsService.getExportPath();

    if (exportPath == null || exportPath.isEmpty) {
      exportPath = await _getAndSetExportPath(context);
      if (exportPath == null) return;
    }

    final directory = Directory(exportPath);
    if (!await directory.existsSync()) {
      await showSnackBar(
          context, 'Error: The selected directory does not exist.');
      return;
    }

    // Scan for existing files and get the biggest ID
    var lastExportedId = 0;
    try {
      final files = directory.listSync();
      for (final file in files) {
        if (file is File) {
          final filename = file.path.split(Platform.pathSeparator).last;
          if (filename.startsWith('tracky_export_prefix_')) {
            final parts = filename.split('_');
            if (parts.length > 2) {
              final id = int.tryParse(parts[2]);
              if (id != null && id > lastExportedId) {
                lastExportedId = id;
              }
            }
          }
        }
      }
    } on Exception catch (e) {
      log('Error scanning directory: $e');
      await showSnackBar(
          context, 'Error scanning directory. Please check permissions.');
      return;
    }
    log('Last exported ID found: $lastExportedId');

    // Get all data and filter for new items
    final allActions =
        _databaseService.getAllAlarmActionsMap().cast<int, AlarmAction>();
    final newActions = allActions.entries
        .where((entry) => entry.key > lastExportedId)
        .toList();

    if (newActions.isEmpty) {
      await showSnackBar(context, 'No new data to export.');
      return;
    }

    // Prepare CSV content
    final highestNewId =
        newActions.map((e) => e.key).reduce((a, b) => a > b ? a : b);
    final timestamp = DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());
    final fileName = 'tracky_export_prefix_${highestNewId}_$timestamp.csv';

    final csvBuffer = StringBuffer()
      // CSV Header
      ..writeln('id,actionType,timestamp');
    // CSV Rows
    for (final entry in newActions) {
      final action = entry.value;
      csvBuffer.writeln(
          '${entry.key},${action.actionType},"${action.timestamp.toIso8601String()}"');
    }

    // Write file
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    try {
      await file.writeAsString(csvBuffer.toString());
      log('Export successful to ${file.path}');
      await showSnackBar(context,
          'Successfully exported ${newActions.length} new items to $fileName');
    } on Exception catch (e) {
      log('Error writing file: $e');
      await showSnackBar(context, 'Failed to write export file.');
    }
  }
}
