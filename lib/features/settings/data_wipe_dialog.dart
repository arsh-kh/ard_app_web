import 'package:flutter/material.dart';
import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/services/data_wipe_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/heavy_ios_button.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/providers/notification_providers.dart';

class DataWipeDialog extends ConsumerStatefulWidget {
  const DataWipeDialog({super.key});

  @override
  ConsumerState<DataWipeDialog> createState() => _DataWipeDialogState();
}

class _DataWipeDialogState extends ConsumerState<DataWipeDialog> {
  bool _isWiping = false;
  final TextEditingController _confirmController = TextEditingController();
  late final _confirmFocus = SelectAllFocusNode(controller: _confirmController);

  bool _isUnderstood = false;

  @override
  void dispose() {
    _confirmController.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _performWipe() async {
    final lang = ref.read(localeProvider).languageCode;
    if (_confirmController.text.trim() != 'DELETE' || !_isUnderstood) {
      AppFeedback.showError(context, Tr.t('typeDeleteToConfirm', lang));
      return;
    }

    setState(() => _isWiping = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null || user.role != 'admin') {
        throw Exception(Tr.t('error_unauthorized', lang));
      }

      final wipeService = ref.read(dataWipeServiceProvider);
      await wipeService.wipeAllData(
        wipeUsers: false,
        currentAdminId: user.id,
        businessId: user.businessId!,
      );

      // Clear local notifications
      ref.read(notificationProvider.notifier).clearAll();

      if (mounted) {
        AppFeedback.showSuccess(context, Tr.t('dataWipedSuccess', lang));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isWiping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    const dangerColor = Color(0xFFD32F2F);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: dangerColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: dangerColor.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_rounded,
              color: dangerColor,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              Tr.t('wipeAllDataTitle', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: dangerColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              Tr.t('wipeAllDataWarning', lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lang == 'ku'
                  ? 'بۆ دڵنیابوونەوە لەم کردارە، تکایە وشەی "DELETE" بە پیتی گەورە (Capital) بنووسە لە خوارەوە:'
                  : lang == 'ar'
                  ? 'للتأكيد، يرجى كتابة كلمة "DELETE" بأحرف كبيرة (Capital) أدناه:'
                  : 'To confirm, please type the word "DELETE" in ALL CAPS below:',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              focusNode: _confirmFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_confirmController.text.trim() == 'DELETE' && _isUnderstood) {
                  _performWipe();
                }
              },
              decoration: InputDecoration(
                hintText: 'DELETE',
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _isUnderstood,
                    activeColor: dangerColor,
                    onChanged: (val) {
                      setState(() => _isUnderstood = val ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang == 'ku'
                        ? 'تێدەگەم کە ئەمە کردارێکی هەمیشەییە و ناتوانرێت بگەڕێندرێتەوە.'
                        : lang == 'ar'
                        ? 'أدرك أن هذا الإجراء دائم ولا يمكن التراجع عنه.'
                        : 'I understand that this action is permanent and cannot be undone.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_isWiping)
              const Center(child: CustomLoader())
            else
              Column(
                children: [
                  HeavyIOSButton(
                    label: Tr.t('wipeAllDataBtn', lang),
                    icon: Icons.delete_forever_rounded,
                    onTap:
                        _confirmController.text.trim() == 'DELETE' &&
                            _isUnderstood
                        ? () => _performWipe()
                        : () {},
                    color:
                        _confirmController.text.trim() == 'DELETE' &&
                            _isUnderstood
                        ? dangerColor
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      Tr.t('cancelBtn', lang),
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
