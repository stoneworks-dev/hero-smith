/// Stamina bar widget for visual stamina representation.
///
/// This file contains the dual-track stamina bar with clear zone visualization.
library;

import 'package:flutter/material.dart';

import '../../../core/repositories/hero_repository.dart';
import '../../../core/text/heroes_sheet/main_stats/stamina_bar_text.dart';
import '../../../core/theme/main_stats_theme.dart';
import 'hero_main_stats_models.dart';

/// Dual-track stamina bar with clear zone visualization:
/// - Top track: Current stamina with smooth blending gradient zones
/// - Bottom track: Temp HP (only shown when temp HP > 0)
/// - Labels positioned above for maximum clarity
class StaminaBarWidget extends StatelessWidget {
  const StaminaBarWidget({
    super.key,
    required this.stats,
    required this.staminaState,
  });

  final HeroMainStats stats;
  final StaminaState staminaState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxStamina = stats.staminaMaxEffective;
    final currentStamina = stats.staminaCurrent;
    final tempHp = stats.staminaTemp;
    final isDark = theme.brightness == Brightness.dark;

    if (maxStamina <= 0) {
      return const SizedBox(height: 48);
    }

    // Zone calculations
    final halfMax = maxStamina ~/ 2;
    final totalRange = maxStamina + halfMax;

    // Zone boundaries as ratios (for stops)
    final zeroRatio = halfMax / totalRange;
    final windedEndRatio = (halfMax + halfMax) / totalRange;

    // Current stamina position
    final clampedCurrent = currentStamina.clamp(-halfMax, maxStamina);
    final staminaRatio = (clampedCurrent + halfMax) / totalRange;

    // Temp HP ratio (capped at reasonable max)
    final tempRatio = tempHp > 0 ? (tempHp / maxStamina).clamp(0.0, 1.0) : 0.0;

    // Zone colors - vibrant and distinct
    final deadColor = MainStatsTheme.deadColor(theme.brightness);
    final dyingColor = MainStatsTheme.dyingColor(theme.brightness);
    final windedColor = MainStatsTheme.windedColor(theme.brightness);
    final healthyColor = MainStatsTheme.healthyColor(theme.brightness);
    final tempColor = MainStatsTheme.tempHpColor(theme.brightness);

    const barHeight = 18.0;
    final tempBarHeight = tempHp > 0 ? 14.0 : 0.0;
    // Total: labels(14) + gap(2) + bar(18) + gap(4) + temp(14) + padding(4)
    final totalHeight =
        14 + 2 + barHeight + (tempHp > 0 ? 4 + tempBarHeight + 4 : 0);

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final zeroX = width * zeroRatio;
          final windedEndX = width * windedEndRatio;
          final staminaX = (width * staminaRatio).clamp(0.0, width);
          final tempWidth = (width * tempRatio)
              .clamp(0.0, width - 40); // Leave room for label

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Labels row (above bar) ===
              SizedBox(
                height: 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Min label (left)
                    Positioned(
                      left: 0,
                      child: Text(
                        '-$halfMax',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: deadColor,
                        ),
                      ),
                    ),
                    // Zero label (centered at zero point)
                    Positioned(
                      left: zeroX,
                      child: Transform.translate(
                        offset: const Offset(-4, 0),
                        child: Text(
                          StaminaBarText.zeroLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    // Half max label (centered at winded/healthy boundary)
                    Positioned(
                      left: windedEndX,
                      child: Transform.translate(
                        offset: Offset(-('$halfMax'.length * 3.0), 0),
                        child: Text(
                          '$halfMax',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: windedColor,
                          ),
                        ),
                      ),
                    ),
                    // Max label (right)
                    Positioned(
                      right: 0,
                      child: Text(
                        '$maxStamina',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: healthyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),

              // === Main stamina bar ===
              SizedBox(
                height: barHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  child: Stack(
                    children: [
                      // === Smooth blending gradient background ===
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              deadColor.withOpacity(0.4),
                              deadColor.withOpacity(0.3),
                              windedColor.withOpacity(0.25),
                              windedColor.withOpacity(0.2),
                              healthyColor.withOpacity(0.2),
                              healthyColor.withOpacity(0.35),
                            ],
                            stops: [
                              0.0,
                              zeroRatio,
                              zeroRatio,
                              windedEndRatio,
                              windedEndRatio,
                              1.0,
                            ],
                          ),
                        ),
                      ),

                      // === Zone divider lines ===
                      // Zero point (prominent)
                      Positioned(
                        left: zeroX - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.surface.withOpacity(0.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Winded/Healthy boundary
                      Positioned(
                        left: windedEndX - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.surface.withOpacity(0.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // === Current stamina fill with horizontal gradient ===
                      if (staminaX > 0)
                        Positioned(
                          left: 0,
                          width: staminaX,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getStaminaFillGradient(
                                  staminaRatio,
                                  zeroRatio,
                                  windedEndRatio,
                                  deadColor,
                                  dyingColor,
                                  windedColor,
                                  healthyColor,
                                ),
                                stops: _getStaminaFillStops(
                                  staminaRatio,
                                  zeroRatio,
                                  windedEndRatio,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: staminaState.color.withOpacity(0.4),
                                  blurRadius: 3,
                                  offset: const Offset(1, 0),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // === Stamina position marker ===
                      if (staminaX > 2)
                        Positioned(
                          left: staminaX - 2,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                ),
                                BoxShadow(
                                  color: staminaState.color,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // === Temp HP bar (below main bar) ===
              if (tempHp > 0) ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: tempBarHeight,
                  child: Row(
                    children: [
                      // Temp HP fill bar
                      Flexible(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(tempBarHeight / 2),
                          child: Container(
                            width: tempWidth,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  tempColor,
                                  tempColor.withOpacity(0.6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: tempColor.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                StaminaBarText.tempLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Temp HP value label
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '+$tempHp',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tempColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Generates gradient colors for the stamina fill bar based on current position
  List<Color> _getStaminaFillGradient(
    double staminaRatio,
    double zeroRatio,
    double windedEndRatio,
    Color deadColor,
    Color dyingColor,
    Color windedColor,
    Color healthyColor,
  ) {
    // Build gradient that shows progression through zones (no dying zone)
    final colors = <Color>[];

    if (staminaRatio <= zeroRatio) {
      // Only in dead/negative zone - solid red
      colors.addAll([deadColor, deadColor.withOpacity(0.85)]);
    } else if (staminaRatio <= windedEndRatio) {
      // Dead to winded
      colors.addAll([deadColor, windedColor]);
    } else {
      // Full spectrum (dead -> winded -> healthy)
      colors.addAll([deadColor, windedColor, healthyColor]);
    }

    return colors;
  }

  /// Generates gradient stops for the stamina fill bar
  List<double>? _getStaminaFillStops(
    double staminaRatio,
    double zeroRatio,
    double windedEndRatio,
  ) {
    if (staminaRatio <= zeroRatio) {
      return null; // Simple 2-color gradient for negative zone
    } else if (staminaRatio <= windedEndRatio) {
      final zero = zeroRatio / staminaRatio;
      return [0.0, zero.clamp(0.0, 1.0)];
    } else {
      final zero = zeroRatio / staminaRatio;
      final windedEnd = windedEndRatio / staminaRatio;
      return [
        0.0,
        zero.clamp(0.0, 1.0),
        windedEnd.clamp(0.0, 1.0),
      ];
    }
  }
}
