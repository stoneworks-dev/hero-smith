import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/navigation_theme.dart';
import '../../core/services/update_provider.dart';
import '../../core/services/update_service.dart';
import '../../widgets/update_dialog.dart';

/// About page with legal notices and attribution as required by
/// the Draw Steel Creator License.
class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  static const String _appName = 'Hero Smith';
  static const String _copyright = '© 2026 stoneworks-dev';
  static const String _sourceUrl = 'https://github.com/stoneworks-dev/hero-smith';
  static const String _issuesUrl = 'https://github.com/stoneworks-dev/hero-smith/issues';
  static const String _supportEmail = 'support@stoneworks-software.com';

  String _version = '';
  bool _checkingForUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = info.version);
    }
  }

  Future<void> _manualCheckForUpdate() async {
    setState(() => _checkingForUpdate = true);
    try {
      final service = ref.read(updateServiceProvider);
      final update = await service.checkForUpdate();
      if (!mounted) return;

      if (update != null) {
        showUpdateDialog(context, ref, update);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are on the latest version!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check for updates: $e')),
      );
    } finally {
      if (mounted) setState(() => _checkingForUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = NavigationTheme.heroesColor;

    return Scaffold(
      backgroundColor: NavigationTheme.navBarBackground,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: NavigationTheme.cardBackgroundDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App header
            _buildAppHeader(accent),
            const SizedBox(height: 24),

            // Legal Notice
            _buildSection(
              title: 'Legal Notice',
              accent: accent,
              child: const Text(
                '$_appName is an independent product published under the '
                'DRAW STEEL Creator License and is not affiliated with '
                'MCDM Productions, LLC.\n\n'
                'DRAW STEEL © 2024 MCDM Productions, LLC.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // Support
            _buildSection(
              title: 'Support',
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To suggest a new feature, improvement, or to report a bug:',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrlOrCopy(context, Uri.parse(_issuesUrl)),
                    onLongPress: () => _copyToClipboard(context, _issuesUrl),
                    child: Text(
                      _issuesUrl,
                      style: TextStyle(
                        fontSize: 15,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrlOrCopy(
                      context,
                      Uri(scheme: 'mailto', path: _supportEmail),
                      fallbackCopyText: _supportEmail,
                    ),
                    onLongPress: () => _copyToClipboard(context, _supportEmail),
                    child: Text(
                      _supportEmail,
                      style: TextStyle(
                        fontSize: 15,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Updates section
            _buildSection(
              title: 'Updates',
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUpdatePromptToggle(accent),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _checkingForUpdate ? null : _manualCheckForUpdate,
                      icon: _checkingForUpdate
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accent,
                              ),
                            )
                          : Icon(Icons.refresh, color: accent),
                      label: Text(
                        _checkingForUpdate ? 'Checking...' : 'Check for Updates',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Source code link
            _buildSection(
              title: 'Source Code',
              accent: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'If you wish to contribute or help:',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrlOrCopy(context, Uri.parse(_sourceUrl)),
                    onLongPress: () => _copyToClipboard(context, _sourceUrl),
                    child: Text(
                      _sourceUrl,
                      style: TextStyle(
                        fontSize: 15,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy
            _buildSection(
              title: 'Privacy',
              accent: accent,
              child: const Text(
                'Hero Smith does not collect any personal data. '
                'All hero data is stored locally on your device.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // License
            _buildSection(
              title: 'License',
              accent: accent,
              child: const Text(
                'Open-source software licensed under the Apache License 2.0.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // View full licenses
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _showLicensePage(context),
                icon: const Icon(Icons.description_outlined),
                label: const Text('View Open Source Licenses'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NavigationTheme.cardBorderRadius),
        color: NavigationTheme.cardBackgroundDark,
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: NavigationTheme.cardIconDecoration(accent),
            child: Icon(Icons.shield, color: accent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _copyright,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version $_version',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: NavigationTheme.cardBackgroundDark,
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildUpdatePromptToggle(Color accent) {
    final showPromptsAsync = ref.watch(updatePreferencesProvider);
    final showPrompts = showPromptsAsync.valueOrNull ?? true;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Show update prompts on startup',
            style: TextStyle(
              fontSize: 14,
              color: showPrompts ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
        Switch(
          value: showPrompts,
          activeColor: const Color(0xFF2E7D32),
          activeTrackColor: const Color(0xFF66BB6A),
          onChanged: (v) {
            ref
                .read(updatePreferencesProvider.notifier)
                .setShowPrompts(v);
          },
        ),
      ],
    );
  }

  Future<void> _launchUrlOrCopy(
    BuildContext context,
    Uri uri, {
    String? fallbackCopyText,
  }) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await _copyToClipboard(context, fallbackCopyText ?? uri.toString());
      }
    } catch (_) {
      await _copyToClipboard(context, fallbackCopyText ?? uri.toString());
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: _appName,
      applicationVersion: _version,
      applicationLegalese: '$_copyright\n\n'
          '$_appName is an independent product published under the '
          'DRAW STEEL Creator License and is not affiliated with '
          'MCDM Productions, LLC.\n\n'
          'DRAW STEEL © 2024 MCDM Productions, LLC.\n\n'
          'Support: $_supportEmail',
    );
  }
}
