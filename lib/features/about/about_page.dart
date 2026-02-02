import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/navigation_theme.dart';

/// About page with legal notices and attribution as required by
/// the Draw Steel Creator License.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _appName = 'Hero Smith';
  static const String _copyright = '© 2026 stoneworks-dev';
  static const String _sourceUrl = 'https://github.com/stoneworks-dev/hero-smith';
  static const String _supportEmail = 'support@stoneworks-software.com';
  static const String _version = '1.0.0';

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

            // License section
            _buildSection(
              title: 'License',
              accent: accent,
              child: const Text(
                'Open-source software licensed under the Apache License 2.0.',
                style: TextStyle(fontSize: 15, height: 1.5),
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
                    onTap: () => _launchUrl(_sourceUrl),
                    child: Text(
                      _sourceUrl,
                      style: TextStyle(
                        fontSize: 15,
                        color: accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Draw Steel Creator License notice
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

            // Support
            _buildSection(
              title: 'Support',
              accent: accent,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  const Text(
                    'To suggest a new feature, improvement, or to report a bug:',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  InkWell(
                    onTap: () => _launchEmail(_supportEmail),
                    child: Text(
                      _supportEmail,
                      style: TextStyle(
                        fontSize: 15,
                        color: accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
