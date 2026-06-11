import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class ReleaseInfo {
  final String tagName;
  final String downloadUrl;
  final String body;

  ReleaseInfo({
    required this.tagName,
    required this.downloadUrl,
    required this.body,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] as List;
    final apkAsset = assets.firstWhere(
      (asset) => (asset['name'] as String).endsWith('.apk'),
      orElse: () => throw Exception('No APK found in release'),
    );

    return ReleaseInfo(
      tagName: json['tag_name'],
      downloadUrl: apkAsset['browser_download_url'],
      body: json['body'] ?? '',
    );
  }
}

class UpdateService extends ChangeNotifier {
  static const String _owner = 'Temiyoko';
  static const String _repo = 'ClassroomTracker';
  static const String _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  ReleaseInfo? _latestRelease;
  bool _isChecking = false;
  double _downloadProgress = 0;
  String? _error;
  bool _isDownloading = false;
  String _currentVersion = '...';

  ReleaseInfo? get latestRelease => _latestRelease;
  bool get isChecking => _isChecking;
  double get downloadProgress => _downloadProgress;
  String? get error => _error;
  bool get isDownloading => _isDownloading;
  String get currentVersion => _currentVersion;

  UpdateService() {
    _init();
  }

  Future<void> _init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    notifyListeners();
  }

  Future<bool> checkForUpdate() async {
    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestRelease = ReleaseInfo.fromJson(data);
        
        final packageInfo = await PackageInfo.fromPlatform();
        final fullCurrentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
        
        final hasUpdate = _isNewerVersion(fullCurrentVersion, _latestRelease!.tagName);
        _isChecking = false;
        notifyListeners();
        return hasUpdate;
      } else {
        _error = 'Failed to fetch releases: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error checking for updates: $e';
    }

    _isChecking = false;
    notifyListeners();
    return false;
  }

  bool _isNewerVersion(String current, String latest) {
    // Clean tag name (remove 'v' prefix if present)
    final cleanLatest = latest.startsWith('v') ? latest.substring(1) : latest;
    
    final latestParts = cleanLatest.split('+');
    final currentParts = current.split('+');
    
    final latestVersion = latestParts[0];
    final currentVersion = currentParts[0];

    // Simple semantic version comparison
    final v1 = latestVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final v2 = currentVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (var i = 0; i < math.max(v1.length, v2.length); i++) {
      final part1 = i < v1.length ? v1[i] : 0;
      final part2 = i < v2.length ? v2[i] : 0;
      if (part1 > part2) return true;
      if (part1 < part2) return false;
    }
    
    // If versions are equal, compare build numbers
    final b1 = latestParts.length > 1 ? (int.tryParse(latestParts[1]) ?? 0) : 0;
    final b2 = currentParts.length > 1 ? (int.tryParse(currentParts[1]) ?? 0) : 0;
    
    return b1 > b2;
  }

  void downloadAndInstall() {
    if (_latestRelease == null || !Platform.isAndroid || _isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0;
    _error = null;
    notifyListeners();

    try {
      OtaUpdate().execute(
        _latestRelease!.downloadUrl,
        destinationFilename: 'classroom_tracker_update.apk',
      ).listen(
        (OtaEvent event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              _downloadProgress = double.tryParse(event.value ?? '0') ?? 0;
              notifyListeners();
              break;
            case OtaStatus.INSTALLING:
              _isDownloading = false;
              notifyListeners();
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              _error = 'Update already in progress';
              _isDownloading = false;
              notifyListeners();
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              _error = 'Permission not granted to install APK';
              _isDownloading = false;
              notifyListeners();
              break;
            case OtaStatus.DOWNLOAD_ERROR:
              _error = 'Download failed';
              _isDownloading = false;
              notifyListeners();
              break;
            default:
              _isDownloading = false;
              notifyListeners();
              break;
          }
        },
        onError: (e) {
          _error = 'Update error: $e';
          _isDownloading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to start update: $e';
      _isDownloading = false;
      notifyListeners();
    }
  }
}
