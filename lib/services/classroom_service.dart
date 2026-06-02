import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/classroom.dart';

class ClassroomService with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    _listenToClassrooms();
  }

  void _listenToClassrooms() {
    _sub = _db.collection('classroom').snapshots().listen(
      (snapshot) {
        _classrooms = snapshot.docs
            .map((doc) => Classroom.fromFirestore(
                  doc.data(),
                  doc.id,
                ))
            .toList();
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

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
