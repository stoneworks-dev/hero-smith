import '../../common/common_text.dart';

class SheetStorySkillsTabText {
  SheetStorySkillsTabText._();

  static const String skillsTitle = 'Skills';
  static const String addSkill = 'Add Skill';
  static const String addSkillDialogTitle = 'Add Skill';
  static const String searchSkillsLabel = 'Search skills';
  static const String noSkillsFound = 'No skills found';

  static const String skillAlreadyAdded = 'Skill already added';
  static const String skillOwnedElsewhere =
      'This skill is granted by another source and cannot be removed here.';
  static const String removeSkillTooltip = 'Remove skill';

  static const String emptyState =
      'No skills selected. Tap "Add Skill" to get started.';

  // Error messages
  static String failedToLoadSkills(Object e) => 'Failed to load skills: $e';
  static String failedToAddSkill(Object e) => 'Failed to add skill: $e';
  static String failedToRemoveSkill(Object e) => 'Failed to remove skill: $e';

  // Counts & labels
  static String skillsLearned(int count) => '$count skills learned';
  static const String pickFromList = 'Pick from list';

  // Custom skill creation
  static const String createCustomSkill = 'Create Custom Skill';
  static const String createCustomSkillTitle = 'Create Custom Skill';
  static const String skillNameLabel = 'Skill Name';
  static const String skillNameHint = 'Enter skill name';
  static const String skillNameRequired = 'Skill name is required';
  static const String skillGroupLabel = 'Group';
  static const String skillGroupHint = 'Select or enter a group';
  static const String skillDescriptionLabel = 'Description';
  static const String skillDescriptionHint = 'Enter skill description';
  static const String createButton = CommonText.create;
  static const String cancelButton = CommonText.cancel;
  static const String customGroup = 'custom';
}
