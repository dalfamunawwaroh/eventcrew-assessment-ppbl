import 'package:flutter/material.dart';
import 'home_screen.dart';

/// Landing Page / Welcome Screen for EventCrew
///
/// - Modern, clean, professional layout
/// - Fully responsive with no overflow issues
/// - Theme-aware: respects app's Light/Dark mode
/// - This file is standalone — it does not modify any other files.

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Color palette
    final primaryBlue = const Color(0xFF1E3A8A);
    final accentMint = const Color(0xFF06B6D4);
    final accentGreen = const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== Hero Section =====
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue,
                      accentMint.withOpacity(0.9),
                      accentGreen.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + Greeting
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.event_available_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back!',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Ready to organize?',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Main heading
                    Text(
                      'EventCrew',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage events effortlessly.\nCollaborate with your team seamlessly.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CTA Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: accentMint.withOpacity(0.35), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Learn More',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ===== Features Section =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Features',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    _FeatureTileNew(
                      icon: Icons.people_alt_outlined,
                      title: 'Team Management',
                      subtitle: 'Assign roles and manage volunteers',
                      color: accentGreen,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _FeatureTileNew(
                      icon: Icons.calendar_today_outlined,
                      title: 'Event Planning',
                      subtitle: 'Create and schedule events easily',
                      color: accentMint,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _FeatureTileNew(
                      icon: Icons.checklist_outlined,
                      title: 'Task Tracking',
                      subtitle: 'Assign tasks and monitor progress',
                      color: accentGreen,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ===== Quick Start =====
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white12 : const Color(0xFFE6FFFA)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: accentGreen, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Start',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _QuickStepItem(1, 'Create your first event', theme),
                    const SizedBox(height: 8),
                    _QuickStepItem(2, 'Invite your team members', theme),
                    const SizedBox(height: 8),
                    _QuickStepItem(3, 'Assign and track tasks', theme),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ===== Footer =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                child: Center(
                  child: Text(
                    'EventCrew v1.0 • Manage Together\nBuilt for passionate event organizers',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.disabledColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feature tile widget with icon, title, and subtitle
class _FeatureTileNew extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _FeatureTileNew({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: color),
        ],
      ),
    );
  }
}

/// Quick step item for onboarding
class _QuickStepItem extends StatelessWidget {
  final int step;
  final String text;
  final ThemeData theme;

  const _QuickStepItem(this.step, this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

