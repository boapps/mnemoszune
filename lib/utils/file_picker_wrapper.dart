import 'dart:io';
import 'package:file_selector/file_selector.dart';

/// A wrapper around file_selector to handle platform-specific issues
class FilePickerWrapper {
  /// Pick a single file with optional allowed extensions
  /// Returns the path to the selected file, or null if canceled
  static Future<String?> pickSingleFile({
    List<String>? allowedExtensions,
  }) async {
    try {
      XTypeGroup typeGroup;
      if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        typeGroup = XTypeGroup(label: 'Files', extensions: allowedExtensions);
        final file = await openFile(acceptedTypeGroups: [typeGroup]);
        return file?.path;
      } else {
        final file = await openFile();
        return file?.path;
      }
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Pick multiple files with optional allowed extensions
  /// Returns the paths to the selected files, or empty list if canceled
  static Future<List<String>> pickMultipleFiles({
    List<String>? allowedExtensions,
  }) async {
    try {
      List<XTypeGroup> typeGroups = [];
      if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        typeGroups = [
          XTypeGroup(label: 'Files', extensions: allowedExtensions),
        ];
      }

      final files = await openFiles(
        acceptedTypeGroups: typeGroups.isEmpty ? null : typeGroups,
      );

      return files.map((file) => file.path).toList();
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }

  /// Pick a directory
  /// Returns the path to the selected directory, or null if canceled
  static Future<String?> pickDirectory() async {
    try {
      final directory = await getDirectoryPath();
      return directory;
    } catch (e) {
      print('Error picking directory: $e');
      return null;
    }
  }
}
