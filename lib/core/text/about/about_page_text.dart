class AboutPageText {
  AboutPageText._();

  // App header
  static const String appName = 'Hero Smith';
  static const String copyright = '© 2026 stoneworks-dev';
  static const String sourceUrl = 'https://github.com/stoneworks-dev/hero-smith';
  static const String issuesUrl = 'https://github.com/stoneworks-dev/hero-smith/issues';
  static const String supportEmail = 'support@stoneworks-software.com';

  // App bar & header
  static const String aboutTitle = 'About';
  static String versionLabel(String version) => 'Version $version';

  // Section titles
  static const String legalNotice = 'Legal Notice';
  static const String support = 'Support';
  static const String updates = 'Updates';
  static const String sourceCode = 'Source Code';
  static const String privacy = 'Privacy';
  static const String license = 'License';

  // Legal notice body
  static const String legalNoticeBody =
      '$appName is an independent product published under the '
      'DRAW STEEL Creator License and is not affiliated with '
      'MCDM Productions, LLC.\n\n'
      'DRAW STEEL © 2024 MCDM Productions, LLC.';

  // Support
  static const String supportBody =
      'To suggest a new feature, improvement, or to report a bug:';

  // Updates
  static const String showUpdatePrompts = 'Show update prompts on startup';
  static const String checking = 'Checking...';
  static const String checkForUpdates = 'Check for Updates';
  static const String latestVersion = 'You are on the latest version!';
  static String updateCheckError(Object e) =>
      'Could not check for updates: $e';

  // Source code
  static const String contributeBody = 'If you wish to contribute or help:';

  // Privacy
  static const String privacyBody =
      'Hero Smith does not collect any personal data. '
      'All hero data is stored locally on your device.';

  // License
  static const String licenseBody =
      'Open-source software licensed under the Apache License 2.0.';

  // Icon attribution
  static const String iconAttribution = 'Icon Attribution';
  static const String iconAttributionBody =
      'Game icons by Lorc, Delapouite, sbed, and Zeromancer from '
      'game-icons.net, licensed under CC BY 3.0 '
      '(creativecommons.org/licenses/by/3.0/).';

  // Actions
  static const String viewOpenSourceLicenses = 'View Open Source Licenses';
  static const String copiedToClipboard = 'Copied to clipboard';

  // License page legalese
  static String licenseLegalese(String version) =>
      '$copyright\n\n'
      '$appName is an independent product published under the '
      'DRAW STEEL Creator License and is not affiliated with '
      'MCDM Productions, LLC.\n\n'
      'DRAW STEEL © 2024 MCDM Productions, LLC.\n\n'
      '$iconAttributionBody\n\n'
      'Support: $supportEmail';
}
