import '../models/class_data.dart';
import '../models/subclass_models.dart';

/// Business helper for determining subclass, deity, and domain requirements
/// for a given class and level selection.
class SubclassService {
  const SubclassService();

  SubclassPlan buildPlan({
    required ClassData classData,
    required int selectedLevel,
  }) {
    String? subclassFeatureName;
    int subclassPickCount = 0;
    int deityPickCount = 0;
    int domainPickCount = 0;

    for (final level in classData.levels) {
      if (level.level > selectedLevel) continue;

      for (final feature in level.features) {
        final type = feature.type?.toLowerCase().trim();
        if (type == 'class_subclass') {
          subclassFeatureName ??= feature.name;
          final count = feature.count ?? 1;
          if (count > subclassPickCount) {
            subclassPickCount = count;
          }
        }

        if (feature.deity != null && feature.deity! > 0) {
          if (feature.deity! > deityPickCount) {
            deityPickCount = feature.deity!;
          }
        }
        if (feature.domain != null && feature.domain! > 0) {
          if (feature.domain! > domainPickCount) {
            domainPickCount = feature.domain!;
          }
        }
      }
    }

    if (subclassPickCount <= 0 && subclassFeatureName != null) {
      subclassPickCount = 1;
    }

    final classSlug = _normalizeClassSlug(
      classId: classData.classId,
      className: classData.name,
    );

    final combineDomainsAsSubclass = classSlug == 'conduit';

    return SubclassPlan(
      classSlug: classSlug,
      subclassFeatureName: subclassFeatureName,
      subclassPickCount: subclassPickCount,
      deityPickCount: deityPickCount,
      domainPickCount: domainPickCount,
      combineDomainsAsSubclass: combineDomainsAsSubclass,
    );
  }

  String _normalizeClassSlug({
    required String classId,
    required String className,
  }) {
    var normalized = classId.trim().toLowerCase();
    if (normalized.startsWith('class_')) {
      normalized = normalized.substring('class_'.length);
    }
    if (normalized.isNotEmpty) return normalized;
    return className.trim().toLowerCase().replaceAll(' ', '_');
  }
}
