/// Text constants for stat edit dialogs.
library;

/// Text constants for stat edit dialogs.
abstract final class StatEditDialogsText {
  // Number edit dialog
  static const String numberEditTitlePrefix = 'Edit ';
  static const String numberEditCancelLabel = 'Cancel';
  static const String numberEditSaveLabel = 'Save';

  // XP edit dialog
  static const String xpEditTitle = 'Edit Experience';
  static const String xpEditCurrentLevelPrefix = 'Current Level: ';
  static const String xpEditExperienceLabel = 'Experience';
  static const String xpEditInsightsTitle = 'Insights';
  static const String xpEditCancelLabel = 'Cancel';
  static const String xpEditSaveLabel = 'Save';

  // Mod edit dialog
  static const String modEditTitlePrefix = 'Edit ';
  static const String modEditBasePrefix = 'Base: ';
  static const String modEditModificationLabel = 'Modification';
  static const String modEditHelperText = 'Positive adds, negative subtracts';
  static const String modEditCancelLabel = 'Cancel';
  static const String modEditSaveLabel = 'Save';

  // Stat edit dialog
  static const String statEditTitlePrefix = 'Edit ';
  static const String statEditBasePrefix = 'Base: ';
  static const String statEditModificationLabel = 'Modification';
  static const String statEditHelperText = 'Positive adds, negative subtracts';
  static const String statEditCancelLabel = 'Cancel';
  static const String statEditSaveLabel = 'Save';

  // Size edit dialog
  static const String sizeEditTitle = 'Edit Size';
  static const String sizeEditBasePrefix = 'Base: ';
  static const String sizeEditModificationLabel = 'Size Modification';
  static const String sizeEditHelperText = 'Positive adds, negative subtracts';
  static const String sizeEditCancelLabel = 'Cancel';
  static const String sizeEditSaveLabel = 'Save';

  // Size categories
  static const String sizeCategoryTiny = 'Tiny';
  static const String sizeCategorySmall = 'Small';
  static const String sizeCategoryMedium = 'Medium';
  static const String sizeCategoryLarge = 'Large';

  // Max vital breakdown dialog
  static const String maxVitalBreakdownTitleSuffix = ' Breakdown';
  static const String breakdownClassBaseLabel = 'Class Base';
  static const String breakdownEquipmentLabel = 'Equipment';
  static const String breakdownFeaturesLabel = 'Features';
  static const String breakdownChoiceModsLabel = 'Choice Mods';
  static const String breakdownManualModsLabel = 'Manual Mods';
  static const String breakdownTotalLabel = 'Total';
  static const String breakdownEditHint =
      'Tap "Edit Modifier" to adjust manual modifications.';
  static const String breakdownCloseLabel = 'Close';
  static const String breakdownEditModifierLabel = 'Edit Modifier';

  // Prompt dialogs
  static const String promptAmountLabel = 'Amount';
  static const String promptCancelLabel = 'Cancel';
  static const String promptApplyLabel = 'Apply';
  static const String promptApplyTempLabel = 'As Temp';

  // Dice roll dialog
  static const String diceRollTitleSuffix = ' Roll';
  static const String diceRolledDicePrefix = 'Rolled: ';
  static const String diceGainPrefix = 'Gain: +';
  static const String diceGainSuffix = ' resource';
  static const String diceRolledValuePrefix = 'Rolled: ';
  static const String diceRollValuesTitle = 'Roll Values:';
  static const String diceAcceptPrompt =
      'Accept this roll or choose a different value:';
  static const String diceCancelLabel = 'Cancel';
  static const String diceAcceptPrefix = 'Accept +';
}
