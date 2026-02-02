import 'package:flutter/material.dart';

/// Feature-specific color tokens for consistent theming
class FeatureTokens {
  FeatureTokens._();

  // Class colors - distinct hues for each class
  static const Map<String, Color> _classColors = {
    'censor': Color(0xFFFFB300),      // Golden yellow - divine
    'conduit': Color(0xFF7B1FA2),     // Deep purple - mystical
    'elementalist': Color(0xFFFF5722), // Red-orange - elemental fire
    'fury': Color(0xFFB71C1C),        // Dark red - rage/fury
    'null': Color(0xFF546E7A),        // Blue-grey - void/neutral
    'shadow': Color(0xFF424242),      // Dark grey - stealth
    'tactician': Color(0xFF1565C0),   // Royal blue - strategy
    'talent': Color(0xFF2E7D32),      // Green - natural talent
    'troubadour': Color(0xFFE91E63),  // Pink - performance/charisma
  };

  // Level tier colors - progression indication
  static const Color levelLow = Color(0xFF4CAF50);     // Green - early levels
  static const Color levelMid = Color(0xFFFF9800);     // Orange - mid levels  
  static const Color levelHigh = Color(0xFFE53935);    // Red - high levels
  static const Color levelMax = Color(0xFF9C27B0);     // Purple - max levels

  // Feature type colors
  static const Color subclassFeature = Color(0xFF673AB7); // Deep purple
  static const Color coreFeature = Color(0xFF1976D2);     // Blue

  /// Get color for a specific class
  static Color getClassColor(String className) {
    return _classColors[className.toLowerCase()] ?? const Color(0xFF607D8B);
  }

  /// Get light variant of class color for backgrounds
  static Color getClassColorLight(String className) {
    final color = getClassColor(className);
    return color.withValues(alpha: 0.15);
  }

  /// Get color based on feature level
  static Color getLevelColor(int level) {
    if (level <= 3) return levelLow;
    if (level <= 6) return levelMid;
    if (level <= 9) return levelHigh;
    return levelMax;
  }

  /// Get light variant of level color
  static Color getLevelColorLight(int level) {
    return getLevelColor(level).withValues(alpha: 0.2);
  }

  /// Get color for feature type (subclass vs core)
  static Color getFeatureTypeColor(bool isSubclassFeature) {
    return isSubclassFeature ? subclassFeature : coreFeature;
  }

  /// Get light variant for feature type
  static Color getFeatureTypeColorLight(bool isSubclassFeature) {
    return getFeatureTypeColor(isSubclassFeature).withValues(alpha: 0.15);
  }
}