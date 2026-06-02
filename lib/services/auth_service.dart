import 'package:flutter/material.dart';

/// Placeholder auth — no real backend yet.
/// Will be replaced by school SSO later.
class AuthService with ChangeNotifier {
  String? _userName;
  String? _schoolOrg;

  bool get isAuthenticated => _userName != null;
  String? get userName => _userName;
  String? get schoolOrg => _schoolOrg;

  /// Always succeeds. Derives a display name from the email address.
  Future<String?> login(String email, String password) async {
    final trimmed = email.trim();
    // Extract the local part of the email (before @), capitalise first letter
    final local = trimmed.contains('@') ? trimmed.split('@').first : trimmed;
    _userName =
        local.isNotEmpty ? local[0].toUpperCase() + local.substring(1) : null;
    _schoolOrg = trimmed.contains('@') ? trimmed.split('@').last : null;
    notifyListeners();
    return null; // no error
  }

  Future<void> logout() async {
    _userName = null;
    _schoolOrg = null;
    notifyListeners();
  }
}
