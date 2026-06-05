import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'flour_fill_loader.dart';

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The core animated loading component
            const FlourFillLoader()
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .slideY(begin: 0.1, end: 0, duration: 800.ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
