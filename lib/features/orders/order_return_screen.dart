import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/providers/return_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/utils/app_translations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/formatters.dart';

import '../../data/models/customer_entity.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/return_entity.dart';
import '../../data/models/return_item_entity.dart';
import '../../data/repositories/return_repository.dart';

class _ReturnLine {
  final OrderItemEntity orderItem;
  final ProductEntity? product;
  final TextEditingController qtyController;
  final double correctionRatio;
  
  double get originalQty => orderItem.quantity;
  double get maxReturnQty => orderItem.quantity - orderItem.returnedQuantity;
  double get unitPrice => orderItem.unitPrice * correctionRatio;
  
  String productName(String lang) {
    final name = product?.name;
    if (name != null && name.isNotEmpty) return name;
    return orderItem.productId.length > 20
        ? '${Tr.t('unknownProduct', lang)} (${orderItem.productId.substring(0, 6).toUpperCase()})'
        : orderItem.productId;
  }

  String get unitType => product?.unitType ?? '';

  late final FocusNode focusNode;

  _ReturnLine({required this.orderItem, this.product, this.correctionRatio = 1.0})
    : qtyController = TextEditingController(
        text: (orderItem.quantity - orderItem.returnedQuantity)
            .toInt()
            .toString(),
      ) {
    focusNode = SelectAllFocusNode(controller: qtyController);
  }

  double get returnedQty {
    final val = CurrencyFormatter.tryParse(qtyController.text) ?? 0.0;
    if (val < 0) return 0.0;
    return val;
  }
  double get lineRefund => returnedQty * unitPrice;

  void dispose() {
    qtyController.dispose();
    focusNode.dispose();
  }
}

class OrderReturnScreen extends ConsumerStatefulWidget {
  final OrderEntity order;
  final List<OrderItemEntity> items;
  final CustomerEntity? customer;
  final List<ProductEntity> products;

  const OrderReturnScreen({
    super.key,
    required this.order,
    required this.items,
    required this.customer,
    required this.products,
  });

  @override
  ConsumerState<OrderReturnScreen> createState() => _OrderReturnScreenState();
}

class _OrderReturnScreenState extends ConsumerState<OrderReturnScreen> {
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
    final double correctionRatio = (sumOfItems > 0 && sumOfItems != widget.order.totalAmount) 
        ? (widget.order.totalAmount / sumOfItems) 
        : 1.0;
        
    _lines = widget.items
        .map(
          (item) =>
              _ReturnLine(
                orderItem: item, 
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
        widget.order.totalAmount - widget.order.totalReturnedAmount;
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
      debtCalc = await ref
          .read(returnRepositoryProvider)
          .previewDebtReduction(widget.order.customerId, _totalRefund);
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
    if (widget.customer != null && debtCalc.debtBefore > 0) {
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
      title: Tr.t('processReturn', lang),
      message: confirmMsg,
      confirmLabel: Tr.t('processReturn', lang),
      confirmColor: Colors.orange,
      icon: Icons.replay_rounded,
    );
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    try {
      final returnId = const Uuid().v4();
      final returnRecord = ReturnEntity(
        id: returnId,
        orderId: widget.order.id,
        customerId: widget.order.customerId,
        returnDate: DateTime.now(),
        totalRefund: _totalRefund,
        notes: null,
      );
      final returnItems = _lines
          .where((l) => l.returnedQty > 0)
          .map(
            (l) => ReturnItemEntity(
              id: const Uuid().v4(),
              returnId: returnId,
              productId: l.orderItem.productId,
              productName: l.productName(lang),
              unitType: l.unitType,
              unitPrice: l.unitPrice,
              returnedQty: l.returnedQty,
            ),
          )
          .toList();

      final orderItemReturns = <String, double>{};
      for (final l in _lines) {
        if (l.returnedQty > 0) {
          orderItemReturns[l.orderItem.id] = l.returnedQty;
        }
      }

      await ref
          .read(returnRepositoryProvider)
          .createReturn(returnRecord, returnItems, debtCalc, orderItemReturns);

      await ref
          .read(notificationProvider.notifier)
          .addNotification(
            title: 'return_processed',
            message:
                'Refunded ${CurrencyFormatter.format(_totalRefund)} on Order #${widget.order.orderNumber ?? widget.order.id.substring(0, 8)} - ${widget.customer?.businessName ?? 'Walk-In'}',
            type: 'order',
            route:
                '${Routes.adminOrders}?search=${widget.order.orderNumber ?? widget.order.id.substring(0, 8)}',
          );

      if (mounted) {
        AppFeedback.showSuccess(context, Tr.t('returnSuccess', lang));
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



    final customerName = widget.customer?.businessName ?? Tr.t('walkIn', lang);
    final selectedCount = _lines.where((l) => l.returnedQty > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Tr.t('processReturn', lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              customerName,
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
                            color: Theme.of(context).colorScheme.onSurface,
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
                            '${Tr.t('orderLabel', lang)} #${widget.order.orderNumber ?? '...'}',
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
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
