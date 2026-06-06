import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_splash_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/inventory/product_form_screen.dart';
import '../../features/customers/customer_form_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/clients_orders_screen.dart';
import '../../features/orders/bakery_catalog_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/dashboard/main_shell_layout.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/edit_profile_screen.dart';
import '../../features/settings/notifications_screen.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/pending_approval_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/dashboard/audit_log_screen.dart';
import '../../features/settings/admin_users_screen.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../core/providers/auth_provider.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen(authProvider, (_, next) => authListenable.value = next);

  return GoRouter(
    initialLocation: Routes.login,
    debugLogDiagnostics: true,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = authListenable.value;
      if (auth.isLoading) return Routes.splash;
      
      final isOnLogin = state.matchedLocation == Routes.login;
      final isOnSplash = state.matchedLocation == Routes.splash;
      final isOnPending = state.matchedLocation == Routes.pendingApproval;
      
      if (!auth.isLoggedIn && !isOnLogin) return Routes.login;
      
      if (auth.isLoggedIn) {
        if (auth.user?.status == 'pending') {
          if (!isOnPending) return Routes.pendingApproval;
          return null;
        }

        if (auth.user?.status == 'banned') {
          Future.microtask(() => ref.read(authProvider.notifier).logout());
          return Routes.login;
        }

        if (isOnLogin || isOnSplash || isOnPending) {
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
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
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
                builder: (context, state) => const BakeryCatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.clientsOrders,
                builder: (context, state) => const ClientsOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inventory,
                builder: (context, state) => const InventoryScreen(),
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
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: Routes.auditLogs,
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: Routes.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),

      GoRoute(
        path: Routes.productForm,
        builder: (context, state) {
          final productToEdit = state.extra as ProductEntity?;
          return ProductFormScreen(productToEdit: productToEdit);
        },
      ),
      GoRoute(
        path: Routes.customerForm,
        builder: (context, state) {
          final customerToEdit = state.extra as CustomerEntity?;
          return CustomerFormScreen(customerToEdit: customerToEdit);
        },
      ),
      GoRoute(
        path: Routes.customerDetail,
        builder: (context, state) {
          final customer = state.extra as CustomerEntity;
          return CustomerDetailScreen(customer: customer);
        },
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationsScreen(),
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
  State<AnimatedBranchContainer> createState() => _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer> {
  late PageController _pageController;
  bool _isNavigatingFromBottomBar = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.navigationShell.currentIndex);
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex != widget.navigationShell.currentIndex) {
      // Only animate if the PageController is not already on that page (avoids snapping during swipes)
      if (_pageController.page?.round() != widget.navigationShell.currentIndex) {
        // Sync PageController with BottomNav taps
        _isNavigatingFromBottomBar = true;
        _pageController.animateToPage(
          widget.navigationShell.currentIndex,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutExpo,
        ).then((_) {
          if (mounted) {
            setState(() {
              _isNavigatingFromBottomBar = false;
            });
          }
        });
      }
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
      onPageChanged: (index) {
        // Sync BottomNav with Swipe gesture ONLY if not jumping from bottom nav
        if (!_isNavigatingFromBottomBar && index != widget.navigationShell.currentIndex) {
          widget.navigationShell.goBranch(index);
        }
      },
      children: widget.children,
    );
  }
}

