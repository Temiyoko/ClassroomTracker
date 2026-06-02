import 'package:flutter/material.dart';

/// Placeholder auth — no real backend yet.
/// Will be replaced by school SSO later.
class AuthService with ChangeNotifier {
  String? _userName;
  String? _schoolOrg;

  bool get isAuthenticated => _userName != null;
  String? get userName => _userName;
  String? get schoolOrg => _schoolOrg;

  /// Always succeeds. Derives a display name from the 'name.surname' identifier.
  Future<String?> login(String identifier, String password) async {
    final trimmed = identifier.trim();
    // Extract the name part (before the first dot)
    final namePart = trimmed.contains('.') ? trimmed.split('.').first : trimmed;
    
    _userName = namePart.isNotEmpty
        ? namePart[0].toUpperCase() + namePart.substring(1).toLowerCase()
        : null;
    
    _schoolOrg = "ESIEE Paris";
    notifyListeners();
    return null; // no error
  }

  Future<void> logout() async {
    _userName = null;
    _schoolOrg = null;
    notifyListeners();
  }
}
