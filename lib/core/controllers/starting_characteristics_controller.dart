import 'package:flutter/widgets.dart';

import '../models/class_data.dart';
import '../models/characteristics_models.dart';
import '../services/starting_characteristics_service.dart';

/// Controller that orchestrates starting characteristic state and interactions.
class StartingCharacteristicsController extends ChangeNotifier {
  StartingCharacteristicsController({
    required ClassData classData,
    required int selectedLevel,
    CharacteristicArray? selectedArray,
    Map<String, int>? initialAssignments,
    Map<String, String?>? initialLevelChoiceSelections,
  })  : _classData = classData,
        _selectedLevel = selectedLevel,
        _selectedArray = selectedArray,
        _initialLevelChoiceSelections = initialLevelChoiceSelections {
    _initialize(initialAssignments ?? const {});
  }

  final Map<String, String?>? _initialLevelChoiceSelections;

  final StartingCharacteristicsService _logic =
      const StartingCharacteristicsService();

  ClassData _classData;
  int _selectedLevel;
  CharacteristicArray? _selectedArray;

  Map<String, int> _fixedValues = {};
  Set<String> _lockedStats = {};
  Map<String, CharacteristicValueToken?> _assignments = {};
  List<CharacteristicValueToken> _tokens = [];
  List<LevelChoice> _levelChoices = [];
  Map<String, String?> _levelChoiceSelections = {};

  /// Current class data backing the controller.
  ClassData get classData => _classData;

  /// Level currently selected in the UI.
  int get selectedLevel => _selectedLevel;

  /// Currently selected array, if any.
  CharacteristicArray? get selectedArray => _selectedArray;

  /// Fixed values imposed by the class definition.
  Map<String, int> get fixedValues => Map.unmodifiable(_fixedValues);

  /// Stats that are locked because of fixed values.
  Set<String> get lockedStats => Set.unmodifiable(_lockedStats);

  /// Current assignment map for draggable tokens.
  Map<String, CharacteristicValueToken?> get assignments =>
      Map.unmodifiable(_assignments);

  /// All tokens produced from the selected array.
  List<CharacteristicValueToken> get tokens => List.unmodifiable(_tokens);

  /// Level-based choices that require user input.
  List<LevelChoice> get levelChoices => List.unmodifiable(_levelChoices);

  /// Persisted selections for level choices keyed by choice id.
  Map<String, String?> get levelChoiceSelections =>
      Map.unmodifiable(_levelChoiceSelections);

  /// Tokens that are not currently assigned to any slot.
  List<CharacteristicValueToken> get unassignedTokens {
    final assignedIds = _assignments.values
        .whereType<CharacteristicValueToken>()
        .map((token) => token.id)
        .toSet();
    return _tokens.where((token) => !assignedIds.contains(token.id)).toList();
  }

  /// Builds the latest summary of totals, contributions, and bonuses.
  CharacteristicSummary get summary {
    final entries = _collectAdjustmentEntries();
    return _logic.buildCharacteristicSummary(
      fixedValues: _fixedValues,
      assignments: _assignments,
      adjustmentEntries: entries,
      levelChoiceSelections: _levelChoiceSelections,
    );
  }

  /// Returns a plain map of assigned values suitable for persistence.
  Map<String, int> get assignedCharacteristics {
    final result = <String, int>{};
    _assignments.forEach((stat, token) {
      if (token != null) result[stat] = token.value;
    });
    return result;
  }

  /// Calculates potency values based on the current totals.
  Map<String, int> computePotency() {
    return _logic.computePotency(
      classData: _classData,
      totals: summary.totals,
    );
  }

  void _initialize(Map<String, int> initialAssignments) {
    _loadFixedValues();
    _tokens = _logic.buildTokens(_selectedArray?.values ?? const []);
    _assignments = _logic.applyExternalAssignments(
      base: _buildEmptyAssignments(),
      tokens: _tokens,
      sourceAssignments: initialAssignments,
    );
    _levelChoices = _buildLevelChoices();
    _levelChoiceSelections = _buildLevelChoiceSelections(
      preserveSelections: false,
      initialSelections: _initialLevelChoiceSelections,
    );
  }

  void _loadFixedValues() {
    final normalized = <String, int>{
      for (final stat in CharacteristicUtils.characteristicOrder) stat: 0,
    };
    final locked = <String>{};
    _classData.startingCharacteristics.fixedStartingCharacteristics
        .forEach((key, value) {
      final normalizedKey = CharacteristicUtils.normalizeKey(key);
      if (normalizedKey == null) return;
      if (CharacteristicUtils.characteristicOrder.contains(normalizedKey)) {
        normalized[normalizedKey] = value;
        locked.add(normalizedKey);
      }
    });
    _fixedValues = normalized;
    _lockedStats = locked;
  }

  Map<String, CharacteristicValueToken?> _buildEmptyAssignments() {
    final map = <String, CharacteristicValueToken?>{};
    for (final stat in CharacteristicUtils.characteristicOrder) {
      if (!_lockedStats.contains(stat)) {
        map[stat] = null;
      }
    }
    return map;
  }

  List<AdjustmentEntry> _collectAdjustmentEntries() {
    return _logic.collectAdjustmentEntries(
      classData: _classData,
      selectedLevel: _selectedLevel,
    );
  }

  List<LevelChoice> _buildLevelChoices() {
    final entries = _collectAdjustmentEntries();
    return _logic.buildLevelChoices(entries);
  }

  Map<String, String?> _buildLevelChoiceSelections({
    required bool preserveSelections,
    Map<String, String?>? initialSelections,
  }) {
    return _logic.buildLevelChoiceSelections(
      choices: _levelChoices,
      previousSelections: preserveSelections ? _levelChoiceSelections : (initialSelections ?? const {}),
      preserveSelections: preserveSelections || initialSelections != null,
    );
  }

  /// Updates controller state when the backing class changes.
  void updateClass(ClassData newClass) {
    if (identical(_classData, newClass)) {
      return;
    }
    _classData = newClass;
    _loadFixedValues();
    _tokens = _logic.buildTokens(_selectedArray?.values ?? const []);
    _assignments = _logic.applyExternalAssignments(
      base: _buildEmptyAssignments(),
      tokens: _tokens,
      sourceAssignments: const {},
    );
    _levelChoices = _buildLevelChoices();
    _levelChoiceSelections = _buildLevelChoiceSelections(
      preserveSelections: false,
    );
    notifyListeners();
  }

  /// Updates controller state when the selected level changes.
  void updateLevel(int newLevel) {
    if (_selectedLevel == newLevel) return;
    _selectedLevel = newLevel;
    _levelChoices = _buildLevelChoices();
    _levelChoiceSelections = _buildLevelChoiceSelections(
      preserveSelections: true,
    );
    notifyListeners();
  }

  /// Updates controller state when the array selection changes.
  void updateArray(CharacteristicArray? newArray) {
    if (_selectedArray == newArray) return;
    _selectedArray = newArray;
    _tokens = _logic.buildTokens(newArray?.values ?? const []);
    _assignments = _buildEmptyAssignments();
    notifyListeners();
  }

  /// Applies externally provided assignments (e.g., from saved state).
  void updateExternalAssignments(Map<String, int> newAssignments) {
    final updated = _logic.applyExternalAssignments(
      base: _assignments.isEmpty ? _buildEmptyAssignments() : _assignments,
      tokens: _tokens,
      sourceAssignments: newAssignments,
    );
    if (_assignmentsEqual(_assignments, updated)) return;
    _assignments = updated;
    notifyListeners();
  }

  /// Assigns or swaps a token into a stat slot.
  void assignToken(String stat, CharacteristicValueToken? selectedToken) {
    if (!_assignments.containsKey(stat)) return;
    final currentToken = _assignments[stat];
    if (currentToken?.id == selectedToken?.id) return;

    final updated = Map<String, CharacteristicValueToken?>.from(_assignments);

    if (selectedToken == null) {
      updated[stat] = null;
    } else {
      String? previousOwner;
      for (final entry in _assignments.entries) {
        if (entry.value?.id == selectedToken.id) {
          previousOwner = entry.key;
          break;
        }
      }
      updated[stat] = selectedToken;
      if (previousOwner != null && previousOwner != stat) {
        updated[previousOwner] = currentToken;
      }
    }

    _assignments = updated;
    notifyListeners();
  }

  /// Clears a token by locating and nulling its current owner slot.
  void clearToken(CharacteristicValueToken token) {
    String? owner;
    for (final entry in _assignments.entries) {
      if (entry.value?.id == token.id) {
        owner = entry.key;
        break;
      }
    }
    if (owner == null) return;
    assignToken(owner, null);
  }

  /// Records a level choice selection for "any" bonuses.
  void selectLevelChoice(String choiceId, String? stat) {
    if (_levelChoiceSelections[choiceId] == stat) return;
    _levelChoiceSelections = Map<String, String?>.from(_levelChoiceSelections)
      ..[choiceId] = stat;
    notifyListeners();
  }

  bool _assignmentsEqual(
    Map<String, CharacteristicValueToken?> a,
    Map<String, CharacteristicValueToken?> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key]?.id != entry.value?.id) return false;
    }
    return true;
  }
}
