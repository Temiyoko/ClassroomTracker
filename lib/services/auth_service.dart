import 'package:flutter/material.dart';

/// Placeholder auth — no real backend yet.
/// Will be replaced by school SSO later.
class AuthService with ChangeNotifier {
  bool _isAuthenticated = true; // App starts logged in
  String? _userName;
  String? _schoolOrg = "ESIEE Paris";

  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get schoolOrg => _schoolOrg;

  /// Always succeeds. Derives a display name from the 'name.surname' identifier.
  Future<String?> login(String identifier, String password) async {
    final trimmed = identifier.trim();
    
    if (trimmed.isEmpty) {
      _userName = null;
    } else {
      // Extract the name part (before the first dot)
      final namePart = trimmed.contains('.') ? trimmed.split('.').first : trimmed;
      _userName = namePart.isNotEmpty
          ? namePart[0].toUpperCase() + namePart.substring(1).toLowerCase()
          : null;
    }
    
    _schoolOrg = "ESIEE Paris";
    _isAuthenticated = true;
    notifyListeners();
    return null; // no error
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userName = null;
    _schoolOrg = null;
    notifyListeners();
  }
}
