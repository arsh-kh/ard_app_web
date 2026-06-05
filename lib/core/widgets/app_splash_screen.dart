import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'modern_splash_loader.dart';

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: const ModernSplashLoader()
            .animate()
            .fadeIn(duration: 800.ms, curve: Curves.easeOut)
            .slideY(begin: 0.05, end: 0, duration: 800.ms, curve: Curves.easeOut),
      ),
    );
  }
}
