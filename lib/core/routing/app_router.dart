import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_splash_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/inventory/product_form_screen.dart';
import '../../features/customers/customer_form_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/sales_pos/pos_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/dashboard/main_shell_layout.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/edit_profile_screen.dart';
import '../../features/settings/notifications_screen.dart';
import '../../features/settings/help_center_screen.dart';
import '../../features/settings/about_us_screen.dart';
import '../../features/settings/legal_screen.dart';
import '../../features/settings/contact_us_screen.dart';
import '../../features/settings/export_data_screen.dart';
import '../../features/settings/invite_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/customers/payment_history_screen.dart';
import '../../features/customers/history_hub_screen.dart';
import '../../features/orders/admin_orders_screen.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/pending_approval_screen.dart';
import '../../features/auth/business_setup_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/dashboard/audit_log_screen.dart';
import '../../features/settings/admin_users_screen.dart';
import '../../features/purchases/purchases_screen.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/onboarding_provider.dart';
import 'routes.dart';

Page _buildSlideTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final begin = isRtl ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
      final tween = Tween(
        begin: begin,
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

Page _buildFadeTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: child,
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen(authProvider, (_, next) => authListenable.value = next);

  final onboardingListenable = ValueNotifier<bool>(
    ref.read(onboardingProvider),
  );
  ref.listen(
    onboardingProvider,
    (_, next) => onboardingListenable.value = next,
  );

  return GoRouter(
    initialLocation: Routes.login,
    debugLogDiagnostics: true,
    refreshListenable: Listenable.merge([authListenable, onboardingListenable]),
    redirect: (context, state) {
      final auth = authListenable.value;
      final hasSeenOnboarding = onboardingListenable.value;

      if (auth.isInitializing) return Routes.splash;

      final isOnLogin = state.matchedLocation == Routes.login;
      final isOnSplash = state.matchedLocation == Routes.splash;
      final isOnPending = state.matchedLocation == Routes.pendingApproval;
      final isOnOnboarding = state.matchedLocation == Routes.onboarding;
      final isOnBusinessSetup = state.matchedLocation == Routes.businessSetup;

      // 1. If not seen onboarding, always go to onboarding.
      if (!hasSeenOnboarding) {
        return isOnOnboarding ? null : Routes.onboarding;
      }

      // 2. If seen onboarding, but still on the onboarding screen, redirect to login.
      if (hasSeenOnboarding && isOnOnboarding) {
        return Routes.login;
      }

      // 3. If not logged in, enforce login page.
      if (!auth.isLoggedIn && !isOnLogin) return Routes.login;

      if (auth.isLoggedIn) {
        if (auth.user?.businessId == null || auth.user!.businessId!.isEmpty) {
          if (!isOnBusinessSetup) return Routes.businessSetup;
          return null;
        }

        if (auth.user?.status == 'pending') {
          if (!isOnPending) return Routes.pendingApproval;
          return null;
        }

        if (auth.user?.status == 'banned') {
          Future.microtask(() => ref.read(authProvider.notifier).logout());
          return Routes.login;
        }

        if (isOnLogin || isOnSplash || isOnPending || isOnOnboarding || isOnBusinessSetup) {
          return Routes.adminDashboard;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const AppSplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: Routes.businessSetup,
        builder: (context, state) => const BusinessSetupScreen(),
      ),
      StatefulShellRoute(
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminDashboard,
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.bakeryCatalog,
                builder: (context, state) => const PosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.clientsOrders,
                builder: (context, state) =>
                    const CustomersScreen(isEmbedded: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inventory,
                builder: (context, state) =>
                    const InventoryScreen(isEmbedded: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AnimatedBranchContainer(
            navigationShell: navigationShell,
            children: children,
          );
        },
        builder: (context, state, navigationShell) {
          return MainShellLayout(navigationShell: navigationShell);
        },
      ),
      GoRoute(
        path: Routes.analytics,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const AnalyticsScreen()),
      ),
      GoRoute(
        path: Routes.auditLogs,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const AuditLogScreen()),
      ),
      GoRoute(
        path: Routes.adminOrders,
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['search'];
          return _buildSlideTransition(
            context,
            state,
            AdminOrdersScreen(initialSearchQuery: query),
          );
        },
      ),
      GoRoute(
        path: Routes.adminUsers,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const AdminUsersScreen()),
      ),

      GoRoute(
        path: Routes.productForm,
        pageBuilder: (context, state) {
          final productToEdit = state.extra as ProductEntity?;
          return _buildSlideTransition(
            context,
            state,
            ProductFormScreen(productToEdit: productToEdit),
          );
        },
      ),
      GoRoute(
        path: Routes.customerForm,
        pageBuilder: (context, state) {
          final customerToEdit = state.extra as CustomerEntity?;
          return _buildSlideTransition(
            context,
            state,
            CustomerFormScreen(customerToEdit: customerToEdit),
          );
        },
      ),
      GoRoute(
        path: Routes.customerSelection,
        pageBuilder: (context, state) => _buildSlideTransition(
          context,
          state,
          const CustomersScreen(isSelectionMode: true, isEmbedded: false),
        ),
      ),
      GoRoute(
        path: Routes.customerDetail,
        pageBuilder: (context, state) {
          final customer = state.extra as CustomerEntity;
          return _buildSlideTransition(
            context,
            state,
            CustomerDetailScreen(customer: customer),
          );
        },
      ),
      GoRoute(
        path: Routes.editProfile,
        pageBuilder: (context, state) =>
            _buildFadeTransition(context, state, const EditProfileScreen()),
      ),
      GoRoute(
        path: Routes.notifications,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const NotificationsScreen()),
      ),

      GoRoute(
        path: Routes.purchases,
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['search'];
          return _buildSlideTransition(
            context,
            state,
            PurchasesScreen(initialSearchQuery: query),
          );
        },
      ),
      GoRoute(
        path: Routes.paymentHistory,
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['search'];
          return _buildSlideTransition(
            context,
            state,
            PaymentHistoryScreen(initialSearchQuery: query),
          );
        },
      ),
      GoRoute(
        path: Routes.historyHub,
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['search'];
          return _buildSlideTransition(
            context,
            state,
            HistoryHubScreen(initialSearchQuery: query),
          );
        },
      ),
      GoRoute(
        path: Routes.helpCenter,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const HelpCenterScreen()),
      ),
      GoRoute(
        path: Routes.privacyPolicy,
        pageBuilder: (context, state) => _buildSlideTransition(
          context,
          state,
          const LegalScreen(documentType: LegalDocumentType.privacyPolicy),
        ),
      ),
      GoRoute(
        path: Routes.termsOfService,
        pageBuilder: (context, state) => _buildSlideTransition(
          context,
          state,
          const LegalScreen(documentType: LegalDocumentType.termsOfService),
        ),
      ),
      GoRoute(
        path: Routes.contactUs,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const ContactUsScreen()),
      ),
      GoRoute(
        path: Routes.exportData,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const ExportDataScreen()),
      ),
      GoRoute(
        path: Routes.aboutUs,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const AboutUsScreen()),
      ),
      GoRoute(
        path: Routes.invite,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const InviteScreen()),
      ),
    ],
  );
});

class AnimatedBranchContainer extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  const AnimatedBranchContainer({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer> {
  late PageController _pageController;
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex !=
        oldWidget.navigationShell.currentIndex) {
      _isProgrammaticScroll = true;
      _pageController
          .animateToPage(
            widget.navigationShell.currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            if (mounted) {
              _isProgrammaticScroll = false;
            }
          });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        if (_isProgrammaticScroll) return; // Prevent intermediate triggers

        if (index != widget.navigationShell.currentIndex) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        }
      },
      children: widget.children,
    );
  }
}
