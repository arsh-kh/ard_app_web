import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/inventory/inventory_screen.dart';
import '../../features/inventory/product_form_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/customers/customer_form_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/clients_orders_screen.dart';
import '../../features/orders/bakery_catalog_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/dashboard/main_shell_layout.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../data/local_database/database.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.adminDashboard, // Testing as Admin
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login Screen - TODO')),
        ),
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
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        builder: (context, state, navigationShell) {
          return MainShellLayout(navigationShell: navigationShell);
        },
      ),
      GoRoute(
        path: Routes.analytics,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const AnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.productForm,
        pageBuilder: (context, state) {
          final productToEdit = state.extra as ProductEntity?;
          return buildSlideTransitionPage(
            state: state,
            child: ProductFormScreen(productToEdit: productToEdit),
          );
        },
      ),
      GoRoute(
        path: Routes.customerForm,
        pageBuilder: (context, state) {
          final customerToEdit = state.extra as CustomerEntity?;
          return buildSlideTransitionPage(
            state: state,
            child: CustomerFormScreen(customerToEdit: customerToEdit),
          );
        },
      ),
      GoRoute(
        path: Routes.customerDetail,
        pageBuilder: (context, state) {
          final customer = state.extra as CustomerEntity;
          return buildSlideTransitionPage(
            state: state,
            child: CustomerDetailScreen(customer: customer),
          );
        },
      ),
    ],
  );
});

CustomTransitionPage<T> buildSlideTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.24, 0.0),
          ).animate(CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          )),
          child: child,
        ),
      );
    },
  );
}

class AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<AnimatedBranchContainer> createState() => _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.children.length, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
        value: index == widget.currentIndex ? 1.0 : 0.0,
      );
    });
    _animations = _controllers.map((c) {
      return CurvedAnimation(
        parent: c,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
    }).toList();
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (index) {
        final child = widget.children[index];
        final animation = _animations[index];
        
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final isVisible = animation.value > 0.0;
            
            Offset slideOffset;
            if (_previousIndex != null) {
              final bool isMovingForward = widget.currentIndex > _previousIndex!;
              if (index == widget.currentIndex) {
                slideOffset = isMovingForward ? const Offset(0.04, 0.0) : const Offset(-0.04, 0.0);
              } else if (index == _previousIndex) {
                slideOffset = isMovingForward ? const Offset(-0.04, 0.0) : const Offset(0.04, 0.0);
              } else {
                slideOffset = Offset.zero;
              }
            } else {
              slideOffset = Offset.zero;
            }

            return Offstage(
              offstage: !isVisible && index != widget.currentIndex,
              child: TickerMode(
                enabled: isVisible || index == widget.currentIndex,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: slideOffset,
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
