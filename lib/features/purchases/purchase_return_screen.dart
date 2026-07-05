import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/providers/purchase_return_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/utils/app_translations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/formatters.dart';


import '../../data/models/purchase_entity.dart';
import '../../data/models/purchase_item_entity.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/purchase_return_entity.dart';
import '../../data/models/purchase_return_item_entity.dart';
import '../../data/repositories/return_repository.dart'; // For DebtCalculation

class _ReturnLine {
  final PurchaseItemEntity purchaseItem;
  final ProductEntity? product;
  final TextEditingController qtyController;
  final double correctionRatio;

  double get originalQty => purchaseItem.quantity;
  double get maxReturnQty =>
      purchaseItem.quantity - purchaseItem.returnedQuantity;
  double get unitPrice => purchaseItem.unitPrice * correctionRatio;

  String productName(String lang) {
    final name = product?.name;
    if (name != null && name.isNotEmpty) return name;
    return purchaseItem.productId.length > 20
        ? '${Tr.t('unknownProduct', lang)} (${purchaseItem.productId.substring(0, 6).toUpperCase()})'
        : purchaseItem.productId;
  }

  String get unitType => product?.unitType ?? '';

  late final FocusNode focusNode;

  _ReturnLine({required this.purchaseItem, this.product, this.correctionRatio = 1.0})
    : qtyController = TextEditingController(
        text: (purchaseItem.quantity - purchaseItem.returnedQuantity)
            .toInt()
            .toString(),
      ) {
    focusNode = SelectAllFocusNode(controller: qtyController);
  }

  double get returnedQty =>
      double.tryParse(
        qtyController.text.replaceAll(',', '').replaceAll('،', ''),
      ) ??
      0;

  double get lineRefund => returnedQty * unitPrice;

  void dispose() {
    qtyController.dispose();
    focusNode.dispose();
  }
}

class PurchaseReturnScreen extends ConsumerStatefulWidget {
  final PurchaseEntity purchase;
  final List<PurchaseItemEntity> items;
  final List<ProductEntity> products;

  const PurchaseReturnScreen({
    super.key,
    required this.purchase,
    required this.items,
    required this.products,
  });

  @override
  ConsumerState<PurchaseReturnScreen> createState() =>
      _PurchaseReturnScreenState();
}
class _PurchaseReturnScreenState extends ConsumerState<PurchaseReturnScreen> {
  late final List<_ReturnLine> _lines;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final productMap = {for (final p in widget.products) p.id: p};
    
    double sumOfItems = 0;
    for (final item in widget.items) {
      sumOfItems += item.quantity * item.unitPrice;
    }
    final double correctionRatio = (sumOfItems > 0 && sumOfItems != widget.purchase.totalAmount) 
        ? (widget.purchase.totalAmount / sumOfItems) 
        : 1.0;
        
    _lines = widget.items
        .map(
          (item) => _ReturnLine(
            purchaseItem: item,
            product: productMap[item.productId],
            correctionRatio: correctionRatio,
          ),
        )
        .toList();
    for (final line in _lines) {
      line.qtyController.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _totalRefund {
    final rawRefund = _lines.fold(0.0, (s, l) => s + l.lineRefund);
    final maxRefund =
        widget.purchase.totalAmount - widget.purchase.totalReturnedAmount;
    if (rawRefund > maxRefund) {
      return maxRefund < 0 ? 0 : maxRefund;
    }
    return rawRefund;
  }

  bool get _hasAnyReturn => _lines.any((l) => l.returnedQty > 0);

  Future<void> _submit() async {
    final lang = ref.read(localeProvider).languageCode;

    if (!_hasAnyReturn) {
      AppFeedback.showError(context, Tr.t('noItemsSelected', lang));
      return;
    }

    for (final line in _lines) {
      if (line.returnedQty > line.maxReturnQty) {
        AppFeedback.showError(
          context,
          Tr.t('returnedQtyError', lang)
              .replaceFirst('{name}', line.productName(lang))
              .replaceFirst('{max}', line.maxReturnQty.toInt().toString()),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    late DebtCalculation debtCalc;
    try {
      debtCalc = const DebtCalculation(
        debtBefore: 0,
        debtAfter: 0,
        actualDeduction: 0,
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
        setState(() => _isSubmitting = false);
      }
      return;
    }
    if (mounted) setState(() => _isSubmitting = false);

    final refundStr = CurrencyFormatter.format(_totalRefund);
    final debtBeforeStr = CurrencyFormatter.format(debtCalc.debtBefore);
    final debtAfterStr = CurrencyFormatter.format(debtCalc.debtAfter);
    final deductionStr = CurrencyFormatter.format(debtCalc.actualDeduction);

    String confirmMsg = Tr.t(
      'returnConfirmMsg',
      lang,
    ).replaceFirst('{refund}', refundStr);

    if (debtCalc.debtBefore > 0) {
      confirmMsg +=
          '\n\n'
          '${Tr.t('debtBefore', lang)}: $debtBeforeStr\n'
          '${Tr.t('debtAfter', lang)}: $debtAfterStr';
      if (_totalRefund > debtCalc.debtBefore) {
        confirmMsg +=
            '\n\n${Tr.t('debtExceedsMsg', lang).replaceFirst('{deductible}', deductionStr)}';
      }
    }

    if (!mounted) return;
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: Tr.t('processPurchaseReturn', lang),
      message: confirmMsg,
      confirmLabel: Tr.t('processPurchaseReturn', lang),
      confirmColor: Colors.orange,
      icon: Icons.replay_rounded,
    );
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    try {
      final returnId = const Uuid().v4();
      final returnRecord = PurchaseReturnEntity(
        id: returnId,
        purchaseId: widget.purchase.id,
        supplierId: widget.purchase.supplierId,
        returnDate: DateTime.now(),
        totalRefund: _totalRefund,
        notes: null,
      );

      final returnItems = _lines
          .where((l) => l.returnedQty > 0)
          .map(
            (l) => PurchaseReturnItemEntity(
              id: const Uuid().v4(),
              returnId: returnId,
              productId: l.purchaseItem.productId,
              productName: l.productName(lang),
              unitType: l.unitType,
              unitPrice: l.unitPrice,
              returnedQty: l.returnedQty,
            ),
          )
          .toList();

      final purchaseItemReturns = <String, double>{};
      for (final l in _lines) {
        if (l.returnedQty > 0) {
          purchaseItemReturns[l.purchaseItem.id] = l.returnedQty;
        }
      }

      await ref
          .read(purchaseReturnRepositoryProvider)
          .createPurchaseReturn(
            returnRecord,
            returnItems,
            debtCalc,
            purchaseItemReturns,
          );

      await ref
          .read(notificationProvider.notifier)
          .addNotification(
            title: 'purchase_return_processed',
            message:
                'Refunded ${CurrencyFormatter.format(_totalRefund)} on Purchase #${widget.purchase.purchaseNumber ?? widget.purchase.id.substring(0, 8)}',
            type: 'stock',
            route:
                '${Routes.purchases}?search=${widget.purchase.purchaseNumber ?? widget.purchase.id.substring(0, 8)}',
          );

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          Tr.t('purchaseReturnedSuccessfully', lang),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);



    final purchaseTitle =
        '${Tr.t('purchaseLabel', lang)} #${widget.purchase.purchaseNumber ?? ''}';
    final selectedCount = _lines.where((l) => l.returnedQty > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Tr.t('processPurchaseReturn', lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              purchaseTitle,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Section label ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Tr.t('returnItems', lang),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${Tr.t('purchaseNo', lang)} #${widget.purchase.purchaseNumber ?? '...'}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Line items ─────────────────────────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final line = _lines[index];
                    final isOver = line.returnedQty > line.maxReturnQty;
                    final hasReturn = line.returnedQty > 0 && !isOver;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child:
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: isOver
                                  ? Border.all(color: Colors.red.withValues(alpha: 0.5))
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // Product info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.productName(lang),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                          Text(
                                            '${Tr.t('ordered', lang)}: ${line.originalQty.toInt()} ${Tr.localiseUnit(line.unitType, lang)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '1 ${Tr.localiseUnit(line.unitType, lang)} = ${CurrencyFormatter.format(line.unitPrice)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Qty input block
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller: line.qtyController,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            ArabicToEnglishFormatter(),
                                            CurrencyInputFormatter(),
                                          ],
                                          focusNode: line.focusNode,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isOver
                                                ? Colors.red
                                                : hasReturn
                                                ? theme.colorScheme.primary
                                                : null,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '0',
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 8,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: isOver
                                                    ? Colors.red
                                                    : theme.colorScheme.primary
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: isOver
                                                    ? Colors.red
                                                    : theme.colorScheme.primary,
                                                width: 2,
                                              ),
                                            ),
                                            errorText: isOver
                                                ? '> ${line.maxReturnQty.toInt()}'
                                                : null,
                                            errorStyle: const TextStyle(
                                              fontSize: 10,
                                              height: 0.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      GestureDetector(
                                        onTap: () {
                                          line.qtyController.text = line
                                              .maxReturnQty
                                              .toInt()
                                              .toString();
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${Tr.t('maxQty', lang)}: ${line.maxReturnQty.toInt()}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(
                            delay: Duration(milliseconds: 40 * index),
                            duration: 200.ms,
                          ),
                    );
                  }, childCount: _lines.length),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 220)),
              ],
            ),
          ),

          // ── Sticky bottom panel ────────────────────────────────────────
          GestureDetector(
            onTap: _isSubmitting || selectedCount == 0 ? null : _submit,
            child: Container(
              margin: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: selectedCount > 0 ? theme.colorScheme.primary : Colors.grey,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (selectedCount > 0)
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: _isSubmitting
                  ? Center(child: CircularProgressIndicator(color: theme.colorScheme.onPrimary))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$selectedCount',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Tr.t('returnTotal', lang),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(_totalRefund),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              Tr.t('processReturn', lang),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: theme.colorScheme.onPrimary,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
