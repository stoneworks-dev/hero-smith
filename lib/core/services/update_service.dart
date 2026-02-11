import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service that checks GitHub Releases for platform-specific app updates.
///
/// Release tags follow the format: `<platform>-<semver>`, e.g.:
///   - `win-1.0.1`
///   - `andr-1.0.1`
///   - `ios-1.0.1`
///   - `mac-1.0.1`
///   - `linux-1.0.1`
///   - `web-1.0.1`
///
/// Each release should attach the corresponding build artifact (.exe, .apk, etc.).
class UpdateService {
  static const String _owner = 'stoneworks-dev';
  static const String _repo = 'hero-smith';

  static const String _releasesUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases';

  /// Platform tag prefixes used in GitHub release tags.
  static const Map<TargetPlatform, String> _platformPrefixes = {
    TargetPlatform.windows: 'win',
    TargetPlatform.android: 'andr',
    TargetPlatform.iOS: 'ios',
    TargetPlatform.macOS: 'mac',
    TargetPlatform.linux: 'linux',
  };

  /// File extension patterns per platform for matching release assets.
  static const Map<TargetPlatform, List<String>> _assetPatterns = {
    TargetPlatform.windows: ['.exe', '.msix', '.zip'],
    TargetPlatform.android: ['.apk'],
    TargetPlatform.iOS: ['.ipa'],
    TargetPlatform.macOS: ['.dmg', '.app.zip'],
    TargetPlatform.linux: ['.AppImage', '.tar.gz', '.deb'],
  };

  /// Checks GitHub for a newer release matching the current platform.
  ///
  /// Returns [UpdateInfo] if a newer version is found, `null` otherwise.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g., "1.0.0"
      final platform = defaultTargetPlatform;
      final prefix = _platformPrefixes[platform];

      if (prefix == null) {
        if (kDebugMode) debugPrint('Update check: unsupported platform $platform');
        return null;
      }

      final response = await http
          .get(
            Uri.parse(_releasesUrl),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (kDebugMode) debugPrint('Update check: GitHub API returned ${response.statusCode}');
        return null;
      }

      final releases = jsonDecode(response.body) as List<dynamic>;

      // Find the latest release whose tag starts with our platform prefix.
      for (final release in releases) {
        final tagName = release['tag_name'] as String? ?? '';
        final isDraft = release['draft'] as bool? ?? false;

        // Skip drafts only. Pre-releases are included since the app
        // is still in early development (0.x.x versioning).
        if (isDraft) continue;

        // Match tag like "win-1.0.1" or "andr-1.2.0".
        if (!tagName.startsWith('$prefix-')) continue;

        final releaseVersion = tagName.substring(prefix.length + 1);

        if (isNewerVersion(releaseVersion, currentVersion)) {
          final assets = release['assets'] as List<dynamic>? ?? [];
          final downloadUrl = _findAssetUrl(assets, platform);

          return UpdateInfo(
            version: releaseVersion,
            downloadUrl: downloadUrl,
            releaseNotes: release['body'] as String?,
            htmlUrl: release['html_url'] as String?,
          );
        }

        // The first matching (non-draft/prerelease) release for this platform
        // is the latest. If it's not newer, no update available.
        break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Update check failed: $e');
    }
    return null;
  }

  /// Finds the download URL for a platform-appropriate asset.
  String? _findAssetUrl(List<dynamic> assets, TargetPlatform platform) {
    final patterns = _assetPatterns[platform] ?? [];

    for (final pattern in patterns) {
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith(pattern.toLowerCase())) {
          return asset['browser_download_url'] as String?;
        }
      }
    }

    // Fallback: if only one asset, use it.
    if (assets.length == 1) {
      return assets[0]['browser_download_url'] as String?;
    }

    return null;
  }

  /// Compares two semantic version strings.
  ///
  /// Returns `true` if [latest] is strictly newer than [current].
  @visibleForTesting
  static bool isNewerVersion(String latest, String current) {
    final latestParts =
        latest.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final currentParts =
        current.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    // Pad to same length.
    while (latestParts.length < 3) {
      latestParts.add(0);
    }
    while (currentParts.length < 3) {
      currentParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  /// Opens the browser to download the update.
  Future<bool> downloadUpdate(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens the GitHub releases page as a fallback.
  Future<bool> openReleasesPage({String? htmlUrl}) async {
    final url = htmlUrl ?? 'https://github.com/$_owner/$_repo/releases';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

/// Information about an available update.
class UpdateInfo {
  final String version;
  final String? downloadUrl;
  final String? releaseNotes;
  final String? htmlUrl;

  const UpdateInfo({
    required this.version,
    this.downloadUrl,
    this.releaseNotes,
    this.htmlUrl,
  });
}
