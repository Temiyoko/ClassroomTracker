import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import '../models/course_detail.dart';

class TimetableService {
  static const String _baseUrl =
      "https://edt-consult.univ-eiffel.fr/jsp/custom/modules/plannings/anonymous_cal.jsp";

  Future<CourseDetail?> fetchCurrentCourse(String resourceId) async {
    final url = Uri.parse(_baseUrl).replace(queryParameters: {
      'resources': resourceId,
      'projectId': '1',
      'calType': 'ical',
      'nbWeeks': '4',
      'displayConfigId': '8',
    });

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final iCalendar = ICalendar.fromString(response.body);
      final now = DateTime.now();

      for (var entry in iCalendar.data) {
        if (entry['type'] == 'VEVENT') {
          // dtstart and dtend are IcsDateTime objects
          final dynamic dtStartObj = entry['dtstart'];
          final dynamic dtEndObj = entry['dtend'];

          if (dtStartObj == null || dtEndObj == null) continue;

          final DateTime? startUtc = dtStartObj.toDateTime();
          final DateTime? endUtc = dtEndObj.toDateTime();

          if (startUtc == null || endUtc == null) continue;

          // Convert UTC to local time if the ics date ends with Z
          final start = startUtc.toLocal();
          final end = endUtc.toLocal();

          if (start.isBefore(now) && end.isAfter(now)) {
            return CourseDetail(
              name: entry['summary'] ?? 'Cours sans nom',
              professor: _extractProfessor(entry['description']),
              start: start,
              end: end,
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching/parsing iCal: $e");
      }
    }
    return null;
  }

  String _extractProfessor(String? description) {
    if (description == null || description.isEmpty) {
      return 'Enseignant non spécifié';
    }

    // Split by newlines or literal \n strings (common in iCal)
    final rawLines = description.split(RegExp(r'\n|\\n'));
    final lines =
        rawLines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // Pattern 1: Look for explicit labels
    for (var line in lines) {
      if (line.toLowerCase().contains('enseignants :') ||
          line.toLowerCase().contains('enseignant :')) {
        final name = line.split(':').last.trim();
        if (name.isNotEmpty) return name;
      }
      if (line.trim().toUpperCase() == 'PERS') {
        return 'PERS';
      }
    }

    // Pattern 2: Look for line with uppercase names (Common in French ADE: DUPONT Jean)
    // Exclude lines that are known labels
    final profRegExp = RegExp(r'^[A-Z\-\s]{2,}\s[A-Z][a-z]+');
    for (var line in lines) {
      final l = line.toLowerCase();
      if (l.contains('groupes :') ||
          l.contains('salles :') ||
          l.contains('matière :') ||
          l.contains('enseignant') ||
          l.contains('(modifié le') ||
          l.contains('(exporté le') ||
          l.startsWith('ue ')) {
        continue;
      }

      if (profRegExp.hasMatch(line)) {
        return line;
      }
    }

    // Strict requirement: If no actual prof found, don't show export info or groups
    return 'Enseignant non spécifié';
  }
}
