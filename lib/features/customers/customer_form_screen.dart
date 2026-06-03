import 'package:ard_app/data/local_database/tables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/local_database/database.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final CustomerEntity? customerToEdit;

  const CustomerFormScreen({super.key, this.customerToEdit});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _debtController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customerToEdit?.businessName ?? '');
    _phoneController = TextEditingController(text: widget.customerToEdit?.phone ?? '');
    _addressController = TextEditingController(text: widget.customerToEdit?.address ?? '');
    _debtController = TextEditingController(text: widget.customerToEdit?.debtBalance.toString() ?? '0.0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(customerRepositoryProvider);

      final customer = CustomersCompanion(
        id: drift.Value(widget.customerToEdit?.id ?? const Uuid().v4()),
        businessName: drift.Value(_nameController.text),
        phone: drift.Value(_phoneController.text.isNotEmpty ? _phoneController.text : null),
        address: drift.Value(_addressController.text),
        debtBalance: drift.Value(double.tryParse(_debtController.text.replaceAll(',', '')) ?? 0.0),
        syncStatus: const drift.Value(SyncStatus.pendingSync),
      );

      final isAdd = widget.customerToEdit == null;

      if (isAdd) {
        await repo.addCustomer(customer);
        await ref.read(notificationProvider.notifier).addNotification(
          title: '${AppConstants.appName} - New Customer Created',
          message: '${_nameController.text} added to customer directory.',
          type: 'sync',
        );
      } else {
        await repo.updateCustomer(customer);
      }

      if (mounted) {
        AppFeedback.showSuccess(context, isAdd ? 'Customer registered successfully!' : 'Customer profile updated!');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.customerToEdit == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Register New Customer' : 'Modify Customer Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Business Name Field
              TextFormField(
                controller: _nameController,
                autofocus: isNew,
                decoration: const InputDecoration(
                  labelText: 'Business / Customer Name',
                  prefixIcon: Icon(Icons.business_outlined),
                  hintText: 'e.g. Sulaymaniyah Bakery Group',
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Business name is required' : null,
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: 'e.g. 0770 123 4567',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Business Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'e.g. Salim Street, Sulaymaniyah, Iraq',
                ),
              ),
              const SizedBox(height: 16),
              
              // Debt Balance Field
              TextFormField(
                controller: _debtController,
                decoration: const InputDecoration(
                  labelText: 'Initial Debt Balance',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  suffixText: ' ${AppConstants.currencySymbol}',
                  hintText: '0',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [CurrencyInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Debt balance is required';
                  final doubleValue = double.tryParse(value.replaceAll(',', ''));
                  if (doubleValue == null) return 'Must be a valid decimal';
                  if (doubleValue < 0) return 'Debt balance cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  child: Text(isNew ? 'Register Customer' : 'Save Profile updates'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
