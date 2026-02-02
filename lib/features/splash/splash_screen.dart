import 'package:flutter/material.dart';

import '../../core/theme/splash_theme.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  // App's dark gray background color
  static const Color _backgroundColor = SplashTheme.background;
  // Accent color for loading indicator
  static const Color _accentColor = SplashTheme.accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Powered by Draw Steel image - centered with subtle glow
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // Subtle warm glow effect
                  BoxShadow(
                    color: _accentColor.withOpacity(0.15),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Image.asset(
                'data/images/loading_screen/powered_by_draw_steel_verticle.webp',
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator with app accent color
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: _accentColor,
                strokeWidth: 3,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
