enum RoomType { classroom, laboratory, amphitheater }

class Classroom {
  final String id;
  final String name;
  final int floor;
  final int corridor;
  final RoomType type;
  final int currentPeople;
  final bool hasCourse;
  bool isFavorite;

  Classroom({
    required this.id,
    required this.name,
    required this.floor,
    required this.corridor,
    required this.type,
    this.currentPeople = 0,
    this.hasCourse = false,
    this.isFavorite = false,
  });

  String get typeLabel {
    switch (type) {
      case RoomType.classroom:
        return 'Salle de classe';
      case RoomType.laboratory:
        return 'Laboratoire';
      case RoomType.amphitheater:
        return 'Amphithéâtre';
    }
  }

  factory Classroom.fromFirestore(Map<String, dynamic> data, String id) {
    return Classroom(
      id: id,
      name: id, // document ID is the room name/number
      floor: (data['floor'] as num?)?.toInt() ?? 0,
      corridor: (data['corridor'] as num?)?.toInt() ?? 0,
      type: _parseRoomType(data['type']),
      currentPeople: (data['currentPeople'] as num?)?.toInt() ?? 0,
      hasCourse: data['hasCourse'] ?? false,
    );
  }

  static RoomType _parseRoomType(String? type) {
    switch (type) {
      case 'laboratory':
      case 'lab':
        return RoomType.laboratory;
      case 'amphitheater':
      case 'amphi':
        return RoomType.amphitheater;
      case 'classroom':
      case 'salle':
      default:
        return RoomType.classroom;
    }
  }
}
