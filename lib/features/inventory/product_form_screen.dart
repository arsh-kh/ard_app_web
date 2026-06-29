import 'package:ard_app/core/widgets/custom_loader.dart';
import '../../core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/purchase_entity.dart';
import '../../data/models/purchase_item_entity.dart';
import '../../core/providers/purchase_providers.dart';
import '../../core/widgets/image_picker_widget.dart';
import '../../core/services/cloud_storage_service.dart';
import '../../core/utils/focus_utils.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final ProductEntity? productToEdit;

  const ProductFormScreen({super.key, this.productToEdit});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _stockController;
  late TextEditingController _buyPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _lowStockThresholdController;
  late TextEditingController _supplierNameController;

  late final _nameFocus = SelectAllFocusNode(controller: _nameController);
  late final _stockFocus = SelectAllFocusNode(controller: _stockController);
  late final _buyPriceFocus = SelectAllFocusNode(
    controller: _buyPriceController,
  );
  late final _sellPriceFocus = SelectAllFocusNode(
    controller: _sellPriceController,
  );
  late final _deliveryFeeFocus = SelectAllFocusNode(
    controller: _deliveryFeeController,
  );
  late final _lowStockThresholdFocus = SelectAllFocusNode(
    controller: _lowStockThresholdController,
  );
  late final _supplierNameFocus = SelectAllFocusNode(
    controller: _supplierNameController,
  );

  String _selectedUnit = 'bag'; // Default fallback
  String? _imagePath;
  bool _hasAgreedToEditStock = false;
  final List<String> _units = ['bag', 'kg', 'ton', 'box'];

  @override
  void initState() {
    super.initState();
    final formatter = NumberFormat('#,###');
    _nameController = TextEditingController(
      text: widget.productToEdit?.name ?? '',
    );
    _stockController = TextEditingController(
      text: widget.productToEdit != null
          ? formatter.format(widget.productToEdit!.stockQuantity)
          : '',
    );
    _buyPriceController = TextEditingController(
      text: widget.productToEdit != null
          ? formatter.format(widget.productToEdit!.buyPrice)
          : '',
    );
    _sellPriceController = TextEditingController(
      text: widget.productToEdit != null
          ? formatter.format(widget.productToEdit!.sellPrice)
          : '',
    );
    _deliveryFeeController = TextEditingController();

    _lowStockThresholdController = TextEditingController(
      text:
          widget.productToEdit?.lowStockThreshold?.toString().replaceAll(
            RegExp(r'\.0$'),
            '',
          ) ??
          '30',
    );
    
    _supplierNameController = TextEditingController(
      text: widget.productToEdit?.supplierName ?? '',
    );

    _stockController.addListener(() => setState(() {}));
    _buyPriceController.addListener(() => setState(() {}));
    _deliveryFeeController.addListener(() => setState(() {}));

    _stockController.addListener(() => setState(() {}));
    _buyPriceController.addListener(() => setState(() {}));
    _deliveryFeeController.addListener(() => setState(() {}));

    if (widget.productToEdit != null &&
        _units.contains(widget.productToEdit!.unitType)) {
      _selectedUnit = widget.productToEdit!.unitType;
    }
    _imagePath = widget.productToEdit?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _deliveryFeeController.dispose();
    _lowStockThresholdController.dispose();
    _supplierNameController.dispose();

    _nameFocus.dispose();
    _stockFocus.dispose();
    _buyPriceFocus.dispose();
    _sellPriceFocus.dispose();
    _deliveryFeeFocus.dispose();
    _lowStockThresholdFocus.dispose();
    _supplierNameFocus.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final currentLocale = ref.read(localeProvider);
      final langCode = currentLocale.languageCode;
      final isAdd = widget.productToEdit == null;

      final stockQty =
          double.tryParse(_stockController.text.replaceAll(',', '')) ?? 0.0;
      final rawBuyPrice =
          double.tryParse(_buyPriceController.text.replaceAll(',', '')) ?? 0.0;
      final deliveryFee =
          double.tryParse(_deliveryFeeController.text.replaceAll(',', '')) ??
          0.0;
      final sellPrice =
          double.tryParse(_sellPriceController.text.replaceAll(',', '')) ?? 0.0;
      final lowStockThreshold =
          double.tryParse(
            _lowStockThresholdController.text.replaceAll(',', ''),
          ) ??
          30.0;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CustomLoader()),
      ).ignore();

      final repo = ref.read(inventoryRepositoryProvider);

      String? finalImageUrl = _imagePath;
      if (_imagePath != null && !_imagePath!.startsWith('http')) {
        final storage = ref.read(cloudStorageServiceProvider);
        final uploadedUrl = await storage.uploadImage(_imagePath!, 'products');
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          finalImageUrl = null;
        }
      }

      final trueBuyPrice = isAdd && stockQty > 0
          ? rawBuyPrice + (deliveryFee / stockQty)
          : rawBuyPrice;

      final productId = widget.productToEdit?.id ?? const Uuid().v4();
      final product = ProductEntity(
        id: productId,
        name: _nameController.text,
        categoryId: 'default_category',
        stockQuantity: isAdd ? 0 : stockQty, // Read from stockQty when editing
        unitType: _selectedUnit,
        buyPrice: trueBuyPrice,
        sellPrice: sellPrice,
        lowStockThreshold: lowStockThreshold,
        imageUrl: finalImageUrl,
        supplierName: _supplierNameController.text.trim().isEmpty ? null : _supplierNameController.text.trim(),
      );

      if (isAdd) {
        await repo.addProduct(product);

        // Auto-generate purchase if initial stock > 0
        if (stockQty > 0) {
          const targetSupplierId = 'no_supplier';

          final purchaseRepo = ref.read(purchaseRepositoryProvider);
          final purchaseId = const Uuid().v4();
          final purchaseItem = PurchaseItemEntity(
            id: const Uuid().v4(),
            purchaseId: purchaseId,
            productId: productId,
            quantity: stockQty,
            unitPrice: trueBuyPrice,
          );

          final purchase = PurchaseEntity(
            id: purchaseId,
            supplierId: targetSupplierId,
            status: 'received', // Auto-received since stock is added directly
            totalAmount: (rawBuyPrice * stockQty) + deliveryFee,
            deliveryFee: deliveryFee,
            purchaseDate: DateTime.now(),
          );

          await purchaseRepo.createPurchase(purchase, [purchaseItem]);
        }
      } else {
        await repo.updateProduct(product);
      }

      if (mounted) {
        Navigator.pop(context); // dismiss loader
        AppFeedback.showSuccess(
          context,
          isAdd
              ? (Tr.t('auto_Productcreateds', langCode))
              : (Tr.t('auto_Productupdateds', langCode)),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = ref.read(localeProvider).languageCode == 'ku';
    final langCode = currentLocale.languageCode;
    final isArabic = currentLocale.languageCode == 'ar';
    final isNew = widget.productToEdit == null;

    final title = isNew
        ? (Tr.t('auto_CreateNewProduc', langCode))
        : (Tr.t('productProfile', langCode));

    final nameLabel = Tr.t('auto_ProductName', langCode);
    final nameHint = Tr.t('auto_egKurdishWhiteF', langCode);
    final nameReq = Tr.t('auto_Productnameisre', langCode);

    final stockLabel = isNew
        ? (Tr.t('auto_Quantity', langCode))
        : (Tr.t('auto_CurrentStockUse', langCode));
    final reqLabel = Tr.t('auto_Required', langCode);
    final numReqLabel = Tr.t('auto_Mustbeanumber', langCode);
    final negLabel = Tr.t('auto_Cannotbenegativ', langCode);

    final unitLabel = Tr.t('auto_Unit', langCode);
    final buyLabel = Tr.t('auto_BuyPrice', langCode);
    final sellLabel = Tr.t('auto_SellPrice', langCode);

    final saveBtn = isNew
        ? (Tr.t('auto_SaveNewProduct', langCode))
        : (Tr.t('auto_UpdateProductDe', langCode));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(Tr.t('auto_DeleteProduct', langCode)),
                    content: Text(Tr.t('auto_Areyousureyouwa', langCode)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(Tr.t('auto_Cancel', langCode)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          Tr.t('auto_Delete', langCode),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref
                      .read(inventoryRepositoryProvider)
                      .deleteProduct(widget.productToEdit!.id);
                  if (context.mounted) {
                    context.pop();
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ImagePickerWidget(
                initialImagePath: _imagePath,
                isKurdish: isKurdish,
                isArabic: isArabic,
                radius: 60,
                placeholderIcon: Icons.inventory_2_outlined,
                onImageSelected: (path) {
                  setState(() => _imagePath = path);
                },
              ),
              const SizedBox(height: 24),

              // Product Name field
              TextFormField(
                controller: _nameController,
                autofocus: isNew,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_supplierNameFocus),
                decoration: InputDecoration(
                  labelText: nameLabel,
                  prefixIcon: const Icon(Icons.label_outline),
                  hintText: nameHint,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? nameReq : null,
              ),
              const SizedBox(height: 16),

              // Supplier Name field (Optional)
              TextFormField(
                controller: _supplierNameController,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_stockFocus),
                focusNode: _supplierNameFocus,
                decoration: InputDecoration(
                  labelText: langCode == 'ku' ? 'ناوی دابینکەر (ئارەزوومەندانە)' : langCode == 'ar' ? 'اسم المورد (اختياري)' : 'Supplier Name (Optional)',
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  hintText: langCode == 'ku' ? 'ناوی ئەو کۆمپانیایە بنووسە' : langCode == 'ar' ? 'اكتب اسم الشركة' : 'Enter supplier or company name',
                ),
              ),
              const SizedBox(height: 16),

              // Stock & Unit fields
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stockController,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_buyPriceFocus),
                      decoration: InputDecoration(
                        labelText: stockLabel,
                        prefixIcon: const Icon(Icons.warehouse_outlined),
                        hintText: '0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        ArabicToEnglishFormatter(),
                        CurrencyInputFormatter(),
                      ],
                      readOnly: !isNew && !_hasAgreedToEditStock,
                      focusNode: _stockFocus,
                      onTap: () async {
                        if (!isNew && !_hasAgreedToEditStock) {
                          final agreed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                Tr.t('addAmountWarningTitle', langCode),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              content: Text(
                                Tr.t('addAmountWarningDesc', langCode),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(Tr.t('goBackBtn', langCode)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(Tr.t('agreeAnywayBtn', langCode)),
                                ),
                              ],
                            ),
                          );

                          if (agreed == true && mounted) {
                            setState(() {
                              _hasAgreedToEditStock = true;
                            });
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return reqLabel;
                        final doubleValue = double.tryParse(
                          value.replaceAll(',', ''),
                        );
                        if (doubleValue == null) return numReqLabel;
                        if (doubleValue < 0) return negLabel;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(labelText: unitLabel),
                      items: _units.map((unit) {
                        final String displayUnit = Tr.localiseUnit(
                          unit,
                          langCode,
                        );
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(displayUnit),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Buy Price
              TextFormField(
                controller: _buyPriceController,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_sellPriceFocus),
                decoration: InputDecoration(
                  labelText: buyLabel,
                  prefixIcon: const Icon(Icons.shopping_basket_outlined),
                  suffixText: ' ${AppConstants.currencySymbol}',
                  hintText: '0',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  ArabicToEnglishFormatter(),
                  CurrencyInputFormatter(),
                ],
                focusNode: _buyPriceFocus,
                validator: (value) {
                  if (value == null || value.isEmpty) return reqLabel;
                  final doubleValue = double.tryParse(
                    value.replaceAll(',', ''),
                  );
                  if (doubleValue == null) return numReqLabel;
                  if (doubleValue < 0) return negLabel;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sell Price
              TextFormField(
                controller: _sellPriceController,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  if (isNew) {
                    FocusScope.of(context).requestFocus(_deliveryFeeFocus);
                  } else {
                    FocusScope.of(context).requestFocus(_lowStockThresholdFocus);
                  }
                },
                decoration: InputDecoration(
                  labelText: sellLabel,
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  suffixText: ' ${AppConstants.currencySymbol}',
                  hintText: '0',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  ArabicToEnglishFormatter(),
                  CurrencyInputFormatter(),
                ],
                focusNode: _sellPriceFocus,
                validator: (value) {
                  if (value == null || value.isEmpty) return reqLabel;
                  final doubleValue = double.tryParse(
                    value.replaceAll(',', ''),
                  );
                  if (doubleValue == null) return numReqLabel;
                  if (doubleValue < 0) return negLabel;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (isNew) ...[
                // Delivery Fee
                TextFormField(
                  controller: _deliveryFeeController,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_lowStockThresholdFocus),
                  decoration: InputDecoration(
                    labelText: Tr.t('deliveryFee', langCode),
                    prefixIcon: const Icon(Icons.local_shipping_outlined),
                    suffixText: ' ${AppConstants.currencySymbol}',
                    hintText: '0',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    ArabicToEnglishFormatter(),
                    CurrencyInputFormatter(),
                  ],
                  focusNode: _deliveryFeeFocus,
                ),
                const SizedBox(height: 16),

                // Calculated True Cost
                Builder(
                  builder: (context) {
                    final stockQty =
                        double.tryParse(
                          _stockController.text.replaceAll(',', ''),
                        ) ??
                        0.0;
                    final rawBuyPrice =
                        double.tryParse(
                          _buyPriceController.text.replaceAll(',', ''),
                        ) ??
                        0.0;
                    final deliveryFee =
                        double.tryParse(
                          _deliveryFeeController.text.replaceAll(',', ''),
                        ) ??
                        0.0;
                    double trueUnitCost = rawBuyPrice;
                    if (stockQty > 0 && deliveryFee > 0) {
                      trueUnitCost = rawBuyPrice + (deliveryFee / stockQty);
                    }

                    if (trueUnitCost > rawBuyPrice) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${Tr.t('calculatedUnitCost', langCode)}: ${CurrencyFormatter.format(trueUnitCost)}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Low Stock Threshold
              TextFormField(
                controller: _lowStockThresholdController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: Tr.t('lowStockThresholdLabel', langCode),
                  prefixIcon: const Icon(Icons.warning_amber_rounded),
                  hintText: Tr.t('lowStockThresholdHint', langCode),
                  helperText: Tr.t('lowStockThresholdDesc', langCode),
                  helperMaxLines: 2,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ArabicToEnglishFormatter()],
                focusNode: _lowStockThresholdFocus,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final doubleValue = double.tryParse(
                      value.replaceAll(',', ''),
                    );
                    if (doubleValue == null) return numReqLabel;
                    if (doubleValue < 0) return negLabel;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text(saveBtn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
