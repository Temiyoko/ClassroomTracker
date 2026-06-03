import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PersistenceService {
  static Future<File> _getFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName.json');
  }

  static Future<void> saveList(String key, List<String> list) async {
    final file = await _getFile(key);
    await file.writeAsString(jsonEncode(list));
  }

  static Future<List<String>> getList(String key) async {
    try {
      final file = await _getFile(key);
      if (await file.exists()) {
        final content = await file.readAsString();
        return List<String>.from(jsonDecode(content));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Persistence error for $key: $e');
      }
    }
    return [];
  }
}
