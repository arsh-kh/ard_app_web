import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/pdf_settings_service.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/widgets/custom_top_bar_helper.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';


import '../../core/providers/business_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_loader.dart';

class PdfSettingsScreen extends ConsumerStatefulWidget {
  const PdfSettingsScreen({super.key});

  @override
  ConsumerState<PdfSettingsScreen> createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends ConsumerState<PdfSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _desc1Controller = TextEditingController();
  final _desc2Controller = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _phone3Controller = TextEditingController();

  final _shopNameFocus = FocusNode();
  final _desc1Focus = FocusNode();
  final _desc2Focus = FocusNode();
  final _phone1Focus = FocusNode();
  final _phone2Focus = FocusNode();
  final _phone3Focus = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final businessId = ref.read(currentBusinessIdProvider) ?? '';
    final settings = await PdfSettingsService.getSettings(businessId);
    if (!mounted) return;
    setState(() {
      _shopNameController.text = settings.shopName;
      _desc1Controller.text = settings.description1;
      _desc2Controller.text = settings.description2;
      _phone1Controller.text = settings.phone1;
      _phone2Controller.text = settings.phone2;
      _phone3Controller.text = settings.phone3;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _desc1Controller.dispose();
    _desc2Controller.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _phone3Controller.dispose();
    
    _shopNameFocus.dispose();
    _desc1Focus.dispose();
    _desc2Focus.dispose();
    _phone1Focus.dispose();
    _phone2Focus.dispose();
    _phone3Focus.dispose();
    super.dispose();
  }

  Future<void> _saveSettings(String langCode) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final settings = PdfSettings(
      shopName: _shopNameController.text,
      description1: _desc1Controller.text,
      description2: _desc2Controller.text,
      phone1: _phone1Controller.text,
      phone2: _phone2Controller.text,
      phone3: _phone3Controller.text,
    );
    
    final businessId = ref.read(currentBusinessIdProvider) ?? '';
    try {
      await PdfSettingsService.saveSettings(settings, businessId);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showError(context, e.toString());
      }
      return;
    }
    
    if (mounted) {
      setState(() => _isSaving = false);
      AppFeedback.showSuccess(context, Tr.t('pdfSettingsSaved', langCode));
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final langCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(Tr.t('pdfPrintSettingsTitle', langCode)),
        centerTitle: true,
        leading: CustomTopBarHelper.buildLeading(
          context: context,
          isRtl: isRtl,
          hasBackButton: true,
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  Tr.t('pdfPrintSettingsDesc', langCode),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _shopNameController,
                  focusNode: _shopNameFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_desc1Focus),
                  decoration: InputDecoration(
                    labelText: Tr.t('shopNameLabel', langCode),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return Tr.t('shopNameError', langCode);
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _desc1Controller,
                  focusNode: _desc1Focus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_desc2Focus),
                  decoration: InputDecoration(
                    labelText: Tr.t('desc1Label', langCode),
                    hintText: Tr.t('desc1Hint', langCode),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _desc2Controller,
                  focusNode: _desc2Focus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phone1Focus),
                  decoration: InputDecoration(
                    labelText: Tr.t('desc2Label', langCode),
                    hintText: Tr.t('desc2Hint', langCode),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  Tr.t('contactInfoTitle', langCode),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phone1Controller,
                  focusNode: _phone1Focus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phone2Focus),
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  inputFormatters: [
                    ArabicToEnglishFormatter(),
                    PhoneInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: Tr.t('phone1Label', langCode),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return Tr.t('phone1Error', langCode);
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phone2Controller,
                  focusNode: _phone2Focus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phone3Focus),
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  inputFormatters: [
                    ArabicToEnglishFormatter(),
                    PhoneInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: Tr.t('phone2Label', langCode),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phone3Controller,
                  focusNode: _phone3Focus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saveSettings(langCode),
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  inputFormatters: [
                    ArabicToEnglishFormatter(),
                    PhoneInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: Tr.t('phone3Label', langCode),
                    border: const OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _saveSettings(langCode),
                    child: _isSaving
                        ? const CustomLoader(size: 24)
                        : Text(Tr.t('saveSettings', langCode)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }
}
