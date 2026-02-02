import 'package:flutter/material.dart';
import 'app_text_styles.dart';

class DsTheme extends ThemeExtension<DsTheme> {
  // Border color maps
  final Map<String, Color> languageTypeBorder;
  final Map<String, Color> skillGroupBorder;
  final Map<String, Color> deityCategoryBorder;
  final Map<int, Color> titleEchelonBorder;
  final Map<String, Color> perkGroupBorder;
  final Color complicationBorder;
  final Map<String, Color> cultureTypeBorder;
  final Color careerBorder;
  final Color ancestryBorder;

  // Emojis
  final Map<String, String> languageTypeEmoji;
  final Map<String, String> languageSectionEmoji;
  final Map<String, String> skillGroupEmoji;
  final Map<String, String> skillSectionEmoji;
  final Map<String, String> titleSectionEmoji;
  final Map<String, String> deityCategoryEmoji;
  final Map<String, String> deitySectionEmoji;
  final Map<String, String> perkGroupEmoji;
  final Map<String, String> perkSectionEmoji;
  final Map<String, String> complicationSectionEmoji;
  final Map<String, String> cultureTypeEmoji;
  final Map<String, String> cultureSectionEmoji;
  final Map<String, String> careerSectionEmoji;
  final Map<String, String> ancestrySectionEmoji;

  // Special colors
  final Color specialSectionColor;

  // Text styles
  final TextStyle cardTitleStyle;
  final TextStyle sectionLabelStyle;
  final TextStyle badgeTextStyle;

  const DsTheme({
    required this.languageTypeBorder,
    required this.skillGroupBorder,
    required this.deityCategoryBorder,
    required this.titleEchelonBorder,
    required this.perkGroupBorder,
    required this.complicationBorder,
    required this.cultureTypeBorder,
    required this.careerBorder,
    required this.ancestryBorder,
    required this.languageTypeEmoji,
    required this.languageSectionEmoji,
    required this.skillGroupEmoji,
    required this.skillSectionEmoji,
    required this.titleSectionEmoji,
    required this.deityCategoryEmoji,
    required this.deitySectionEmoji,
    required this.perkGroupEmoji,
    required this.perkSectionEmoji,
    required this.complicationSectionEmoji,
    required this.cultureTypeEmoji,
    required this.cultureSectionEmoji,
    required this.careerSectionEmoji,
    required this.ancestrySectionEmoji,
    required this.specialSectionColor,
    required this.cardTitleStyle,
    required this.sectionLabelStyle,
    required this.badgeTextStyle,
  });

  factory DsTheme.defaults(ColorScheme scheme) {
    return DsTheme(
      languageTypeBorder: {
        'human': Colors.blue.shade300,
        'ancestral': Colors.green.shade300,
        'dead': Colors.grey.shade400,
        'unknown': Colors.grey.shade300,
      },
      skillGroupBorder: {
        'crafting': Colors.orangeAccent.shade200,
        'exploration': Colors.blue.shade300,
        'interpersonal': Colors.pink.shade300,
        'intrigue': Colors.teal.shade300,
        'lore': Colors.indigo.shade300,
        'other': Colors.grey.shade300,
      },
      deityCategoryBorder: {
        'god': Colors.amber.shade300,
        'saint': Colors.lightBlue.shade300,
        'other': Colors.grey.shade400,
      },
      titleEchelonBorder: {
        1: Colors.green.shade300,
        2: Colors.blue.shade300,
        3: Colors.purple.shade300,
        4: Colors.orange.shade300,
        0: Colors.grey.shade300, // fallback for unknown echelon
      },
      perkGroupBorder: {
        'exploration': Colors.blue.shade300,
        'interpersonal': Colors.pink.shade300,
        'intrigue': Colors.teal.shade300,
        'lore': Colors.indigo.shade300,
        'supernatural': Colors.purple.shade300,
      },
      complicationBorder: const Color(0xFFB71C1C), // Deep crimson red for dark theme
      cultureTypeBorder: {
        'culture_environment': Colors.green.shade300,
        'culture_organisation': Colors.blue.shade300,
        'culture_upbringing': Colors.purple.shade300,
      },
      careerBorder: Colors.cyan.shade300,
      languageTypeEmoji: {
        'human': '🗣️',
        'ancestral': '📜',
        'dead': '☠️',
        'unknown': '💬',
      },
      languageSectionEmoji: {
        'region': '🗺️',
        'ancestry': '🧬',
        'related': '🔗',
        'topics': '🧩',
      },
      skillGroupEmoji: {
        'crafting': '⚒️',
        'exploration': '🧭',
        'interpersonal': '🤝',
        'intrigue': '🕵️',
        'lore': '📚',
        'other': '🧩',
      },
      skillSectionEmoji: {
        'group': '📂',
        'description': '📝',
      },
      titleSectionEmoji: {
        'prerequisite': '🗝️',
        'description': '📝',
        'benefits': '🎁',
        'special': '✨',
      },
      deityCategoryEmoji: {
        'god': '🕊️',
        'saint': '✨',
        'other': '🔰',
      },
      deitySectionEmoji: {
        'domains': '🧭',
      },
      perkGroupEmoji: {
        'exploration': '🧭',
        'interpersonal': '🤝',
        'intrigue': '🕵️',
        'lore': '📚',
        'supernatural': '✨',
      },
      perkSectionEmoji: {
        'description': '📝',
        'grants': '🎁',
      },
      complicationSectionEmoji: {
        'description': '📝',
        'effects': '⚔️',
        'grants': '🎁',
      },
      cultureTypeEmoji: {
        'culture_environment': '🏞️',
        'culture_organisation': '🏛️',
        'culture_upbringing': '👨‍👩‍👧‍👦',
      },
      cultureSectionEmoji: {
        'description': '📝',
        'skillGroups': '📚',
        'specificSkills': '🎯',
      },
      careerSectionEmoji: {
        'description': '📝',
        'skills': '🛠️',
        'resources': '💰',
        'perks': '🎁',
        'incitingIncidents': '⚡',
      },
      ancestryBorder: Colors.purple.shade400,
      ancestrySectionEmoji: {
        'description': '📝',
        'exampleNames': '👤',
        'stats': '📊',
        'signature': '🌟',
        'traits': '🧬',
      },
      specialSectionColor: Colors.amber.shade300,
      cardTitleStyle: AppTextStyles.title.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: scheme.onSurface.withOpacity(0.95),
      ),
      sectionLabelStyle: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: scheme.onSurface.withOpacity(0.85),
      ),
      badgeTextStyle: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        color: scheme.onSurface.withOpacity(0.85),
      ),
    );
  }

  static DsTheme of(BuildContext context) {
    final ext = Theme.of(context).extension<DsTheme>();
    return ext ?? DsTheme.defaults(Theme.of(context).colorScheme);
  }

  @override
  DsTheme copyWith({
    Map<String, Color>? languageTypeBorder,
    Map<String, Color>? skillGroupBorder,
    Map<String, Color>? deityCategoryBorder,
    Map<int, Color>? titleEchelonBorder,
    Map<String, Color>? perkGroupBorder,
    Color? complicationBorder,
    Map<String, Color>? cultureTypeBorder,
    Color? careerBorder,
    Color? ancestryBorder,
    Map<String, String>? languageTypeEmoji,
    Map<String, String>? languageSectionEmoji,
    Map<String, String>? skillGroupEmoji,
    Map<String, String>? skillSectionEmoji,
    Map<String, String>? titleSectionEmoji,
    Map<String, String>? deityCategoryEmoji,
    Map<String, String>? deitySectionEmoji,
    Map<String, String>? perkGroupEmoji,
    Map<String, String>? perkSectionEmoji,
    Map<String, String>? complicationSectionEmoji,
    Map<String, String>? cultureTypeEmoji,
    Map<String, String>? cultureSectionEmoji,
    Map<String, String>? careerSectionEmoji,
    Map<String, String>? ancestrySectionEmoji,
    Color? specialSectionColor,
    TextStyle? cardTitleStyle,
    TextStyle? sectionLabelStyle,
    TextStyle? badgeTextStyle,
  }) {
    return DsTheme(
      languageTypeBorder: languageTypeBorder ?? this.languageTypeBorder,
      skillGroupBorder: skillGroupBorder ?? this.skillGroupBorder,
      deityCategoryBorder: deityCategoryBorder ?? this.deityCategoryBorder,
      titleEchelonBorder: titleEchelonBorder ?? this.titleEchelonBorder,
      perkGroupBorder: perkGroupBorder ?? this.perkGroupBorder,
      complicationBorder: complicationBorder ?? this.complicationBorder,
      cultureTypeBorder: cultureTypeBorder ?? this.cultureTypeBorder,
      careerBorder: careerBorder ?? this.careerBorder,
      ancestryBorder: ancestryBorder ?? this.ancestryBorder,
      languageTypeEmoji: languageTypeEmoji ?? this.languageTypeEmoji,
      languageSectionEmoji: languageSectionEmoji ?? this.languageSectionEmoji,
      skillGroupEmoji: skillGroupEmoji ?? this.skillGroupEmoji,
      skillSectionEmoji: skillSectionEmoji ?? this.skillSectionEmoji,
      titleSectionEmoji: titleSectionEmoji ?? this.titleSectionEmoji,
      deityCategoryEmoji: deityCategoryEmoji ?? this.deityCategoryEmoji,
      deitySectionEmoji: deitySectionEmoji ?? this.deitySectionEmoji,
      perkGroupEmoji: perkGroupEmoji ?? this.perkGroupEmoji,
      perkSectionEmoji: perkSectionEmoji ?? this.perkSectionEmoji,
      complicationSectionEmoji: complicationSectionEmoji ?? this.complicationSectionEmoji,
      cultureTypeEmoji: cultureTypeEmoji ?? this.cultureTypeEmoji,
      cultureSectionEmoji: cultureSectionEmoji ?? this.cultureSectionEmoji,
      careerSectionEmoji: careerSectionEmoji ?? this.careerSectionEmoji,
      ancestrySectionEmoji: ancestrySectionEmoji ?? this.ancestrySectionEmoji,
      specialSectionColor: specialSectionColor ?? this.specialSectionColor,
      cardTitleStyle: cardTitleStyle ?? this.cardTitleStyle,
      sectionLabelStyle: sectionLabelStyle ?? this.sectionLabelStyle,
      badgeTextStyle: badgeTextStyle ?? this.badgeTextStyle,
    );
  }

  @override
  ThemeExtension<DsTheme> lerp(ThemeExtension<DsTheme>? other, double t) {
    // Non-animated for simplicity.
    return this;
  }
}