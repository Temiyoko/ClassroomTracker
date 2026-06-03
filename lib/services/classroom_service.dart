import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/classroom.dart';
import 'notification_service.dart';
import 'persistence_service.dart';

class ClassroomService with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  NotificationService? _notificationService;

  List<Classroom> _classrooms = [];
  final Set<String> _favoriteIds = {};
  StreamSubscription<QuerySnapshot>? _sub;
  bool _loading = true;
  String? _error;

  List<Classroom> get classrooms => _classrooms;
  List<Classroom> get favorites =>
      _classrooms.where((c) => _favoriteIds.contains(c.id)).toList();
  bool get loading => _loading;
  String? get error => _error;

  ClassroomService() {
    _loadFavorites();
    _listenToClassrooms();
  }

  void updateNotificationService(NotificationService service) {
    _notificationService = service;
  }

  Future<void> _loadFavorites() async {
    final favs = await PersistenceService.getList('favorite_classrooms');
    if (favs.isNotEmpty) {
      _favoriteIds.addAll(favs);
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    await PersistenceService.saveList('favorite_classrooms', _favoriteIds.toList());
  }

  void _listenToClassrooms() {
    _sub = _db.collection('classroom').snapshots().listen(
      (snapshot) {
        final newClassrooms = snapshot.docs
            .map((doc) => Classroom.fromFirestore(
                  doc.data(),
                  doc.id,
                ))
            .toList();

        _checkStatusChanges(_classrooms, newClassrooms);

        _classrooms = newClassrooms;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        _error = 'Erreur de chargement : $e';
        notifyListeners();
      },
    );
  }

  void _checkStatusChanges(List<Classroom> oldRooms, List<Classroom> newRooms) {
    if (oldRooms.isEmpty || _notificationService == null) return;

    for (var newRoom in newRooms) {
      if (_favoriteIds.contains(newRoom.id)) {
        final oldRoom = oldRooms.firstWhere((r) => r.id == newRoom.id,
            orElse: () => newRoom);

        // Transition to "Libre": currentPeople goes to 0 AND hasCourse becomes false
        bool wasBusy = oldRoom.currentPeople > 0 || oldRoom.hasCourse;
        bool isFree = newRoom.currentPeople == 0 && !newRoom.hasCourse;

        if (wasBusy && isFree) {
          _notificationService?.addNotification(
            'Salle disponible !',
            'La salle ${newRoom.name} est maintenant libre.',
          );
        }
      }
    }
  }

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
