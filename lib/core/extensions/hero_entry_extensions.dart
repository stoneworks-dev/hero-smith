import '../db/app_database.dart' as db;
import 'package:collection/collection.dart';

extension HeroEntryListX on List<db.HeroEntry> {
  List<db.HeroEntry> ofType(String entryType) =>
      where((e) => e.entryType == entryType).toList();

  Map<String, List<db.HeroEntry>> groupedBySource() =>
      groupBy(this, (e) => '${e.sourceType}:${e.sourceId}'.trim());
}
