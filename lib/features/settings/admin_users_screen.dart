import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/locale_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_entity.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/business_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/widgets/initials_avatar.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  late final _searchFocus = SelectAllFocusNode(controller: _searchCtrl);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;

    final titleText = Tr.t('manageUsersTitle', lang);

    final userRepo = ref.watch(userRepositoryProvider);
    final currentUser = ref.watch(authProvider).user;

    final businessAsync = ref.watch(currentBusinessEntityProvider);
    final business = businessAsync.valueOrNull;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              business != null ? 10 : 10,
              20,
              20,
            ),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: Tr.t('searchUsers', lang),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.2),

          Expanded(
            child: StreamBuilder<List<UserEntity>>(
              stream: userRepo.watchAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CustomLoader());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${Tr.t('errorPrefix', lang)}${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  );
                }

                final users = snapshot.data ?? [];
                final filteredUsers = users
                    .where(
                      (u) =>
                          u.name.toLowerCase().contains(_searchQuery) ||
                          (u.email ?? '').toLowerCase().contains(_searchQuery),
                    )
                    .toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Tr.t('noUsersFound', lang),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isBanned = user.status == 'banned';
                    final isPending = user.status == 'pending';
                    final isCurrentUser = user.id == currentUser?.id;

                    final Color statusColor = isBanned
                        ? theme.colorScheme.error
                        : (isPending
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                )
                              : theme.colorScheme.primary);

                    return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: theme.colorScheme.surface,
                          elevation: isDark ? 0 : 4,
                          shadowColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: statusColor.withValues(
                                alpha: isBanned ? 0.3 : 0,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Stack(
                              children: [
                                InitialsAvatar(
                                  text: user.name,
                                  imageUrl: user.imageUrl,
                                  radius: 24,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.scaffoldBackgroundColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (isPending)
                                  Container(
                                    margin: const EdgeInsetsDirectional.only(end: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      Tr.t('statusPending', lang),
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (user.role == 'admin')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      Tr.t('roleAdmin', lang),
                                      style: TextStyle(
                                        color: theme.colorScheme.surface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                user.email ??
                                    user.phone ??
                                    Tr.t('noContactDetails', lang),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            trailing: isCurrentUser
                                ? null
                                : PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (value) async {
                                      if (value == 'ban') {
                                        await userRepo.updateUserStatus(
                                          user.id,
                                          'banned',
                                        );
                                      } else if (value == 'activate') {
                                        await userRepo.updateUserStatus(
                                          user.id,
                                          'active',
                                        );
                                      } else if (value == 'make_admin') {
                                        await userRepo.updateUserRole(
                                          user.id,
                                          'admin',
                                        );
                                      } else if (value == 'make_user') {
                                        await userRepo.updateUserRole(
                                          user.id,
                                          'user',
                                        );
                                      } else if (value == 'delete') {
                                        await userRepo.deleteUser(user.id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      if (isBanned ||
                                          isPending ||
                                          user.status == null)
                                        PopupMenuItem(
                                          value: 'activate',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle_outline,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(Tr.t('activateUser', lang)),
                                            ],
                                          ),
                                        ),
                                      if (!isBanned)
                                        PopupMenuItem(
                                          value: 'ban',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.block, size: 20),
                                              const SizedBox(width: 8),
                                              Text(Tr.t('banUser', lang)),
                                            ],
                                          ),
                                        ),
                                      if (user.role != 'admin')
                                        PopupMenuItem(
                                          value: 'make_admin',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons
                                                    .admin_panel_settings_outlined,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(Tr.t('makeAdmin', lang)),
                                            ],
                                          ),
                                        ),
                                      if (user.role == 'admin')
                                        PopupMenuItem(
                                          value: 'make_user',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.person_outline,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(Tr.t('removeAdmin', lang)),
                                            ],
                                          ),
                                        ),
                                      const PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(Tr.t('deleteAccount', lang)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 50 * index))
                        .slideX(begin: 0.1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
