import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/customer_entity.dart';
import '../../core/widgets/image_picker_widget.dart';

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
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customerToEdit?.businessName ?? '');
    _phoneController = TextEditingController(text: widget.customerToEdit?.phone ?? '');
    _addressController = TextEditingController(text: widget.customerToEdit?.address ?? '');
    _debtController = TextEditingController(text: widget.customerToEdit?.debtBalance.toString() ?? '0.0');
    _imagePath = widget.customerToEdit?.imageUrl;
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
      final currentLocale = ref.read(localeProvider);
      final isKurdish = currentLocale.languageCode == 'ku';
      final isArabic = currentLocale.languageCode == 'ar';

      final repo = ref.read(customerRepositoryProvider);

      final customer = CustomerEntity(
        id: widget.customerToEdit?.id ?? const Uuid().v4(),
        businessName: _nameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text,
        debtBalance: double.tryParse(_debtController.text.replaceAll(',', '')) ?? 0.0,
        imageUrl: _imagePath,
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
        AppFeedback.showSuccess(context, isAdd 
          ? (isKurdish ? 'کڕیارەکە بە سەرکەوتوویی تۆمارکرا!' : isArabic ? 'تم تسجيل العميل بنجاح!' : 'Customer registered successfully!')
          : (isKurdish ? 'پڕۆفایلی کڕیارەکە نوێکرایەوە!' : isArabic ? 'تم تحديث ملف العميل!' : 'Customer profile updated!')
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
    final isNew = widget.customerToEdit == null;

    final title = isNew 
      ? (isKurdish ? 'تۆمارکردنی کڕیاری نوێ' : isArabic ? 'تسجيل عميل جديد' : 'Register New Customer')
      : (isKurdish ? 'گۆڕینی پرۆفایلی کڕیار' : isArabic ? 'تعديل ملف العميل' : 'Modify Customer Profile');

    final nameLabel = isKurdish ? 'ناوی کار / کڕیار' : isArabic ? 'اسم العمل / العميل' : 'Business / Customer Name';
    final nameHint = isKurdish ? 'بۆ نموونە: گرووپی نانەواخانەی سلێمانی' : isArabic ? 'مثل: مجموعة مخابز السليمانية' : 'e.g. Sulaymaniyah Bakery Group';
    final nameReq = isKurdish ? 'ناوی کار داواکراوە' : isArabic ? 'اسم العمل مطلوب' : 'Business name is required';

    final phoneLabel = isKurdish ? 'ژمارەی تەلەفۆن' : isArabic ? 'رقم الهاتف' : 'Phone Number';
    final addressLabel = isKurdish ? 'ناونیشانی کار' : isArabic ? 'عنوان العمل' : 'Business Address';
    final addressHint = isKurdish ? 'بۆ نموونە: شەقامی سەالم، سلێمانی، عێراق' : isArabic ? 'مثل: شارع سالم، السليمانية، العراق' : 'e.g. Salim Street, Sulaymaniyah, Iraq';

    final debtLabel = isKurdish ? 'قەرزی سەرەتا' : isArabic ? 'الرصيد الافتتاحي للديون' : 'Initial Debt Balance';
    final debtReq = isKurdish ? 'قەرز داواکراوە' : isArabic ? 'الرصيد مطلوب' : 'Debt balance is required';
    final numReqLabel = isKurdish ? 'دەبێت ژمارە بێت' : isArabic ? 'يجب أن يكون رقماً' : 'Must be a valid decimal';
    final negLabel = isKurdish ? 'نابێت نەرێنی بێت' : isArabic ? 'لا يمكن أن يكون سالباً' : 'Debt balance cannot be negative';

    final saveBtn = isNew 
      ? (isKurdish ? 'تۆمارکردنی کڕیار' : isArabic ? 'تسجيل العميل' : 'Register Customer')
      : (isKurdish ? 'پاشەکەوتکردنی گۆڕانکارییەکان' : isArabic ? 'حفظ تحديثات الملف' : 'Save Profile updates');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                placeholderIcon: Icons.person_outline,
                onImageSelected: (path) {
                  setState(() => _imagePath = path);
                },
              ),
              const SizedBox(height: 24),
              // Business Name Field
              TextFormField(
                controller: _nameController,
                autofocus: isNew,
                decoration: InputDecoration(
                  labelText: nameLabel,
                  prefixIcon: const Icon(Icons.business_outlined),
                  hintText: nameHint,
                ),
                validator: (value) => value == null || value.trim().isEmpty ? nameReq : null,
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: phoneLabel,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  hintText: '0770 123 4567',
                  hintTextDirection: TextDirection.ltr,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [ArabicToEnglishFormatter(), PhoneInputFormatter()],
              ),
              const SizedBox(height: 16),
              
              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: addressLabel,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  hintText: addressHint,
                ),
              ),
              const SizedBox(height: 16),
              
              // Debt Balance Field
              TextFormField(
                controller: _debtController,
                decoration: InputDecoration(
                  labelText: debtLabel,
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  suffixText: ' ${AppConstants.currencySymbol}',
                  hintText: '0',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ArabicToEnglishFormatter(), CurrencyInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) return debtReq;
                  final doubleValue = double.tryParse(value.replaceAll(',', ''));
                  if (doubleValue == null) return numReqLabel;
                  if (doubleValue < 0) return negLabel;
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCustomer,
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

