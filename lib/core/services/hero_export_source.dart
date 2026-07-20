import '../db/app_database.dart' as db;

/// Immutable, hero-scoped read model used to build native export content and
/// its report from exactly the same database view.
class HeroExportSource {
  HeroExportSource({
    required this.hero,
    required List<db.HeroEntry> entries,
    required List<db.HeroConfigData> config,
    required List<db.HeroValue> values,
    required List<db.HeroDowntimeProject> projects,
    required List<db.HeroFollower> followers,
    required List<db.HeroProjectSource> sources,
    required List<db.HeroNote> notes,
    required List<db.HeroRetainer> retainers,
  })  : entries = _sorted(
          entries,
          (a, b) => _entryKey(a).compareTo(_entryKey(b)),
        ),
        config = _sorted(config, (a, b) => a.configKey.compareTo(b.configKey)),
        values = _sorted(values, (a, b) => a.key.compareTo(b.key)),
        projects = _sorted(projects, (a, b) => a.id.compareTo(b.id)),
        followers = _sorted(followers, (a, b) => a.id.compareTo(b.id)),
        sources = _sorted(sources, (a, b) => a.id.compareTo(b.id)),
        notes = _sorted(notes, (a, b) => a.id.compareTo(b.id)),
        retainers = _sorted(
          retainers,
          (a, b) => '${a.retainerComponentId}\u0000${a.name}'
              .compareTo('${b.retainerComponentId}\u0000${b.name}'),
        );

  final db.Heroe hero;
  final List<db.HeroEntry> entries;
  final List<db.HeroConfigData> config;
  final List<db.HeroValue> values;
  final List<db.HeroDowntimeProject> projects;
  final List<db.HeroFollower> followers;
  final List<db.HeroProjectSource> sources;
  final List<db.HeroNote> notes;
  final List<db.HeroRetainer> retainers;

  static List<T> _sorted<T>(List<T> rows, int Function(T, T) compare) {
    final sorted = List<T>.of(rows)..sort(compare);
    return List.unmodifiable(sorted);
  }

  static String _entryKey(db.HeroEntry entry) =>
      '${entry.entryType}\u0000${entry.entryId}\u0000${entry.sourceType}'
      '\u0000${entry.sourceId}\u0000${entry.gainedBy}\u0000${entry.payload ?? ''}';
}

/// Reads every hero-owned table once. Callers provide transaction scope so a
/// normalised export can read a coherent view and then roll its repairs back.
class HeroExportSourceLoader {
  HeroExportSourceLoader(this._db);

  final db.AppDatabase _db;

  Future<HeroExportSource?> load(String heroId) async {
    final hero = await (_db.select(_db.heroes)
          ..where((table) => table.id.equals(heroId)))
        .getSingleOrNull();
    if (hero == null) return null;

    final rows = await Future.wait([
      (_db.select(_db.heroEntries)
            ..where((table) => table.heroId.equals(heroId)))
          .get(),
      (_db.select(_db.heroConfig)
            ..where((table) => table.heroId.equals(heroId)))
          .get(),
      _db.getHeroValues(heroId),
      (_db.select(_db.heroDowntimeProjects)
            ..where((table) => table.heroId.equals(heroId)))
          .get(),
      (_db.select(_db.heroFollowers)
            ..where((table) => table.heroId.equals(heroId)))
          .get(),
      (_db.select(_db.heroProjectSources)
            ..where((table) => table.heroId.equals(heroId)))
          .get(),
      (_db.select(_db.heroNotes)
            ..where((table) => table.heroId.equals(heroId)))
          .get(),
      (_db.select(_db.heroRetainers)
            ..where((table) => table.heroId.equals(heroId)))
          .get(),
    ]);

    return HeroExportSource(
      hero: hero,
      entries: rows[0] as List<db.HeroEntry>,
      config: rows[1] as List<db.HeroConfigData>,
      values: rows[2] as List<db.HeroValue>,
      projects: rows[3] as List<db.HeroDowntimeProject>,
      followers: rows[4] as List<db.HeroFollower>,
      sources: rows[5] as List<db.HeroProjectSource>,
      notes: rows[6] as List<db.HeroNote>,
      retainers: rows[7] as List<db.HeroRetainer>,
    );
  }
}
