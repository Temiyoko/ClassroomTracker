import 'dart:convert';
import 'dart:io';
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
        final currentVersion = packageInfo.version;
        
        final hasUpdate = _isNewerVersion(currentVersion, _latestRelease!.tagName);
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
    
    // Split by '+' for build number if present
    final latestParts = cleanLatest.split('+');
    final currentParts = current.split('+');
    
    final latestVersion = latestParts[0];
    final currentVersion = currentParts[0];

    // Simple semantic version comparison
    final v1 = latestVersion.split('.').map(int.parse).toList();
    final v2 = currentVersion.split('.').map(int.parse).toList();

    for (var i = 0; i < v1.length && i < v2.length; i++) {
      if (v1[i] > v2[i]) return true;
      if (v1[i] < v2[i]) return false;
    }
    
    if (v1.length > v2.length) return true;

    // If versions are equal, compare build numbers if both exist
    if (latestParts.length > 1 && currentParts.length > 1) {
      final b1 = int.tryParse(latestParts[1]) ?? 0;
      final b2 = int.tryParse(currentParts[1]) ?? 0;
      return b1 > b2;
    }

    return false;
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
