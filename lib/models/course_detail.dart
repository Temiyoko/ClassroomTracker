class CourseDetail {
  final String name;
  final String professor;
  final DateTime start;
  final DateTime end;

  CourseDetail({
    required this.name,
    required this.professor,
    required this.start,
    required this.end,
  });

  String get timeRange => 
    "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - "
    "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
}
