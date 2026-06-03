import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class KurdishMaterialLocalizations extends DefaultMaterialLocalizations {
  const KurdishMaterialLocalizations();

  @override
  String get okButtonLabel => 'باشە';

  @override
  String get cancelButtonLabel => 'هەڵوەشاندنەوە';

  @override
  String get closeButtonLabel => 'داخستن';

  @override
  String get searchFieldLabel => 'گەڕان...';

  @override
  String get selectAllButtonLabel => 'دیاریکردنی هەموو';

  @override
  String get copyButtonLabel => 'کۆپیکردن';

  @override
  String get cutButtonLabel => 'بڕین';

  @override
  String get pasteButtonLabel => 'لکاندن';

  @override
  String get backButtonTooltip => 'گەڕانەوە';

  @override
  String get nextPageTooltip => 'لاپەڕەی داهاتوو';

  @override
  String get previousPageTooltip => 'لاپەڕەی پێشوو';

  @override
  String get firstPageTooltip => 'یەکەم لاپەڕە';

  @override
  String get lastPageTooltip => 'دوا لاپەڕە';

  @override
  String get showMenuTooltip => 'نیشاندانی پێڕست';

  @override
  String get moreButtonTooltip => 'زیاتر';

  @override
  String get rowsPerPageTitle => 'ڕیز لە هەر لاپەڕەیەکدا:';

  static const LocalizationsDelegate<MaterialLocalizations> delegate = _KurdishMaterialLocalizationsDelegate();
}

class _KurdishMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const KurdishMaterialLocalizations();
  }

  @override
  bool shouldReload(_KurdishMaterialLocalizationsDelegate old) => false;
}

class KurdishCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const KurdishCupertinoLocalizations();

  @override
  String get alertDialogLabel => 'ئاگاداری';

  @override
  String get copyButtonLabel => 'کۆپیکردن';

  @override
  String get cutButtonLabel => 'بڕین';

  @override
  String get pasteButtonLabel => 'لکاندن';

  @override
  String get selectAllButtonLabel => 'دیاریکردنی هەموو';

  @override
  String get searchTextFieldPlaceholderLabel => 'گەڕان...';

  static const LocalizationsDelegate<CupertinoLocalizations> delegate = _KurdishCupertinoLocalizationsDelegate();
}

class _KurdishCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _KurdishCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return const KurdishCupertinoLocalizations();
  }

  @override
  bool shouldReload(_KurdishCupertinoLocalizationsDelegate old) => false;
}

class KurdishWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const KurdishWidgetsLocalizations();

  @override
  TextDirection get textDirection => TextDirection.rtl;

  static const LocalizationsDelegate<WidgetsLocalizations> delegate = _KurdishWidgetsLocalizationsDelegate();
}

class _KurdishWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _KurdishWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    return const KurdishWidgetsLocalizations();
  }

  @override
  bool shouldReload(_KurdishWidgetsLocalizationsDelegate old) => false;
}
