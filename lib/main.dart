import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/text/main_text.dart';
import 'core/theme/app_icon.dart';
import 'core/theme/app_icon_data.dart';
import 'core/theme/app_icons.dart';
import 'core/theme/navigation_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/main_pages/heroes_page.dart';
import 'features/main_pages/strife/strife_page.dart';
import 'features/main_pages/story/story_page.dart';
import 'features/main_pages/gear/gear_page.dart';
import 'features/main_pages/downtime/downtime_projects_page.dart';
import 'features/splash/splash_screen.dart';
import 'core/db/providers.dart';
import 'widgets/update_dialog.dart';

void main() {
  runApp(const ProviderScope(child: HeroSmithApp()));
}

class HeroSmithApp extends StatelessWidget {
  const HeroSmithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MainText.appTitle,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const SplashWrapper(),
    );
  }
}

/// Wrapper that shows splash screen during initialization, then transitions to main app.
class SplashWrapper extends ConsumerStatefulWidget {
  const SplashWrapper({super.key});

  @override
  ConsumerState<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends ConsumerState<SplashWrapper> {
  bool _showSplash = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization until after first frame to avoid lifecycle edge-cases
    // around didChangeDependencies/first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        _initializeApp();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _initializeApp() async {
    // Skip splash in test mode (when auto-seed is disabled)
    final shouldShowSplash = ref.read(autoSeedEnabledProvider);
    if (!shouldShowSplash) {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
      return;
    }
    
    // Minimum splash duration for branding visibility
    await Future.delayed(const Duration(seconds: 2));

    // Seed DB while the splash screen is showing so the Heroes page doesn't
    // appear frozen during heavy first-run initialization.
    // Add timeout to prevent infinite hang if seeding gets stuck.
    try {
      await ref.read(seedOnStartupProvider.future).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (kDebugMode) debugPrint('Startup seed timed out after 30 seconds');
        },
      );
    } catch (e) {
      // Best-effort: allow app to continue; downstream pages can surface errors.
      if (kDebugMode) debugPrint('Startup seed failed: $e');
    }

    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: () {
        setState(() {
          _showSplash = false;
        });
      });
    }
    return const UpdateChecker(child: RootNavPage());
  }
}

class RootNavPage extends ConsumerStatefulWidget {
  const RootNavPage({super.key});

  @override
  ConsumerState<RootNavPage> createState() => _RootNavPageState();
}

class _RootNavPageState extends ConsumerState<RootNavPage> {
  int _index = 0;

  static const _pages = <Widget>[
    HeroesPage(),
    StrifePage(),
    StoryPage(),
    GearPage(),
    DowntimeProjectsPage(),
  ];

  // @override
  // void initState() {
  //   super.initState();
  //   // Print database path once (skipped in tests where auto-seed is disabled).
  //   final shouldShow = ref.read(autoSeedEnabledProvider);
  //   if (shouldShow) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) async {
  //       final path = await AppDatabase.databasePath();
  //       debugPrint('Hero Smith DB path: $path');
  //       if (!mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('DB path: $path'), duration: const Duration(seconds: 5)),
  //       );
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: NavigationTheme.navBarBackground,
          boxShadow: NavigationTheme.navBarShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: NavIcons.heroes,
                  activeIcon: NavIcons.heroesActive,
                  label: MainText.heroes,
                  color: NavigationTheme.heroesColor,
                  isSelected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: NavIcons.strife,
                  activeIcon: NavIcons.strifeActive,
                  label: MainText.strife,
                  color: NavigationTheme.strifeColor,
                  isSelected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: NavIcons.story,
                  activeIcon: NavIcons.storyActive,
                  label: MainText.story,
                  color: NavigationTheme.storyColor,
                  isSelected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: NavIcons.gear,
                  activeIcon: NavIcons.gearActive,
                  label: MainText.gear,
                  color: NavigationTheme.gearColor,
                  isSelected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
                _NavItem(
                  icon: NavIcons.downtime,
                  activeIcon: NavIcons.downtimeActive,
                  label: MainText.downtime,
                  color: NavigationTheme.downtimeColor,
                  isSelected: _index == 4,
                  onTap: () => setState(() => _index = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppIconData icon;
  final AppIconData activeIcon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSelected ? color : NavigationTheme.inactiveColor;
    final displayIcon = isSelected ? activeIcon : icon;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected 
            ? NavigationTheme.selectedNavItemDecoration(color)
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              displayIcon,
              color: activeColor,
              size: NavigationTheme.navBarIconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: NavigationTheme.navLabelStyle(
                color: activeColor,
                isSelected: isSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
