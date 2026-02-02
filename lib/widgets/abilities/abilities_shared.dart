import 'package:flutter/material.dart';
import '../../core/models/abilities_models.dart';
import '../../core/models/component.dart';
import '../../core/models/ability_simplified.dart';
import '../../core/theme/semantic/semantic_tokens.dart';

class AbilityTierLine {
  final String label; // e.g., '<=11', '12-16', '17+'
  final String primaryText; // Main damage expression
  final String? secondaryText; // Additional notes (potencies, conditions)
  const AbilityTierLine({
    required this.label,
    required this.primaryText,
    this.secondaryText,
  });
}

/// Utility class for highlighting game mechanics in ability text
class AbilityTextHighlighter {
  // Damage types to match
  static const _damageTypes = [
    'acid',
    'poison',
    'fire',
    'cold',
    'sonic',
    'holy',
    'corruption',
    'psychic',
    'lightning',
  ];

  // Potency strength keywords
  static const _potencyStrengths = [
    'weak',
    'average',
    'strong',
    'w',
    'a',
    's',
    'WEAK',
    'AVERAGE',
    'STRONG',
    'W',
    'A',
    'S',
  ];

  /// Creates a RichText widget with highlighted characteristics, potencies, and damage types
  static Widget highlightGameMechanics(
    String text,
    BuildContext context, {
    TextStyle? baseStyle,
  }) {
    final theme = Theme.of(context);
    baseStyle ??= theme.textTheme.bodyMedium ?? const TextStyle();

    final spans = <TextSpan>[];

    // Build damage types pattern
    final damageTypesPattern = _damageTypes.join('|');

    // Build potency strengths pattern
    final potencyPattern = _potencyStrengths.join('|');

    // Comprehensive regex for game mechanics:
    // 1. Potency: M<weak, A < AVERAGE, etc. (characteristic + < + strength)
    // 2. Characteristic after +: "5 + M", "3 + A damage"
    // 3. Characteristic before <: "M < WEAK", "A < AVERAGE"
    // 4. Characteristic at start followed by < (for tier text): "^A < WEAK"
    // 5. Damage types: fire, cold, etc.
    // 6. Characteristics in comma/or lists: "M, R, I, or P"
    final regex = RegExp(
      // Group 1-2: Potency with no space: M<weak
      r'([MARIP])<(' + potencyPattern + r')\b'
      // Group 3-4: Potency with spaces: M < WEAK
      r'|([MARIP])\s*<\s*(' + potencyPattern + r')\b'
      // Group 5: Characteristic after + (with optional space): "5 + M" or "5 +M"
      r'|(?<=\+\s?)([MARIP])(?=\s|$|[,;]|\s+(?:' + damageTypesPattern + r')|(?:\s+damage))'
      // Group 6: Characteristic before damage keyword: "3 + A damage" or "A fire damage"
      r'|(?<=\+\s?)([MARIP])(?=\s+(?:' + damageTypesPattern + r')?\s*damage)'
      // Group 7: Standalone damage types
      r'|\b(' + damageTypesPattern + r')\b(?=\s+damage|\s+immunity|\))'
      // Group 8: Characteristic after comma or "or" in a list context (e.g., "M, R, I, or P")
      r'|(?<=,\s?)([MARIP])(?=\s|,|$)'
      // Group 9: Characteristic after "or " (e.g., "or P")
      r'|(?<=\bor\s)([MARIP])(?=\s|,|$)',
      caseSensitive: false,
    );

    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // Potency without space: M<weak (groups 1-2)
      final potencyCharNoSpace = match.group(1);
      final potencyStrengthNoSpace = match.group(2);

      // Potency with space: M < WEAK (groups 3-4)
      final potencyCharWithSpace = match.group(3);
      final potencyStrengthWithSpace = match.group(4);

      // Characteristic after + (groups 5-6)
      final charAfterPlus = match.group(5) ?? match.group(6);

      // Damage type (group 7)
      final damageType = match.group(7);

      // Characteristic in comma list (group 8) or after "or" (group 9)
      final charInList = match.group(8) ?? match.group(9);

      if (potencyCharNoSpace != null && potencyStrengthNoSpace != null) {
        // Potency highlighting without space (e.g., "M<weak")
        _addPotencySpans(
          spans,
          baseStyle,
          potencyCharNoSpace,
          '<$potencyStrengthNoSpace',
          potencyStrengthNoSpace,
        );
      } else if (potencyCharWithSpace != null && potencyStrengthWithSpace != null) {
        // Potency highlighting with space (e.g., "M < WEAK")
        // We need to reconstruct the matched text with its original spacing
        final matchedText = text.substring(match.start, match.end);
        final charPart = potencyCharWithSpace;
        final strengthPart = potencyStrengthWithSpace;
        
        // Find the separator (everything between char and strength)
        final charIndex = matchedText.indexOf(charPart);
        final strengthIndex = matchedText.toLowerCase().indexOf(strengthPart.toLowerCase());
        final separator = matchedText.substring(charIndex + 1, strengthIndex);

        spans.add(TextSpan(
          text: charPart,
          style: baseStyle.copyWith(
            color: CharacteristicTokens.color(charPart.toUpperCase()),
            fontWeight: FontWeight.bold,
          ),
        ));
        spans.add(TextSpan(
          text: separator,
          style: baseStyle,
        ));
        spans.add(TextSpan(
          text: strengthPart,
          style: baseStyle.copyWith(
            color: PotencyTokens.color(strengthPart.toLowerCase()),
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (charAfterPlus != null) {
        // Characteristic after + sign (damage expression context)
        spans.add(TextSpan(
          text: charAfterPlus,
          style: baseStyle.copyWith(
            color: CharacteristicTokens.color(charAfterPlus.toUpperCase()),
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (damageType != null) {
        // Damage type highlighting with emoji and color
        final normalizedType = damageType.toLowerCase();
        final emoji = DamageTokens.emoji(normalizedType);
        final color = DamageTokens.color(normalizedType);

        // Keep original case but add styling
        spans.add(TextSpan(
          text: emoji.isNotEmpty ? '$emoji $damageType' : damageType,
          style: baseStyle.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (charInList != null) {
        // Characteristic in a comma-separated list or after "or"
        spans.add(TextSpan(
          text: charInList,
          style: baseStyle.copyWith(
            color: CharacteristicTokens.color(charInList.toUpperCase()),
            fontWeight: FontWeight.bold,
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  static void _addPotencySpans(
    List<TextSpan> spans,
    TextStyle baseStyle,
    String characteristic,
    String potencyText,
    String strength,
  ) {
    spans.add(TextSpan(
      text: characteristic,
      style: baseStyle.copyWith(
        color: CharacteristicTokens.color(characteristic.toUpperCase()),
        fontWeight: FontWeight.bold,
      ),
    ));
    spans.add(TextSpan(
      text: potencyText,
      style: baseStyle.copyWith(
        color: PotencyTokens.color(strength.toLowerCase()),
        fontWeight: FontWeight.bold,
      ),
    ));
  }
}

class AbilityData {
  AbilityData._({
    required this.component,
    required this.simplified,
    required this.detail,
  });

  factory AbilityData.fromComponent(Component source) {
    final simplified = _tryParseAsSimplified(source);
    final detail = simplified == null ? AbilityDetail.fromComponent(source) : null;
    return AbilityData._(
      component: source,
      simplified: simplified,
      detail: detail,
    );
  }

  AbilityData.fromSimplified(AbilitySimplified source)
      : component = null,
        simplified = source,
        detail = null;

  final Component? component;
  final AbilitySimplified? simplified;
  final AbilityDetail? detail;

  bool get isSimplified => simplified != null;

  /// Try to parse a Component as simplified format
  /// Detects simplified format by checking for simplified-specific fields
  static AbilitySimplified? _tryParseAsSimplified(Component component) {
    final data = component.data;
    final hasNewResource = data.containsKey('resource_value');
    final hasNewRoll = data['power_roll'] is String;
    final hasNewEffects = data['tier_effects'] is List;
    final hasLegacySimplifiedResource = data['resource'] is String;
    final hasLegacySimplifiedRoll = data['roll'] is String;
    final hasLegacySimplifiedEffects = data['effects'] is List;

    if (hasNewResource || hasNewRoll || hasNewEffects || hasLegacySimplifiedResource || hasLegacySimplifiedRoll || hasLegacySimplifiedEffects) {
      try {
        final json = {
          'id': component.id,
          'name': component.name,
          'level': data['level'] ?? 1,
          ...data,
        };
        return AbilitySimplified.fromJson(json);
      } catch (e) {
        // If parsing fails, return null to fall back to legacy format
        return null;
      }
    }
    
    return null;
  }

  // Basics
  String get name => isSimplified ? simplified!.name : detail!.name;
  
  String? get flavor {
    if (isSimplified) {
      final story = simplified!.storyText;
      if (story == null || story.isEmpty) return null;
      return story;
    }
    return detail!.storyText;
  }
  
  int? get level => isSimplified ? simplified!.level : detail!.level;
  
  String? get triggerText {
    if (isSimplified) {
      final trigger = simplified!.triggerText;
      if (trigger == null || trigger.isEmpty) return null;
      return trigger;
    }
    return detail!.triggerText;
  }

  // Costs
  String? get costString {
    final resourceLabel = this.resourceLabel;
    final amount = costAmount;

    if (resourceLabel == null || resourceLabel.isEmpty) {
      if (amount == null || amount <= 0) {
        return isSignature ? 'Signature' : null;
      }
      return 'Cost $amount';
    }

    if (amount == null || amount <= 0) {
      return resourceLabel;
    }

    return '$resourceLabel $amount';
  }

  int? get costAmount {
    if (isSimplified) {
      final amount = simplified!.resourceAmount;
      if (amount != null) {
        return amount;
      }
      if (simplified!.isSignature) {
        return 0;
      }
      return null;
    }

    final cost = detail?.cost;
    if (cost != null) {
      return cost.amount;
    }

    final rawCosts = detail?.rawData['costs'];
    if (rawCosts is Map) {
      final amount = rawCosts['amount'];
      if (amount != null) {
        final parsed = int.tryParse(amount.toString());
        if (parsed != null) {
          return parsed;
        }
      }
      if (rawCosts['signature'] == true) {
        return 0;
      }
    } else if (rawCosts is String && rawCosts.toLowerCase() == 'signature') {
      return 0;
    }

    return null;
  }

  String? get resourceType {
    if (isSimplified) {
      return simplified!.resourceType;
    }
    return detail!.resourceType;
  }

  String? get resourceLabel {
    final resource = resourceType;
    if (resource == null || resource.isEmpty) return null;
    return _formatResource(resource);
  }

  bool get isSignature {
    if (isSimplified) {
      return simplified!.isSignature;
    }

    final rawCosts = detail?.rawData['costs'];
    if (rawCosts is Map && rawCosts['signature'] == true) {
      return true;
    } else if (rawCosts is String && rawCosts.toLowerCase() == 'signature') {
      return true;
    }

    final resource = resourceType?.toLowerCase();
    if (resource == 'signature') {
      return true;
    }

    return false;
  }

  // Keywords
  List<String> get keywords {
    if (isSimplified) {
      return simplified!.keywordsList;
    }
    return detail!.keywords;
  }

  // Action / Range / Targeting
  String? get actionType {
    if (isSimplified) {
      final action = simplified!.actionType;
      if (action == null || action.isEmpty) return null;
      // Capitalize first letter of each word
      return action.split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }
    return detail!.actionType;
  }

  String? get rangeSummary {
    if (isSimplified) {
      final distance = simplified!.distance;
      if (distance == null || distance.isEmpty) return null;
      return distance;
    }
    final range = detail!.range;
    if (range == null) return null;

    final distance = range.distance;
    final area = range.area;
    final value = range.value;

    final parts = <String>[];
    if (distance != null && distance.isNotEmpty) parts.add(distance);
    if (value != null && value.isNotEmpty) parts.add(value);
    if (area != null && area.isNotEmpty) parts.add(area);

    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  String? get targets {
    if (isSimplified) {
      final t = simplified!.targets;
      if (t == null || t.isEmpty) return null;
      return t;
    }
    return detail!.targets;
  }

  // Power roll
  AbilityPowerRoll? get _powerRoll => isSimplified ? null : detail!.powerRoll;

  bool get hasPowerRoll {
    if (isSimplified) {
      return simplified!.hasPowerRoll;
    }
    return _powerRoll != null;
  }

  String? get powerRollLabel {
    if (isSimplified) {
      final roll = simplified!.powerRoll;
      if (roll == null || roll.isEmpty) return null;
      // Extract just "Power Roll" part (before the +)
      final parts = roll.split('+');
      if (parts.isEmpty) return null;
      return parts[0].trim();
    }
    final label = _powerRoll?.label;
    return label ?? (_powerRoll != null ? 'Power roll' : null);
  }

  String? get characteristicSummary {
    if (isSimplified) {
      final roll = simplified!.powerRoll;
      if (roll == null || roll.isEmpty) return null;
      // Extract characteristic part (after the +)
      final parts = roll.split('+');
      if (parts.length < 2) return null;
      return parts.sublist(1).join('+').trim();
    }
    final characteristics = _powerRoll?.characteristics;
    final trimmed = characteristics?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  List<String> get characteristics {
    final summary = characteristicSummary;
    if (summary == null) return const [];
    return _splitCharacteristics(summary)
        .map(_abbreviateCharacteristic)
        .where((value) => value.isNotEmpty)
        .toList();
  }

  List<AbilityTierLine> get tiers {
    if (isSimplified) {
      final effects = simplified!.tierEffects;
      if (effects.isEmpty) return const [];

      const labels = {
        'tier1': '<=11',
        'tier2': '12-16',
        'tier3': '17+',
      };

      final results = <AbilityTierLine>[];

      for (final entry in labels.entries) {
        String? tierText;
        for (final tier in effects) {
          final candidate = tier.getTier(entry.key);
          if (candidate != null && candidate.isNotEmpty) {
            tierText = candidate;
            break;
          }
        }
        if (tierText == null || tierText.isEmpty) continue;
        results.add(
          AbilityTierLine(
            label: entry.value,
            primaryText: tierText,
            secondaryText: null,
          ),
        );
      }

      return results;
    }

    final powerRoll = _powerRoll;
    if (powerRoll == null) return const [];

    const labels = {
      'low': '<=11',
      'mid': '12-16',
      'high': '17+',
    };

    final results = <AbilityTierLine>[];

    for (final entry in labels.entries) {
      final detail = powerRoll.tiers[entry.key];
      if (detail == null) continue;

      final baseDamage = detail.baseDamageValue;
      final characteristicDamage = detail.characteristicDamageOptions;
      final damageTypes = detail.damageTypes;
      final potencies = detail.potencies;
      final conditions = detail.conditions;
      final damageExpression = detail.damageExpression;
      final secondaryDamage = detail.secondaryDamageExpression;
      final descriptiveText = detail.descriptiveText;
      final allText = detail.allText;

      final primaryParts = <String>[];
      if (damageExpression != null && damageExpression.isNotEmpty) {
        primaryParts.add(damageExpression);
      } else {
        if (baseDamage != null) {
          primaryParts.add(baseDamage.toString());
        }
        if (characteristicDamage != null && characteristicDamage.isNotEmpty) {
          primaryParts.add(primaryParts.isEmpty
              ? characteristicDamage
              : '+ $characteristicDamage');
        }
        if (damageTypes != null && damageTypes.isNotEmpty) {
          final suffix = damageTypes.toLowerCase().contains('damage')
              ? damageTypes
              : '$damageTypes damage';
          primaryParts.add(suffix);
        }
      }

      var primary = primaryParts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

      final detailParts = <String>[];
      if (secondaryDamage != null && secondaryDamage.isNotEmpty) {
        detailParts.add(secondaryDamage);
      }
      if (descriptiveText != null && descriptiveText.isNotEmpty) {
        detailParts.add(descriptiveText);
      }
      if (potencies != null && potencies.isNotEmpty) {
        detailParts.add(potencies);
      }
      if (conditions != null && conditions.isNotEmpty) {
        detailParts.add(conditions);
      }

      var secondary = detailParts.isEmpty ? null : detailParts.join(', ');

      if ((primary.isEmpty || primary == '+') && allText != null && allText.isNotEmpty) {
        primary = allText;
        secondary = null;
      } else if (primary.isEmpty && secondary != null && secondary.isNotEmpty) {
        primary = secondary;
        secondary = null;
      }

      if (primary.isEmpty && (secondary == null || secondary.isEmpty)) {
        continue;
      }

      results.add(
        AbilityTierLine(
          label: entry.value,
          primaryText: primary,
          secondaryText: secondary,
        ),
      );
    }

    return results;
  }

  String? get effect {
    if (isSimplified) {
      final e = simplified!.effect;
      if (e == null || e.isEmpty) return null;
      return e;
    }
    return detail!.effect;
  }
  
  String? get specialEffect {
    if (isSimplified) {
      final se = simplified!.specialEffect;
      if (se == null || se.isEmpty) return null;
      return se;
    }
    return detail!.specialEffect;
  }

  String metaSummary() {
    final parts = <String>[];
    if (keywords.isNotEmpty) parts.add(keywords.join(', '));
    if (actionType != null) parts.add(actionType!);
    if (rangeSummary != null) parts.add(rangeSummary!);
    if (characteristicSummary != null) {
      parts.add('Power roll + $characteristicSummary');
    }
    if (resourceLabel != null && costAmount != null && costAmount! > 0) {
      parts.add('${resourceLabel!} $costAmount');
    } else if (isSignature && resourceLabel != null) {
      parts.add(resourceLabel!);
    }
    return parts.join(' • ');
  }

  static String _formatResource(dynamic res) {
    if (res == null) return 'Heroic resource';
    final s = res.toString().trim();
    if (s.isEmpty) return 'Heroic resource';
    if (s == 'heroic_resource') return 'Heroic resource';
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static List<String> _splitCharacteristics(String value) {
    final normalized = value
        .replaceAll('/', ',')
        .replaceAll(RegExp(r'\band\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'\bor\b', caseSensitive: false), ',');
    return normalized
        .split(',')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
  }

  static String _abbreviateCharacteristic(String token) {
    final lower = token.toLowerCase();
    if (lower.startsWith('might')) return 'M';
    if (lower.startsWith('agility')) return 'A';
    if (lower.startsWith('reason')) return 'R';
    if (lower.startsWith('intuition')) return 'I';
    if (lower.startsWith('presence')) return 'P';
    if (token.length == 1 && 'marip'.contains(lower)) {
      return token.toUpperCase();
    }
    return token;
  }
}
