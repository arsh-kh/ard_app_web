import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/local_database/database.dart';

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
      final repo = ref.read(inventoryRepositoryProvider);
      
      final product = ProductsCompanion(
        id: drift.Value(widget.productToEdit?.id ?? const Uuid().v4()),
        name: drift.Value(_nameController.text),
        categoryId: const drift.Value('default_category'), 
        stockQuantity: drift.Value(double.tryParse(_stockController.text.replaceAll(',', '')) ?? 0.0),
        unitType: drift.Value(_selectedUnit),
        buyPrice: drift.Value(double.tryParse(_buyPriceController.text.replaceAll(',', '')) ?? 0.0),
        sellPrice: drift.Value(double.tryParse(_sellPriceController.text.replaceAll(',', '')) ?? 0.0),
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
        AppFeedback.showSuccess(context, isAdd ? 'Product created successfully!' : 'Product updated successfully!');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.productToEdit == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Create New Product' : 'Modify Product Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Name field
              TextFormField(
                controller: _nameController,
                autofocus: isNew,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.label_outline),
                  hintText: 'e.g. Kurdish White Flour Premium',
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Product name is required' : null,
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
                      decoration: const InputDecoration(
                        labelText: 'Opening Stock',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                        hintText: '0.0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter()],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final doubleValue = double.tryParse(value.replaceAll(',', ''));
                        if (doubleValue == null) return 'Must be a number';
                        if (doubleValue < 0) return 'Cannot be negative';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                      ),
                      items: _units.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
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
                      decoration: const InputDecoration(
                        labelText: 'Buy Price',
                        prefixIcon: Icon(Icons.shopping_basket_outlined),
                        suffixText: ' ${AppConstants.currencySymbol}',
                        hintText: '0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter()],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final doubleValue = double.tryParse(value.replaceAll(',', ''));
                        if (doubleValue == null) return 'Must be a number';
                        if (doubleValue < 0) return 'Cannot be negative';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Sell Price',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                        suffixText: ' ${AppConstants.currencySymbol}',
                        hintText: '0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter()],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final doubleValue = double.tryParse(value.replaceAll(',', ''));
                        if (doubleValue == null) return 'Must be a number';
                        if (doubleValue < 0) return 'Cannot be negative';
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
                  child: Text(isNew ? 'Save New Product' : 'Update Product Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
