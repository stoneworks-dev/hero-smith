import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/navigation_theme.dart';
import '../../../core/text/heroes_sheet/downtime/hero_downtime_tracking_page_text.dart';
import '../../../widgets/downtime/downtime_tabs.dart';
import 'sheet_downtime/projects_list_tab.dart';
import 'sheet_downtime/followers_tab.dart';
import 'sheet_downtime/sources_tab.dart';

/// Accent color for downtime page
const Color _downtimeColor = NavigationTheme.downtimeColor;

/// Main page for managing hero downtime projects
class HeroDowntimeTrackingPage extends ConsumerStatefulWidget {
  const HeroDowntimeTrackingPage({
    super.key,
    required this.heroId,
    required this.heroName,
    this.isEmbedded = false,
  });

  final String heroId;
  final String heroName;
  final bool isEmbedded;

  @override
  ConsumerState<HeroDowntimeTrackingPage> createState() =>
      _HeroDowntimeTrackingPageState();
}

class _HeroDowntimeTrackingPageState
    extends ConsumerState<HeroDowntimeTrackingPage> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    // If embedded, return content with top tab navigation
    if (widget.isEmbedded) {
      return DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Header with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _downtimeColor.withAlpha(38),
                    _downtimeColor.withAlpha(10),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _downtimeColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: _downtimeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Downtime',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.event_note, color: _downtimeColor),
                      tooltip:
                          HeroDowntimeTrackingPageText.viewEventTablesTooltip,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EventsPageScaffold(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Tab bar
            Container(
              color: NavigationTheme.cardBackgroundDark,
              child: TabBar(
                labelColor: _downtimeColor,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: _downtimeColor,
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.assignment),
                    text: HeroDowntimeTrackingPageText.tabProjectsLabel,
                  ),
                  Tab(
                    icon: Icon(Icons.people),
                    text: HeroDowntimeTrackingPageText.tabFollowersLabel,
                  ),
                  Tab(
                    icon: Icon(Icons.book),
                    text: HeroDowntimeTrackingPageText.tabSourcesLabel,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: NavigationTheme.navBarBackground,
                child: TabBarView(
                  children: [
                    ProjectsListTab(heroId: widget.heroId),
                    FollowersTab(heroId: widget.heroId),
                    SourcesTab(heroId: widget.heroId),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: NavigationTheme.navBarBackground,
      appBar: AppBar(
        backgroundColor: NavigationTheme.cardBackgroundDark,
        foregroundColor: Colors.white,
        title: Text('${widget.heroName} - Downtime Projects'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note, color: _downtimeColor),
            tooltip: HeroDowntimeTrackingPageText.viewEventTablesTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EventsPageScaffold(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          ProjectsListTab(heroId: widget.heroId),
          FollowersTab(heroId: widget.heroId),
          SourcesTab(heroId: widget.heroId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: NavigationTheme.cardBackgroundDark,
        selectedItemColor: _downtimeColor,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: HeroDowntimeTrackingPageText.bottomNavProjectsLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: HeroDowntimeTrackingPageText.bottomNavFollowersLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: HeroDowntimeTrackingPageText.bottomNavSourcesLabel,
          ),
        ],
      ),
    );
  }
}
