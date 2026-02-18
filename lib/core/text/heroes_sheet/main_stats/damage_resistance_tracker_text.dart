import '../../common/common_text.dart';

class DamageResistanceTrackerText {
  static const String saveErrorPrefix = 'Error saving resistances: ';
  static const String errorLoadingResistancesPrefix =
      'Error loading resistances: ';
  static const String errorRetryLabel = 'Retry';

  static const String addDamageTypeDialogTitle = 'Add Damage Type';
  static const String addDamageTypeCancelLabel = CommonText.cancel;
  static const String addDamageTypeCustomLabel = 'Custom...';

  static const String customDamageTypeDialogTitle = 'Custom Damage Type';
  static const String customDamageTypeNameLabel = 'Damage Type Name';
  static const String customDamageTypeNameHint = 'e.g., Radiant';
  static const String customDamageTypeCancelLabel = CommonText.cancel;
  static const String customDamageTypeAddLabel = CommonText.add;

  static const String editResistanceTitlePrefix = 'Edit ';
  static const String netResultPrefix = 'Net Result: ';
  static const String totalImmunityPrefix = 'Total Immunity: ';
  static const String totalWeaknessPrefix = 'Total Weakness: ';
  static const String sourcesLabel = 'Sources:';
  static const String baseImmunityLabel = 'Base Immunity';
  static const String baseWeaknessLabel = 'Base Weakness';
  static const String editResistanceCancelLabel = CommonText.cancel;
  static const String editResistanceSaveLabel = CommonText.save;

  static const String netImmunityPrefix = 'Immunity ';
  static const String netWeaknessPrefix = 'Weakness ';
  static const String netNoneLabel = CommonText.none;

  static const String damageResistancesTitle = 'Damage Resistances';
  static const String addDamageTypeTooltip = 'Add damage type';
  static const String damageResistancesFormulaLabel =
      'Immunity - Weakness = Net Value';
  static const String emptyResistancesLabel = 'No damage resistances tracked';
  static const String removeDamageTypeTooltip = CommonText.remove;
}
