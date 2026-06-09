import 'package:flutter/material.dart';
import 'landing_page.dart';

/// Splash Screen for EventCrew
///
/// - Full-screen display with elegant gradient background
/// - Displays on app launch with a 3-second timer
/// - Features aesthetic branding, logo, and loading indicator
/// - Automatically navigates to LandingPage after 3 seconds using pushReplacement
/// - This file is standalone — it does not modify any other files

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // ===== Animation Setup =====
    // Creates a smooth fade-in animation for the logo
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();

    // ===== Timer Logic =====
    // Start a 3-second delayed navigation to LandingPage
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // pushReplacement ensures user cannot navigate back to splash screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove default scaffolding padding for full-screen effect
      extendBodyBehindAppBar: true,
      body: Container(
        // ===== Full-Screen Background Gradient =====
        // Navy blue to mint/teal gradient covering entire screen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E3A8A), // Deep Navy Blue
              Color(0xFF06B6D4), // Cyan/Mint
              Color(0xFF10B981), // Fresh Mint Green
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ===== Top Decorative Element =====
            Opacity(
              opacity: 0.15,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ===== Center Section (Logo & Branding) =====
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ===== Animated Logo Container =====
                  FadeTransition(
                    opacity: _animationController,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0)
                          .animate(_animationController),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.event_available,
                          color: Colors.white,
                          size: 64,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== App Name =====
                  // Large, bold, white text with glow effect for strong branding
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Text(
                      'EventCrew',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontSize: 48,
                          ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== Tagline =====
                  Text(
                    'Manage Together',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.0,
                          fontSize: 16,
                        ),
                  ),

                  const SizedBox(height: 8),

                  // ===== Extended Tagline =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Built for Passionate Event Organizers',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withOpacity(0.65),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== Bottom Section (Loading Indicator) =====
            Container(
              padding: const EdgeInsets.only(bottom: 64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ===== Animated Loading Indicator =====
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.9),
                      ),
                      strokeWidth: 3.5,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== Loading Text =====
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

