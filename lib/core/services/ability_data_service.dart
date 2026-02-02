import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/component.dart';
import '../models/characteristics_models.dart';
import '../models/ability_simplified.dart';

class AbilityLibrary {
  AbilityLibrary(this._index, this._componentsById);

  final Map<String, Component> _index;
  final Map<String, Component> _componentsById;

  Iterable<Component> get components => _componentsById.values;

  Component? find(String reference) {
    final key = _normalizeAbilityKey(reference);
    if (key.isEmpty) return null;
    return _index[key];
  }

  Component? byId(String id) {
    if (id.isEmpty) return null;
    return _componentsById[id];
  }

  bool get isEmpty => _componentsById.isEmpty;
}

class AbilityDataService {
  AbilityDataService._();

  static final AbilityDataService _instance = AbilityDataService._();

  factory AbilityDataService() => _instance;

  AbilityLibrary? _cachedLibrary;
  final Map<String, List<Component>> _classAbilityCache = {};
  final Map<String, List<AbilitySimplified>> _simplifiedAbilityCache = {};

  static const List<String> _abilityAssetPaths = [
    'data/abilities/abilities.json',
    'data/abilities/ancestry_abilities.json',
    'data/abilities/complication_abilities.json',
    'data/abilities/item_imbuement_abilities.json',
    'data/abilities/kit_abilities.json',
    'data/abilities/kits_abilities.json',
    'data/abilities/perk_abilities.json',
    'data/abilities/stormwight_abilities.json',
    'data/abilities/titles_abilities.json',
    'data/abilities/treasure_abilities.json',
  ];
  static const List<String> _classAbilityAssetPrefixes = [
    'data/abilities/class_abilities_new/',
    'data/abilities/class_abilities_simplified/',
  ];

  Future<AbilityLibrary> loadLibrary() async {
    if (_cachedLibrary != null) {
      return _cachedLibrary!;
    }

    final index = <String, Component>{};
    final byId = <String, Component>{};

    for (final path in _abilityAssetPaths) {
      await _ingestAbilityAsset(path, index, byId);
    }

    final classAbilityPaths = await _resolveClassAbilityAssets();
    for (final path in classAbilityPaths) {
      await _ingestAbilityAsset(path, index, byId);
    }

    final library = AbilityLibrary(
      Map.unmodifiable(index),
      Map.unmodifiable(byId),
    );
    _cachedLibrary = library;
    _classAbilityCache.clear();
    return library;
  }

  Future<List<Component>> loadClassAbilities(String classSlug) async {
    final normalizedSlug = classSlug.trim().toLowerCase();
    if (normalizedSlug.isEmpty) return const [];

    final cached = _classAbilityCache[normalizedSlug];
    if (cached != null) {
      return cached;
    }

    final library = await loadLibrary();
    final components = library.components.where((component) {
      final slug = component.data['class_slug'];
      if (slug is String && slug.trim().toLowerCase() == normalizedSlug) {
        return true;
      }
      final path = component.data['ability_source_path'];
      if (path is String && _isClassAbilityAssetPath(path)) {
        final relative = _relativeClassAbilityPath(path);
        if (relative != null &&
            relative.toLowerCase().startsWith('$normalizedSlug/')) {
          return true;
        }
        final inferredSlug = _inferSlugFromRelativePath(relative);
        if (inferredSlug != null && inferredSlug == normalizedSlug) {
          return true;
        }
      }
      return false;
    }).toList(growable: false);

    components.sort((a, b) {
      final levelA = (componentLevel(a) ?? 0);
      final levelB = (componentLevel(b) ?? 0);
      if (levelA != levelB) {
        return levelA.compareTo(levelB);
      }
      return a.name.compareTo(b.name);
    });

    final result = List<Component>.unmodifiable(components);
    _classAbilityCache[normalizedSlug] = result;
    return result;
  }

  /// Load simplified abilities for a class from the class_abilities_simplified folder
  Future<List<AbilitySimplified>> loadClassAbilitiesSimplified(String classSlug) async {
    final normalizedSlug = classSlug.trim().toLowerCase();
    if (normalizedSlug.isEmpty) return const [];

    final cached = _simplifiedAbilityCache[normalizedSlug];
    if (cached != null) {
      return cached;
    }

    final path = 'data/abilities/class_abilities_simplified/${normalizedSlug}_abilities.json';
    
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      
      if (decoded is! List) {
        return const [];
      }

      final abilities = <AbilitySimplified>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            final ability = AbilitySimplified.fromJson(item);
            abilities.add(ability);
          } catch (e) {
            // Skip malformed abilities
            continue;
          }
        }
      }

      // Sort by level then name
      abilities.sort((a, b) {
        if (a.level != b.level) {
          return a.level.compareTo(b.level);
        }
        return a.name.compareTo(b.name);
      });

      final result = List<AbilitySimplified>.unmodifiable(abilities);
      _simplifiedAbilityCache[normalizedSlug] = result;
      return result;
    } catch (error) {
      // If the simplified abilities don't exist, return empty list
      return const [];
    }
  }

  int? componentLevel(Component component) {
    final value = component.data['level'];
    if (value is num) return value.toInt();
    return CharacteristicUtils.toIntOrNull(value);
  }

  Future<void> _ingestAbilityAsset(
    String path,
    Map<String, Component> index,
    Map<String, Component> byId,
  ) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            final component = _parseComponent(item, sourcePath: path);
            if (component != null) {
              _registerComponent(index, byId, component);
            }
          }
        }
      } else if (decoded is Map) {
        // Check if this is a single component (has 'type' field) or a collection
        if (decoded['type'] != null) {
          // Single component file (new format)
          final component = _parseComponent(decoded, sourcePath: path);
          if (component != null) {
            _registerComponent(index, byId, component);
          }
        } else {
          // Collection of components (old format)
          for (final mapEntry in decoded.entries) {
            final value = mapEntry.value;
            if (value is Map) {
              final merged = Map<String, dynamic>.from(value);
              merged['id'] ??= mapEntry.key;
              final component = _parseComponent(merged, sourcePath: path);
              if (component != null) {
                _registerComponent(index, byId, component);
              }
            }
          }
        }
      }
    } catch (error) {
      final message = error.toString();
      if (message.contains('Unable to load asset')) {
        // Asset is missing from the bundle; skip without crashing.
        return;
      }
      // Surface other errors to simplify debugging without failing silently.
      throw Exception('Failed to load ability asset "$path": $error');
    }
  }

  Component? _parseComponent(dynamic raw, {required String sourcePath}) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final nameRaw = map['name'];
    final name = _cleanString(nameRaw);
    final idRaw = map['id'];
    final id = _extractId(idRaw, fallback: name);
    if (id == null) return null;

    map.remove('id');
    map.remove('type');
    map.remove('name');

    final data = Map<String, dynamic>.from(map);

    final componentName = name.isNotEmpty ? name : _titleFromIdentifier(id);

    final derived = _buildDerivedMetadata(
      sourcePath: sourcePath,
      baseId: id,
      data: data,
      componentName: componentName,
    );

    return Component(
      id: derived.id,
      type: 'ability',
      name: componentName,
      data: derived.data,
      source: 'seed',
    );
  }

  Future<List<String>> _resolveClassAbilityAssets() async {
    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(manifestRaw);
      final paths = <String>{};

      void addPath(dynamic candidate) {
        if (candidate is! String) return;
        final normalized = candidate.replaceAll('\\', '/');
        if (!_isClassAbilityAssetPath(normalized)) return;
        if (!normalized.endsWith('.json')) return;
        paths.add(normalized);
      }

      if (decoded is Map) {
        for (final entry in decoded.entries) {
          addPath(entry.key);
          if (entry.value is List) {
            for (final variant in entry.value as List) {
              addPath(variant);
            }
          }
        }
      } else if (decoded is List) {
        for (final entry in decoded) {
          addPath(entry);
        }
      }

      final sorted = paths.toList()..sort();
      return sorted;
    } catch (error) {
      throw Exception('Unable to resolve class ability assets: $error');
    }
  }

  _DerivedComponentMetadata _buildDerivedMetadata({
    required String sourcePath,
    required String baseId,
    required Map<String, dynamic> data,
    required String componentName,
  }) {
    final normalizedPath = sourcePath.replaceAll('\\', '/');
    final augmented = Map<String, dynamic>.from(data);
    augmented['original_id'] ??= baseId;
    augmented['ability_source_path'] ??= normalizedPath;

    String resolvedId = baseId;

    if (_isClassAbilityAssetPath(normalizedPath)) {
      final relative = _relativeClassAbilityPath(normalizedPath);
      final classSegment = _classSegmentFromRelative(relative);
      final levelSegment = _levelSegmentFromRelative(relative);

      final classSlug =
          classSegment != null ? _slugify(classSegment) : _inferSlugFromRelativePath(relative);
      if (classSlug != null && classSlug.isNotEmpty) {
        augmented['class_slug'] ??= classSlug;
        augmented['class_name'] ??= classSegment ?? classSlug;
      }
      if (levelSegment != null && levelSegment.isNotEmpty) {
        augmented['level_band'] ??= levelSegment;
      } else if (!augmented.containsKey('level_band') &&
          augmented['level'] != null) {
        augmented['level_band'] = 'level_${augmented['level']}';
      }

      final existingLevel = _parseLevelNumber(augmented['level']);
      if (existingLevel != null) {
        augmented['level'] = existingLevel;
      } else {
        final inferredLevel =
            _parseLevelNumber(levelSegment) ?? _parseLevelNumber(relative);
        if (inferredLevel != null) {
          augmented['level'] = inferredLevel;
        }
      }

      // Inject costs metadata for simplified assets if missing
      if (!augmented.containsKey('costs')) {
        final inferredCosts = _buildCostsFromSimplifiedData(augmented);
        if (inferredCosts != null) {
          augmented['costs'] = inferredCosts;
        }
      }

      final costs = augmented['costs'];
      String? resourceSlug;
      String? costAmountSlug;
      if (costs is Map) {
        final resource = costs['resource'];
        if (resource is String && resource.trim().isNotEmpty) {
          resourceSlug = _slugify(resource);
        }
        final amount = costs['amount'];
        if (amount != null) {
          costAmountSlug = 'cost${amount.toString()}';
        }
      }

      final parts = <String>[
        'ability',
        if (classSlug != null && classSlug.isNotEmpty) classSlug,
        if (levelSegment != null && levelSegment.isNotEmpty)
          _slugify(levelSegment),
        if (resourceSlug != null && resourceSlug.isNotEmpty) resourceSlug,
        if (costAmountSlug != null) costAmountSlug,
        baseId,
      ];

      resolvedId = parts.where((element) => element.isNotEmpty).join('_');
      augmented['display_name'] ??= componentName;
    }

    augmented['resolved_id'] ??= resolvedId;

    return _DerivedComponentMetadata(
      id: resolvedId,
      data: augmented,
    );
  }

  bool _isClassAbilityAssetPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    for (final prefix in _classAbilityAssetPrefixes) {
      if (normalized.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  String? _relativeClassAbilityPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    for (final prefix in _classAbilityAssetPrefixes) {
      if (normalized.startsWith(prefix)) {
        return normalized.substring(prefix.length);
      }
    }
    return null;
  }

  String? _classSegmentFromRelative(String? relative) {
    if (relative == null || relative.isEmpty) return null;
    final segments = relative.split('/');
    if (segments.isEmpty) return null;
    final first = segments.first.trim();
    if (first.isEmpty) return null;
    if (first.endsWith('.json')) {
      final name = first.substring(0, first.length - 5);
      if (name.endsWith('_abilities')) {
        final base = name.substring(0, name.length - '_abilities'.length);
        return base;
      }
      return name;
    }
    return first;
  }

  String? _levelSegmentFromRelative(String? relative) {
    if (relative == null || relative.isEmpty) return null;
    final segments = relative.split('/');
    if (segments.length >= 2) {
      final second = segments[1].trim();
      if (second.endsWith('.json')) {
        return second.substring(0, second.length - 5);
      }
      return second.isEmpty ? null : second;
    }
    return null;
  }

  String? _inferSlugFromRelativePath(String? relative) {
    final segment = _classSegmentFromRelative(relative);
    if (segment == null || segment.isEmpty) return null;
    return _slugify(segment);
  }

  int? _parseLevelNumber(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final match = RegExp(r'(\d+)').firstMatch(value);
      if (match != null) {
        final parsed = int.tryParse(match.group(1)!);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _buildCostsFromSimplifiedData(
    Map<String, dynamic> augmented,
  ) {
    int? parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim());
      return null;
    }

    final resourceRaw = augmented['resource'];
    final resourceName = resourceRaw is String ? resourceRaw.trim() : '';
    final resourceValue = parseInt(augmented['resource_value']);

    if (resourceName.isEmpty && resourceValue == null) {
      return null;
    }

    final normalizedName = resourceName;
    if (normalizedName.toLowerCase() == 'signature') {
      final result = <String, dynamic>{
        'signature': true,
      };
      if (normalizedName.isNotEmpty) {
        result['resource'] = normalizedName;
      }
      return result;
    }

    if (resourceValue != null && resourceValue > 0) {
      final result = <String, dynamic>{};
      if (normalizedName.isNotEmpty) {
        result['resource'] = normalizedName;
      }
      result['amount'] = resourceValue;
      return result;
    }

    if (normalizedName.isEmpty) {
      return null;
    }

    final parts = normalizedName.split(RegExp(r'\s+'));
    final trailing = parts.isNotEmpty ? parts.last : '';
    final parsedAmount = int.tryParse(trailing);
    if (parsedAmount != null) {
      final resourceOnly = parts.length > 1
          ? parts.sublist(0, parts.length - 1).join(' ').trim()
          : '';
      if (resourceOnly.toLowerCase() == 'signature') {
        return {
          'resource': resourceOnly,
          'signature': true,
        };
      }
      final result = <String, dynamic>{
        'amount': parsedAmount,
      };
      if (resourceOnly.isNotEmpty) {
        result['resource'] = resourceOnly;
      }
      return result;
    }

    return {
      'resource': normalizedName,
    };
  }

  void _registerComponent(
    Map<String, Component> index,
    Map<String, Component> byId,
    Component component,
  ) {
    byId[component.id] = component;

    void addKey(String? value) {
      if (value == null) return;
      final normalized = _normalizeAbilityKey(value);
      if (normalized.isEmpty) return;
      index.putIfAbsent(normalized, () => component);
      index.putIfAbsent(normalized.replaceAll('_', ''), () => component);
    }

    addKey(component.id);
    addKey(component.name);
    addKey(component.id.replaceAll('_', ' '));
    addKey(component.name.replaceAll('-', ' '));
  }
}

class _DerivedComponentMetadata {
  const _DerivedComponentMetadata({
    required this.id,
    required this.data,
  });

  final String id;
  final Map<String, dynamic> data;
}

String _normalizeAbilityKey(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) return '';
  final normalized = trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  final collapsed = normalized.replaceAll(RegExp(r'_+'), '_');
  return collapsed.replaceAll(RegExp(r'^_|_$'), '');
}

String? _extractId(dynamic value, {String? fallback}) {
  final id = _cleanString(value);
  if (id.isNotEmpty) return id;
  if (fallback != null && fallback.isNotEmpty) {
    return _slugify(fallback);
  }
  return null;
}

String _cleanString(dynamic value) {
  if (value == null) return '';
  final str = value.toString().trim();
  return str;
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  if (lower.isEmpty) return '';
  final slug = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return slug.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
}

String _titleFromIdentifier(String id) {
  final parts = id.split(RegExp(r'[_\s-]+')).where((part) => part.isNotEmpty);
  return parts
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
