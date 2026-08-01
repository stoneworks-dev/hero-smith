import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/text/heroes_sheet/story/sheet_story_title_progress_text.dart';
import '../../../core/theme/app_icon.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/form_theme.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/theme/story_theme.dart';
import '../../../widgets/shared/drag_scroll_behavior.dart';

const _titlesColor = StoryTheme.titlesAccent;

// ---------------------------------------------------------------------------
// Title prerequisite analysis helpers
// ---------------------------------------------------------------------------

/// Parses a prerequisite string and determines the tracking mode and steps.
class _PrerequisiteInfo {
  /// Required prior title id (e.g. "ship_captain" for Corsair).
  final String? requiredTitleId;

  /// The actionable part of the prerequisite (after "Have X title and").
  final String actionText;

  /// Number of discrete steps the user needs to track.
  /// 1 = single checkbox, >1 = multi-step counter.
  final int totalSteps;

  const _PrerequisiteInfo({
    this.requiredTitleId,
    required this.actionText,
    this.totalSteps = 1,
  });
}

/// Analyses the prerequisite text and title list to produce tracking metadata.
_PrerequisiteInfo _analysePrerequisite(
  String prerequisite,
  List<Map<String, dynamic>> allTitles,
) {
  String actionText = prerequisite;
  String? requiredTitleId;

  // Detect "Have X title and …" pattern.
  final haveTitleRe = RegExp(r'^Have (.+?) title and (.+)$', caseSensitive: false);
  final match = haveTitleRe.firstMatch(prerequisite);
  if (match != null) {
    final requiredTitleName = match.group(1)!;
    actionText = match.group(2)!;
    // Resolve the title id from name.
    for (final t in allTitles) {
      if ((t['name'] as String?)?.toLowerCase() == requiredTitleName.toLowerCase()) {
        requiredTitleId = t['id'] as String?;
        break;
      }
    }
  }

  // Detect counts in the action text.
  final countPatterns = <RegExp, int Function(RegExpMatch m)>{
    // "Defeat three leader/solo …" → 3
    RegExp(r'\b(two|three|four|five|six|seven|eight|nine|ten)\b', caseSensitive: false):
        (m) => _wordToNumber(m.group(1)!),
    // "at least five respites" → 5
    RegExp(r'at least (\w+)', caseSensitive: false): (m) {
      final n = int.tryParse(m.group(1)!);
      if (n != null) return n;
      return _wordToNumber(m.group(1)!);
    },
    // "defeat five non-minion …" → 5
    RegExp(r'defeat (\w+) ', caseSensitive: false): (m) {
      final n = int.tryParse(m.group(1)!);
      if (n != null) return n;
      return _wordToNumber(m.group(1)!);
    },
  };

  int steps = 1;
  for (final entry in countPatterns.entries) {
    final m = entry.key.firstMatch(actionText);
    if (m != null) {
      final parsed = entry.value(m);
      if (parsed > 1) {
        steps = parsed;
        break;
      }
    }
  }

  return _PrerequisiteInfo(
    requiredTitleId: requiredTitleId,
    actionText: actionText,
    totalSteps: steps,
  );
}

int _wordToNumber(String word) {
  const map = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
  };
  return map[word.toLowerCase()] ?? 1;
}

// ---------------------------------------------------------------------------
// TitleProgressPage
// ---------------------------------------------------------------------------

class TitleProgressPage extends ConsumerStatefulWidget {
  final String heroId;
  /// Titles already earned by this hero (set of title ids).
  final Set<String> earnedTitleIds;
  /// Callback when the user earns a new title from this page.
  final void Function(String titleId)? onTitleEarned;

  const TitleProgressPage({
    super.key,
    required this.heroId,
    required this.earnedTitleIds,
    this.onTitleEarned,
  });

  @override
  ConsumerState<TitleProgressPage> createState() => _TitleProgressPageState();
}

class _TitleProgressPageState extends ConsumerState<TitleProgressPage> {
  List<Map<String, dynamic>> _allTitles = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & filter
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _echelonFilter; // null = all
  String _statusFilter = 'all'; // all | available | in_progress | completed

  // Progress tracking: titleId → completedSteps (int)
  Map<String, int> _progress = {};

  // Earned titles (mutable copy so we can update when user adds a title)
  late Set<String> _earnedTitleIds;

  @override
  void initState() {
    super.initState();
    _earnedTitleIds = Set<String>.from(widget.earnedTitleIds);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- Data loading ----------

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load titles JSON
      final titlesData = await rootBundle.loadString('data/story/titles.json');
      final titlesList = json.decode(titlesData) as List;
      _allTitles = titlesList.cast<Map<String, dynamic>>();

      // Load persisted progress from HeroConfig
      await _loadProgress();

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = SheetStoryTitleProgressText.failedToLoad(e);
      });
    }
  }

  Future<void> _loadProgress() async {
    final db = ref.read(appDatabaseProvider);
    final stored = await db.getHeroConfigValue(widget.heroId, 'title_progress');
    if (stored != null) {
      _progress = (stored['steps'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {};
    }
  }

  Future<void> _saveProgress() async {
    final db = ref.read(appDatabaseProvider);
    await db.setHeroConfig(
      heroId: widget.heroId,
      configKey: 'title_progress',
      value: {'steps': _progress},
    );
  }

  // ---------- Progress mutations ----------

  void _setSteps(String titleId, int steps, int totalSteps) {
    setState(() {
      _progress[titleId] = steps.clamp(0, totalSteps);
    });
    _saveProgress();
  }

  void _toggleComplete(String titleId, int totalSteps) {
    final current = _progress[titleId] ?? 0;
    _setSteps(titleId, current >= totalSteps ? 0 : totalSteps, totalSteps);
  }

  void _resetProgress(String titleId) {
    setState(() {
      _progress.remove(titleId);
    });
    _saveProgress();
  }

  // ---------- Status helpers ----------

  String _titleStatus(String titleId, int totalSteps) {
    if (_earnedTitleIds.contains(titleId)) return 'earned';
    final done = _progress[titleId] ?? 0;
    if (done >= totalSteps) return 'completed';
    if (done > 0) return 'in_progress';
    return 'not_started';
  }

  // ---------- Filtering ----------

  List<Map<String, dynamic>> get _filteredTitles {
    var titles = List<Map<String, dynamic>>.from(_allTitles);

    // Echelon filter
    if (_echelonFilter != null) {
      titles = titles.where((t) => (t['echelon'] as int?) == _echelonFilter).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      titles = titles.where((t) {
        final name = (t['name'] as String? ?? '').toLowerCase();
        final prereq = (t['prerequisite'] as String? ?? '').toLowerCase();
        final desc = (t['description_text'] as String? ?? '').toLowerCase();
        return name.contains(q) || prereq.contains(q) || desc.contains(q);
      }).toList();
    }

    // Status filter
    if (_statusFilter != 'all') {
      titles = titles.where((t) {
        final id = t['id'] as String;
        final info = _analysePrerequisite(t['prerequisite'] as String? ?? '', _allTitles);
        final status = _titleStatus(id, info.totalSteps);

        switch (_statusFilter) {
          case 'available':
            return status == 'not_started' || status == 'in_progress';
          case 'in_progress':
            return status == 'in_progress';
          case 'completed':
            return status == 'completed' || status == 'earned';
          default:
            return true;
        }
      }).toList();
    }

    return titles;
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        title: const Text(
          SheetStoryTitleProgressText.pageTitle,
          style: TextStyle(color: _titlesColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: _titlesColor),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _titlesColor))
          : _errorMessage != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(color: Colors.red.shade300)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _titlesColor,
              foregroundColor: Colors.black,
            ),
            child: const Text(SheetStoryTitleProgressText.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final filtered = _filteredTitles;

    // Group by echelon
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final t in filtered) {
      final echelon = (t['echelon'] as int?) ?? 1;
      grouped.putIfAbsent(echelon, () => []).add(t);
    }
    final sortedEchelons = grouped.keys.toList()..sort();

    // Summary counts
    final totalCount = _allTitles.length;
    final earnedCount = _earnedTitleIds.length;

    return Column(
      children: [
        // Search + filters
        _buildSearchAndFilters(earnedCount, totalCount),
        // Title list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    SheetStoryTitleProgressText.noTitlesMatch,
                    style: TextStyle(color: FormTheme.textSecondary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    for (final echelon in sortedEchelons) ...[
                      _buildEchelonHeader(echelon),
                      ...grouped[echelon]!.map(_buildTitleProgressCard),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ],
    );
  }

  // ---------- Search & Filter bar ----------

  Widget _buildSearchAndFilters(int earnedCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        border: Border(bottom: BorderSide(color: FormTheme.borderDim)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary + search
          Row(
            children: [
              Expanded(
                child: Text(
                  SheetStoryTitleProgressText.progressSummary(earnedCount, totalCount),
                  style: const TextStyle(
                    color: _titlesColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: FormTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: SheetStoryTitleProgressText.searchTitlesHint,
              hintStyle: TextStyle(color: FormTheme.textHint),
              prefixIcon: const Icon(Icons.search, color: _titlesColor, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: FormTheme.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              filled: true,
              fillColor: FormTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: FormTheme.borderDim),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: FormTheme.borderDim),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _titlesColor),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 10),
          // Echelon filter chips
          ScrollConfiguration(
            behavior: const DragScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(SheetStoryTitleProgressText.allFilter, null),
                  for (int e = 1; e <= 4; e++)
                    _filterChip(SheetStoryTitleProgressText.echelonLabel(e), e),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Status filter chips
          ScrollConfiguration(
            behavior: const DragScrollBehavior(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusChip(SheetStoryTitleProgressText.allFilter, 'all'),
                  _statusChip(SheetStoryTitleProgressText.availableFilter, 'available'),
                  _statusChip(SheetStoryTitleProgressText.inProgressFilter, 'in_progress'),
                  _statusChip(SheetStoryTitleProgressText.completedFilter, 'completed'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? echelon) {
    final sel = _echelonFilter == echelon;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.black : FormTheme.textSecondary)),
        selected: sel,
        onSelected: (_) => setState(() => _echelonFilter = echelon),
        selectedColor: _titlesColor,
        backgroundColor: FormTheme.surfaceDark,
        checkmarkColor: Colors.black,
        side: BorderSide(color: sel ? _titlesColor : FormTheme.borderDim),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _statusChip(String label, String status) {
    final sel = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.black : FormTheme.textSecondary)),
        selected: sel,
        onSelected: (_) => setState(() => _statusFilter = status),
        selectedColor: _titlesColor,
        backgroundColor: FormTheme.surfaceDark,
        checkmarkColor: Colors.black,
        side: BorderSide(color: sel ? _titlesColor : FormTheme.borderDim),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ---------- Echelon header ----------

  Widget _buildEchelonHeader(int echelon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: _titlesColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          AppIcon(TitleIcons.fromEchelon(echelon), color: _titlesColor, size: 18),
          const SizedBox(width: 6),
          Text(
            SheetStoryTitleProgressText.echelonLabel(echelon),
            style: const TextStyle(
              color: _titlesColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Title progress card ----------

  Widget _buildTitleProgressCard(Map<String, dynamic> title) {
    final titleId = title['id'] as String;
    final titleName = title['name'] as String? ?? 'Unknown';
    final echelon = (title['echelon'] as int?) ?? 1;
    final prerequisite = title['prerequisite'] as String? ?? '';
    final special = title['special'] as String?;
    final info = _analysePrerequisite(prerequisite, _allTitles);
    final completedSteps = _progress[titleId] ?? 0;
    final status = _titleStatus(titleId, info.totalSteps);

    // Colors based on status
    final Color statusColor;
    final IconData statusIcon;
    switch (status) {
      case 'earned':
        statusColor = Colors.green.shade400;
        statusIcon = Icons.verified;
        break;
      case 'completed':
        statusColor = Colors.green.shade300;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.orange.shade300;
        statusIcon = Icons.timelapse;
        break;
      default:
        statusColor = FormTheme.textMuted;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: NavigationTheme.cardBackgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'earned'
              ? statusColor.withAlpha(80)
              : status == 'completed'
                  ? statusColor.withAlpha(60)
                  : FormTheme.borderDim,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _titlesColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AppIcon(TitleIcons.fromEchelon(echelon), color: _titlesColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleName,
                        style: TextStyle(
                          color: status == 'earned' ? statusColor : FormTheme.textBright,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(status),
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (status != 'earned' && completedSteps > 0)
                  IconButton(
                    icon: Icon(Icons.restart_alt, color: FormTheme.textMuted, size: 18),
                    tooltip: SheetStoryTitleProgressText.resetProgress,
                    onPressed: () => _resetProgress(titleId),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Required title prerequisite
            if (info.requiredTitleId != null) ...[
              _buildRequiredTitleChip(info.requiredTitleId!),
              const SizedBox(height: 8),
            ],

            // Prerequisite text
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FormTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FormTheme.borderDim),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(TitleIcons.prerequisite, color: _titlesColor.withAlpha(180), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.actionText,
                      style: TextStyle(color: FormTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Special note
            if (special != null && special.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue.shade300),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      special,
                      style: TextStyle(color: Colors.blue.shade200, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],

            if (status != 'earned') ...[
              const SizedBox(height: 12),

              // Progress tracking
              if (info.totalSteps == 1)
                _buildSingleStepTracker(titleId, completedSteps >= 1, info.totalSteps)
              else
                _buildMultiStepTracker(titleId, completedSteps, info.totalSteps),

              // "Add Title" button when complete
              if (status == 'completed') ...[
                const SizedBox(height: 10),
                _buildAddTitleButton(titleId, titleName),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'earned':
        return SheetStoryTitleProgressText.titleAlreadyEarned;
      case 'completed':
        return SheetStoryTitleProgressText.statusComplete;
      case 'in_progress':
        return SheetStoryTitleProgressText.statusInProgress;
      default:
        return SheetStoryTitleProgressText.statusNotStarted;
    }
  }

  // ---------- Required title chip ----------

  Widget _buildRequiredTitleChip(String requiredTitleId) {
    final requiredTitle = _allTitles.firstWhere(
      (t) => t['id'] == requiredTitleId,
      orElse: () => <String, dynamic>{'name': requiredTitleId},
    );
    final hasRequired = _earnedTitleIds.contains(requiredTitleId);
    final name = requiredTitle['name'] as String? ?? requiredTitleId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasRequired ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasRequired ? Colors.green.withAlpha(60) : Colors.red.withAlpha(60),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasRequired ? Icons.check_circle : Icons.lock_outline,
            size: 15,
            color: hasRequired ? Colors.green.shade300 : Colors.red.shade300,
          ),
          const SizedBox(width: 6),
          Text(
            '${SheetStoryTitleProgressText.requiresTitleLabel}: $name',
            style: TextStyle(
              color: hasRequired ? Colors.green.shade200 : Colors.red.shade200,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Single step (checkbox) ----------

  Widget _buildSingleStepTracker(String titleId, bool isComplete, int totalSteps) {
    return InkWell(
      onTap: () => _toggleComplete(titleId, totalSteps),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isComplete ? _titlesColor.withAlpha(18) : FormTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isComplete ? _titlesColor.withAlpha(60) : FormTheme.borderDim,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isComplete ? Icons.check_box : Icons.check_box_outline_blank,
              color: isComplete ? _titlesColor : FormTheme.textMuted,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              isComplete
                  ? SheetStoryTitleProgressText.markIncomplete
                  : SheetStoryTitleProgressText.markComplete,
              style: TextStyle(
                color: isComplete ? _titlesColor : FormTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Multi step (stepper) ----------

  Widget _buildMultiStepTracker(String titleId, int completedSteps, int totalSteps) {
    final progress = completedSteps / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + counter
        Row(
          children: [
            Text(
              SheetStoryTitleProgressText.progressLabel,
              style: TextStyle(color: FormTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              SheetStoryTitleProgressText.stepProgress(completedSteps, totalSteps),
              style: TextStyle(
                color: completedSteps >= totalSteps ? _titlesColor : FormTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: FormTheme.surfaceDark,
            valueColor: AlwaysStoppedAnimation(
              completedSteps >= totalSteps ? Colors.green.shade400 : _titlesColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Step buttons
        Row(
          children: [
            _stepButton(
              icon: Icons.remove,
              enabled: completedSteps > 0,
              onTap: () => _setSteps(titleId, completedSteps - 1, totalSteps),
            ),
            const SizedBox(width: 8),
            // Step indicators
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: List.generate(totalSteps, (i) {
                  final done = i < completedSteps;
                  return GestureDetector(
                    onTap: () => _setSteps(titleId, done ? i : i + 1, totalSteps),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? _titlesColor.withAlpha(40) : FormTheme.surfaceDark,
                        border: Border.all(
                          color: done ? _titlesColor : FormTheme.borderDim,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: done
                            ? Icon(Icons.check, size: 14, color: _titlesColor)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: FormTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            _stepButton(
              icon: Icons.add,
              enabled: completedSteps < totalSteps,
              onTap: () => _setSteps(titleId, completedSteps + 1, totalSteps),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? _titlesColor.withAlpha(20) : FormTheme.surfaceDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? _titlesColor.withAlpha(80) : FormTheme.borderDim,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _titlesColor : FormTheme.textMuted,
        ),
      ),
    );
  }

  // ---------- "Add Title" button ----------

  Widget _buildAddTitleButton(String titleId, String titleName) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          widget.onTitleEarned?.call(titleId);
          setState(() {
            _earnedTitleIds.add(titleId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${SheetStoryTitleProgressText.titleAdded} $titleName'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        },
        icon: const Icon(Icons.emoji_events, size: 18),
        label: const Text(SheetStoryTitleProgressText.addTitle),
        style: ElevatedButton.styleFrom(
          backgroundColor: _titlesColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
