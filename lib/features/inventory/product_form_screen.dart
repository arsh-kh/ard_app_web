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
    _stockController = TextEditingController(text: widget.productToEdit?.stockQuantity.toString() ?? '');
    _buyPriceController = TextEditingController(text: widget.productToEdit?.buyPrice.toString() ?? '');
    _sellPriceController = TextEditingController(text: widget.productToEdit?.sellPrice.toString() ?? '');
    
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
      final currentLocale = ref.read(localeProvider);
      final isKurdish = currentLocale.languageCode == 'ku';
      final isArabic = currentLocale.languageCode == 'ar';

      final repo = ref.read(inventoryRepositoryProvider);
      
      final product = ProductEntity(
        id: widget.productToEdit?.id ?? const Uuid().v4(),
        name: _nameController.text,
        categoryId: 'default_category', 
        stockQuantity: double.tryParse(_stockController.text.replaceAll(',', '')) ?? 0.0,
        unitType: _selectedUnit,
        buyPrice: double.tryParse(_buyPriceController.text.replaceAll(',', '')) ?? 0.0,
        sellPrice: double.tryParse(_sellPriceController.text.replaceAll(',', '')) ?? 0.0,
        imageUrl: _imagePath,
      );

      final isAdd = widget.productToEdit == null;

      if (isAdd) {
        await repo.addProduct(product);
        await ref.read(notificationProvider.notifier).addNotification(
          title: '${AppConstants.appName} - New Product Registered',
          message: '${_nameController.text} added to inventory catalog.',
          type: 'stock',
        );
      } else {
        await repo.updateProduct(product);
      }

      if (mounted) {
        AppFeedback.showSuccess(context, isAdd 
          ? (isKurdish ? 'بەرهەمەکە بە سەرکەوتوویی دروستکرا!' : isArabic ? 'تم إنشاء المنتج بنجاح!' : 'Product created successfully!') 
          : (isKurdish ? 'بەرهەمەکە بە سەرکەوتوویی نوێکرایەوە!' : isArabic ? 'تم تحديث المنتج بنجاح!' : 'Product updated successfully!')
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    final isNew = widget.productToEdit == null;

    final title = isNew 
      ? (isKurdish ? 'دروستکردنی بەرهەمی نوێ' : isArabic ? 'إنشاء منتج جديد' : 'Create New Product') 
      : (isKurdish ? 'گۆڕینی پرۆفایلی بەرهەم' : isArabic ? 'تعديل ملف المنتج' : 'Modify Product Profile');
    
    final nameLabel = isKurdish ? 'ناوی بەرهەم' : isArabic ? 'اسم المنتج' : 'Product Name';
    final nameHint = isKurdish ? 'بۆ نموونە: ئاردی سپی کوردی' : isArabic ? 'مثل: طحين أبيض كردي ممتاز' : 'e.g. Kurdish White Flour Premium';
    final nameReq = isKurdish ? 'ناوی بەرهەم داواکراوە' : isArabic ? 'اسم المنتج مطلوب' : 'Product name is required';
    
    final stockLabel = isNew 
      ? (isKurdish ? 'کۆگای سەرەتا' : isArabic ? 'المخزون الافتتاحي' : 'Opening Stock')
      : (isKurdish ? 'کۆگای ئێستا (دەستکاری مەکە بۆ کڕینی نوێ)' : isArabic ? 'المخزون الحالي' : 'Current Stock (Use Restock to add)');
    final reqLabel = isKurdish ? 'داواکراوە' : isArabic ? 'مطلوب' : 'Required';
    final numReqLabel = isKurdish ? 'دەبێت ژمارە بێت' : isArabic ? 'يجب أن يكون رقماً' : 'Must be a number';
    final negLabel = isKurdish ? 'نابێت نەرێنی بێت' : isArabic ? 'لا يمكن أن يكون سالباً' : 'Cannot be negative';
    
    final unitLabel = isKurdish ? 'یەکە' : isArabic ? 'الوحدة' : 'Unit';
    final buyLabel = isKurdish ? 'نرخی کڕین' : isArabic ? 'سعر الشراء' : 'Buy Price';
    final sellLabel = isKurdish ? 'نرخی فرۆشتن' : isArabic ? 'سعر البيع' : 'Sell Price';
    
    final saveBtn = isNew 
      ? (isKurdish ? 'پاشەکەوتکردنی بەرهەمی نوێ' : isArabic ? 'حفظ المنتج الجديد' : 'Save New Product') 
      : (isKurdish ? 'نوێکردنەوەی وردەکارییەکانی بەرهەم' : isArabic ? 'تحديث تفاصيل المنتج' : 'Update Product Details');

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
                    title: Text(isKurdish ? 'سڕینەوەی کاڵا' : isArabic ? 'حذف المنتج' : 'Delete Product'),
                    content: Text(isKurdish ? 'دڵنیای لە سڕینەوەی ئەم کاڵایە؟' : isArabic ? 'هل أنت متأكد من حذف هذا المنتج؟' : 'Are you sure you want to delete this product?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(isKurdish ? 'نەخێر' : isArabic ? 'لا' : 'Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(isKurdish ? 'سڕینەوە' : isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
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
                        hintText: '0.0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ArabicToEnglishFormatter(), CurrencyInputFormatter()],
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

