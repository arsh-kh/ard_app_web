import 'package:ard_app/core/widgets/custom_loader.dart';
import '../../core/utils/app_translations.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product_entity.dart';
import '../../core/widgets/image_picker_widget.dart';
import '../../core/services/cloud_storage_service.dart';

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
  
  String _selectedUnit = 'bag'; // Default unit
  final List<String> _units = ['bag', 'kg', 'ton', 'box'];
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productToEdit?.name ?? '');
    _stockController = TextEditingController(
      text: widget.productToEdit != null
          ? widget.productToEdit!.stockQuantity.toInt().toString()
          : '');
    _buyPriceController = TextEditingController(
      text: widget.productToEdit != null
          ? widget.productToEdit!.buyPrice.toInt().toString()
          : '');
    _sellPriceController = TextEditingController(
      text: widget.productToEdit != null
          ? widget.productToEdit!.sellPrice.toInt().toString()
          : '');
    
    if (widget.productToEdit != null && _units.contains(widget.productToEdit!.unitType)) {
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
    super.dispose();
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CustomLoader()),
      );

      final currentLocale = ref.read(localeProvider);
      final langCode = currentLocale.languageCode;

      final repo = ref.read(inventoryRepositoryProvider);
      
      String? finalImageUrl = _imagePath;
      if (_imagePath != null && !_imagePath!.startsWith('http')) {
        final storage = ref.read(cloudStorageServiceProvider);
        final uploadedUrl = await storage.uploadImage(_imagePath!, 'products');
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        }
      }

      final product = ProductEntity(
        id: widget.productToEdit?.id ?? const Uuid().v4(),
        name: _nameController.text,
        categoryId: 'default_category', 
        stockQuantity: double.tryParse(_stockController.text.replaceAll(',', '')) ?? 0.0,
        unitType: _selectedUnit,
        buyPrice: double.tryParse(_buyPriceController.text.replaceAll(',', '')) ?? 0.0,
        sellPrice: double.tryParse(_sellPriceController.text.replaceAll(',', '')) ?? 0.0,
        imageUrl: finalImageUrl,
      );

      final isAdd = widget.productToEdit == null;

      if (isAdd) {
        await repo.addProduct(product);
        await ref.read(notificationProvider.notifier).addNotification(
          title: 'new_product',
          message: jsonEncode({'name': _nameController.text}),
          type: 'stock',
        );
      } else {
        await repo.updateProduct(product);
      }

      if (mounted) {
        Navigator.pop(context); // dismiss loader
        AppFeedback.showSuccess(context, isAdd 
          ? (Tr.t('auto_Productcreateds', langCode)) 
          : (Tr.t('auto_Productupdateds', langCode))
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
      : (Tr.t('auto_ModifyProductPr', langCode));
    
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
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(Tr.t('auto_Delete', langCode), style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(inventoryRepositoryProvider).deleteProduct(widget.productToEdit!.id);
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
                decoration: InputDecoration(
                  labelText: nameLabel,
                  prefixIcon: const Icon(Icons.label_outline),
                  hintText: nameHint,
                ),
                validator: (value) => value == null || value.trim().isEmpty ? nameReq : null,
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
                      decoration: InputDecoration(
                        labelText: stockLabel,
                        prefixIcon: const Icon(Icons.warehouse_outlined),
                        hintText: '0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ArabicToEnglishFormatter(), CurrencyInputFormatter()],
                      onTap: () {
                        _stockController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _stockController.text.length,
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return reqLabel;
                        final doubleValue = double.tryParse(value.replaceAll(',', ''));
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
                      decoration: InputDecoration(
                        labelText: unitLabel,
                      ),
                      items: _units.map((unit) {
                        String displayUnit = unit;
                        if (isKurdish) {
                          if (unit == 'bag') displayUnit = 'فەردە';
                          if (unit == 'kg') displayUnit = 'کیلۆگرام';
                          if (unit == 'ton') displayUnit = 'تۆن';
                          if (unit == 'box') displayUnit = 'سندوق';
                        } else if (isArabic) {
                          if (unit == 'bag') displayUnit = 'كيس';
                          if (unit == 'kg') displayUnit = 'كيلوغرام';
                          if (unit == 'ton') displayUnit = 'طن';
                          if (unit == 'box') displayUnit = 'صندوق';
                        }
                        return DropdownMenuItem(value: unit, child: Text(displayUnit));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Pricing Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buyPriceController,
                      decoration: InputDecoration(
                        labelText: buyLabel,
                        prefixIcon: const Icon(Icons.shopping_basket_outlined),
                        suffixText: ' ${AppConstants.currencySymbol}',
                        hintText: '0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ArabicToEnglishFormatter(), CurrencyInputFormatter()],
                      onTap: () {
                        _buyPriceController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _buyPriceController.text.length,
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return reqLabel;
                        final doubleValue = double.tryParse(value.replaceAll(',', ''));
                        if (doubleValue == null) return numReqLabel;
                        if (doubleValue < 0) return negLabel;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellPriceController,
                      decoration: InputDecoration(
                        labelText: sellLabel,
                        prefixIcon: const Icon(Icons.monetization_on_outlined),
                        suffixText: ' ${AppConstants.currencySymbol}',
                        hintText: '0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ArabicToEnglishFormatter(), CurrencyInputFormatter()],
                      onTap: () {
                        _sellPriceController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _sellPriceController.text.length,
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return reqLabel;
                        final doubleValue = double.tryParse(value.replaceAll(',', ''));
                        if (doubleValue == null) return numReqLabel;
                        if (doubleValue < 0) return negLabel;
                        return null;
                      },
                    ),
                  ),
                ],
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
