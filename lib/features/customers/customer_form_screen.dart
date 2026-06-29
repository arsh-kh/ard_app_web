import '../../core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/constants/app_constants.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/customer_entity.dart';
import '../../core/widgets/image_picker_widget.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/services/cloud_storage_service.dart';

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

  late final _nameFocus = SelectAllFocusNode(controller: _nameController);
  late final _phoneFocus = SelectAllFocusNode(controller: _phoneController);
  late final _addressFocus = SelectAllFocusNode(controller: _addressController);
  late final _debtFocus = SelectAllFocusNode(controller: _debtController);
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.customerToEdit?.businessName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.customerToEdit?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customerToEdit?.address ?? '',
    );
    final formatter = NumberFormat('#,###');
    _debtController = TextEditingController(
      text: widget.customerToEdit != null
          ? formatter.format(widget.customerToEdit!.debtBalance)
          : '0',
    );
    _imagePath = widget.customerToEdit?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _debtController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _debtFocus.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CustomLoader()),
      ).ignore();

      final currentLocale = ref.read(localeProvider);
      final langCode = currentLocale.languageCode;

      final repo = ref.read(customerRepositoryProvider);

      String? finalImageUrl = _imagePath;
      if (_imagePath != null && !_imagePath!.startsWith('http')) {
        final storage = ref.read(cloudStorageServiceProvider);
        final uploadedUrl = await storage.uploadImage(_imagePath!, 'customers');
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          finalImageUrl = null;
        }
      }

      final customer = CustomerEntity(
        id: widget.customerToEdit?.id ?? const Uuid().v4(),
        businessName: _nameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text,
        debtBalance:
            double.tryParse(_debtController.text.replaceAll(',', '')) ?? 0.0,
        imageUrl: finalImageUrl,
      );

      final isAdd = widget.customerToEdit == null;

      if (isAdd) {
        await repo.addCustomer(customer);
      } else {
        await repo.updateCustomer(customer);
      }

      if (mounted) {
        Navigator.pop(context); // dismiss loader
        AppFeedback.showSuccess(
          context,
          isAdd
              ? (Tr.t('auto_Customerregiste', langCode))
              : (Tr.t('auto_Customerprofile', langCode)),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final langCode = currentLocale.languageCode;
    final isKurdish = langCode == 'ku';
    final isArabic = langCode == 'ar';
    final isNew = widget.customerToEdit == null;

    final title = isNew
        ? (Tr.t('auto_RegisterNewCust', langCode))
        : (Tr.t('customerProfile', langCode));

    final nameLabel = Tr.t('auto_BusinessCustome', langCode);
    final nameHint = Tr.t('auto_egSulaymaniyahB', langCode);
    final nameReq = Tr.t('auto_Businessnameisr', langCode);

    final phoneLabel = Tr.t('auto_PhoneNumber', langCode);
    final addressLabel = Tr.t('auto_BusinessAddress', langCode);
    final addressHint = Tr.t('auto_egSalimStreetSu', langCode);

    final debtLabel = Tr.t('auto_InitialDebtBala', langCode);
    final debtReq = Tr.t('auto_Debtbalanceisre', langCode);
    final numReqLabel = Tr.t('auto_Mustbeavaliddec', langCode);
    final negLabel = Tr.t('auto_Debtbalancecann', langCode);

    final saveBtn = isNew
        ? (Tr.t('auto_RegisterCustome', langCode))
        : (Tr.t('auto_SaveProfileupda', langCode));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                namePlaceholder: _nameController.text.isNotEmpty
                    ? _nameController.text
                    : null,
                onImageSelected: (path) {
                  setState(() => _imagePath = path);
                },
              ),
              const SizedBox(height: 24),
              // Business Name Field
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                autofocus: isNew,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                decoration: InputDecoration(
                  labelText: nameLabel,
                  prefixIcon: const Icon(Icons.business_outlined),
                  hintText: nameHint,
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? nameReq : null,
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                textAlign: Directionality.of(context) == TextDirection.rtl
                    ? TextAlign.right
                    : TextAlign.left,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                decoration: InputDecoration(
                  labelText: phoneLabel,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  hintText: '0770 123 4567',
                  hintTextDirection: TextDirection.ltr,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  ArabicToEnglishFormatter(),
                  PhoneInputFormatter(),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty && !AppValidators.isValidPhone(value.replaceAll(' ', ''))) {
                    return Tr.t('invalidPhone', langCode);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Field
              TextFormField(
                controller: _addressController,
                focusNode: _addressFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
                focusNode: _debtFocus,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: debtLabel,
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
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
                validator: (value) {
                  if (value == null || value.isEmpty) return debtReq;
                  final doubleValue = double.tryParse(
                    value.replaceAll(',', ''),
                  );
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
