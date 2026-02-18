import '../../common/common_text.dart';

class ProjectRollDialogText {
  static const String dialogTitle = 'Roll for Project';
  static const String cancelButtonLabel = CommonText.cancel;
  static const String heroSectionTitle = 'Hero Roll';
  static const String heroRerollButtonLabel = 'Re-roll (Reset)';
  static const String heroRollButtonLabel = 'Roll 2d10';
  static const String heroInitialRollLabel = 'Initial Roll:';
  static const String heroBreakthroughButtonLabel = 'Roll Breakthrough!';
  static const String heroRollTotalLabel = 'Roll Total: ';
  static const String heroBreakthroughBadgeLabel = '19+!';
  static const String heroEdgeLabel = 'Edge';
  static const String heroBaneLabel = 'Bane';
  static const String heroSkillLabel = 'Skill';
  static const String heroCharacteristicHint = 'Select characteristic';
  static const String heroCharacteristicNoneLabel = CommonText.none;
  static const String followerSectionTitle = 'Follower Contributions';
  static const String noFollowersLabel = 'No followers available';
  static const String followerRerollButtonLabel = 'Re-roll';
  static const String followerRollButtonLabel = 'Roll';
  static const String followerRollPrefixLabel = 'Roll: ';
  static const String followerBreakthroughButtonLabel = 'Breakthrough!';
  static const String followerEdgeLabel = 'Edge';
  static const String followerBaneLabel = 'Bane';
  static const String followerSkillLabel = 'Skill';
  static const String followerCharacteristicNoneLabel = CommonText.none;
  static const String totalPointsLabel = 'Total Points: ';
  static String addPointsButton(int total) => 'Add $total Points';
  static String breakthroughLabel(int index) => 'Breakthrough $index:';
  static String characteristicLabel(int multiplier) =>
      'Characteristic${multiplier > 1 ? ' (x$multiplier)' : ''}:';
  static String errorLoadingFollowers(Object e) =>
      'Error loading followers: $e';
  static String followerCharacteristicLabel(int multiplier) =>
      'Characteristic${multiplier > 1 ? ' (x$multiplier)' : ''}';
}
