import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';

/// Data model representing a menu action option.
class MainMenuItem {
  const MainMenuItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.accentColor,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color accentColor;
}

/// Responsive Main Menu Screen providing access to all game modes and features.
/// Uses [Wrap] and [Flex] layout wrappers to reflow options smoothly on mobile and desktop.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    super.key,
    this.onNavigate,
  });

  /// Optional navigation callback for direct test orchestration.
  final void Function(String route)? onNavigate;

  static const List<MainMenuItem> menuItems = [
    MainMenuItem(
      id: 'quick_play',
      title: 'Quick Play',
      subtitle: 'Jump right into a classic word search puzzle',
      icon: Icons.play_arrow_rounded,
      route: AppRoutes.game,
      accentColor: Color(0xFF6366F1), // Indigo
    ),
    MainMenuItem(
      id: 'pack_library',
      title: 'Pack Library',
      subtitle: 'Explore themed word packs and collections',
      icon: Icons.auto_stories_rounded,
      route: AppRoutes.packLibrary,
      accentColor: Color(0xFF0EA5E9), // Sky
    ),
    MainMenuItem(
      id: 'learn_mode',
      title: 'Learn Mode',
      subtitle: 'Master vocabulary with spaced repetition',
      icon: Icons.school_rounded,
      route: AppRoutes.learnMode,
      accentColor: Color(0xFF10B981), // Emerald
    ),
    MainMenuItem(
      id: 'ai_generator',
      title: 'AI Generator',
      subtitle: 'Generate infinite dynamic custom puzzles',
      icon: Icons.auto_awesome_rounded,
      route: AppRoutes.aiGenerator,
      accentColor: Color(0xFFF59E0B), // Amber
    ),
    MainMenuItem(
      id: 'settings',
      title: 'Settings',
      subtitle: 'Audio, display themes, and preferences',
      icon: Icons.settings_rounded,
      route: AppRoutes.settings,
      accentColor: Color(0xFF8B5CF6), // Purple
    ),
  ];

  void _handleNavigation(BuildContext context, String route) {
    if (onNavigate != null) {
      onNavigate!(route);
      return;
    }

    try {
      GoRouter.of(context).go(route);
    } catch (_) {
      try {
        Navigator.of(context).pushNamed(route);
      } catch (_) {
        // Fallback for isolated widget testing environments
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.grid_4x4_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Word Search App',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;

            // Responsive item width calculation for Wrap reflow
            final double itemWidth;
            if (constraints.maxWidth < 600) {
              itemWidth = (constraints.maxWidth - 32).clamp(48.0, 520.0);
            } else if (constraints.maxWidth < 960) {
              itemWidth = ((constraints.maxWidth - 48) / 2).clamp(240.0, 420.0);
            } else {
              itemWidth = ((constraints.maxWidth - 64) / 3).clamp(260.0, 380.0);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header & Greeting Banner
                      _buildHeader(context, isWide),
                      const SizedBox(height: 28),

                      // Responsive Wrap Layout for Menu Options
                      Wrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: menuItems.map((item) {
                          return SizedBox(
                            width: itemWidth,
                            child: _MainMenuTile(
                              item: item,
                              onTap: () => _handleNavigation(context, item.route),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWide) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32.0 : 20.0,
        vertical: isWide ? 28.0 : 20.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.7),
            colorScheme.secondaryContainer.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Welcome to Word Search',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Explore, Learn & Play',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select a game mode or utility below to begin your word quest.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action Tile supporting strict minimum 48x48 dp touch target requirements,
/// keyboard accessibility, and interactive ripple feedback.
class _MainMenuTile extends StatelessWidget {
  const _MainMenuTile({
    required this.item,
    required this.onTap,
  });

  final MainMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Minimum touch target of 48x48 dp strictly enforced
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 48.0,
        minHeight: 48.0,
      ),
      child: Semantics(
        container: true,
        button: true,
        label: item.title,
        hint: item.subtitle,
        excludeSemantics: true,
        enabled: true,
        child: Material(
          color: colorScheme.surface,
          elevation: 1,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: InkWell(
            key: Key('menu_tile_${item.id}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  // Icon badge with distinctive accent color
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        color: item.accentColor,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title and Subtitle in flexible column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          key: Key('title_${item.id}'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Trailing navigation arrow
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
