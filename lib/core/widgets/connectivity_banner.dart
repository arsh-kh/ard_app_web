import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/connectivity_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/app_translations.dart';

class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnectedAsync = ref.watch(connectivityProvider);
    final lang = ref.watch(localeProvider).languageCode;
    
    // We assume connected until proven otherwise to avoid flashing on startup
    final isConnected = isConnectedAsync.value ?? true;

    return Directionality(
      textDirection: lang == 'en' ? TextDirection.ltr : TextDirection.rtl,
      child: Stack(
        children: [
          child,
          if (!isConnected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          Tr.t('noInternetConnection', lang),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: -1.0, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
