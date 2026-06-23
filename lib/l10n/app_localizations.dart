import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ku.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ku'),
  ];

  /// The application name, always displayed in Kurdish/Arabic script
  ///
  /// In en, this message translates to:
  /// **'ئارد'**
  String get appName;

  /// Tagline shown below the app name on splash/login screens
  ///
  /// In en, this message translates to:
  /// **'Flour Distribution Management'**
  String get appTagline;

  /// Login button and page title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button label
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Email input field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password input field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Checkbox label for persisting login session
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// Link to password reset flow
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Main dashboard navigation label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Inventory section navigation label
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// Sales section navigation label
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// Purchases section navigation label
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// Customers section navigation label
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// Invoices section navigation label
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// Reports section navigation label
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Settings section navigation label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Dashboard card title showing total inventory value or count
  ///
  /// In en, this message translates to:
  /// **'Total Inventory'**
  String get totalInventory;

  /// Dashboard card title showing today's sales total
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaySales;

  /// Dashboard card title showing current month profit
  ///
  /// In en, this message translates to:
  /// **'Monthly Profit'**
  String get monthlyProfit;

  /// Dashboard card title showing total outstanding debts
  ///
  /// In en, this message translates to:
  /// **'Debtors'**
  String get pendingDebts;

  /// Dashboard section title for products below minimum stock
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get lowStockAlerts;

  /// Dashboard section title for latest transactions
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// Dashboard section title for top-selling flour products
  ///
  /// In en, this message translates to:
  /// **'Best Selling Flour'**
  String get bestSellingFlour;

  /// Button label for adding a new product
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// Button/page title for editing an existing product
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// Button label for deleting a product
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// Input field label for product name
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// Input field label for flour type classification
  ///
  /// In en, this message translates to:
  /// **'Flour Type'**
  String get flourType;

  /// Input field label for product brand
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// Input field label for current stock amount
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get stockQuantity;

  /// Dropdown label for selecting measurement unit
  ///
  /// In en, this message translates to:
  /// **'Unit Type'**
  String get unitType;

  /// Input field label for purchase/cost price
  ///
  /// In en, this message translates to:
  /// **'Buy Price'**
  String get buyPrice;

  /// Input field label for selling price
  ///
  /// In en, this message translates to:
  /// **'Sell Price'**
  String get sellPrice;

  /// Input field label for low stock threshold
  ///
  /// In en, this message translates to:
  /// **'Minimum Stock'**
  String get minimumStock;

  /// Input field label for product barcode
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// Unit of measurement: kilogram
  ///
  /// In en, this message translates to:
  /// **'Kilogram'**
  String get kg;

  /// Unit of measurement: bag/sack of flour
  ///
  /// In en, this message translates to:
  /// **'Bag'**
  String get bag;

  /// Unit of measurement: metric ton
  ///
  /// In en, this message translates to:
  /// **'Ton'**
  String get ton;

  /// Unit of measurement: individual pieces
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get pieces;

  /// Placeholder text for inventory search field
  ///
  /// In en, this message translates to:
  /// **'Search Inventory'**
  String get searchInventory;

  /// Label for filter dropdown/dialog
  ///
  /// In en, this message translates to:
  /// **'Filter By'**
  String get filterBy;

  /// Label for sort dropdown/dialog
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Stock status label when quantity is below minimum
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// Stock status label when quantity is available
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// Stock status label when quantity is zero
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// Button label for adding a new customer
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// Button/page title for editing an existing customer
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// Input field label for customer full name
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// Input field label for the customer's bakery business name
  ///
  /// In en, this message translates to:
  /// **'Bakery Name'**
  String get bakeryName;

  /// Input field label for phone number
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Input field label for physical address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Label showing customer's current outstanding debt
  ///
  /// In en, this message translates to:
  /// **'Debtors'**
  String get currentDebt;

  /// Section title for list of past payments
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// Section title for list of past purchases
  ///
  /// In en, this message translates to:
  /// **'Purchase History'**
  String get purchaseHistory;

  /// Input field label for notes about a customer
  ///
  /// In en, this message translates to:
  /// **'Customer Notes'**
  String get customerNotes;

  /// Button label for creating a new sale transaction
  ///
  /// In en, this message translates to:
  /// **'Create Sale'**
  String get createSale;

  /// Page title for list of past sales
  ///
  /// In en, this message translates to:
  /// **'Sales History'**
  String get salesHistory;

  /// Page title for individual sale detail view
  ///
  /// In en, this message translates to:
  /// **'Sale Details'**
  String get saleDetails;

  /// Dropdown/search label for choosing a customer
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomer;

  /// Dropdown/search label for choosing a product
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// Input field label for item quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Label for price per single unit
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// Label for total price of a line item
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// Label for sum before discount
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// Input field label for discount amount
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// Label for final total after discount
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// Input field label for amount paid by customer
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// Label for unpaid balance after partial payment
  ///
  /// In en, this message translates to:
  /// **'Remaining Debt'**
  String get remainingDebt;

  /// Label for the current payment status of a transaction
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// Payment status: fully paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// Payment status: partially paid
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// Payment status: not paid at all
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// Button label for adding a new payment record
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// Button/page title for recording a payment
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// Dropdown label for selecting how payment was made
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Payment method: cash
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Payment method: bank transfer
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get transfer;

  /// Payment method: bank check/cheque
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// Button label for creating a new purchase from supplier
  ///
  /// In en, this message translates to:
  /// **'Create Purchase'**
  String get createPurchase;

  /// Input field label for supplier/vendor name
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get supplierName;

  /// Input field label for delivery/transport expense
  ///
  /// In en, this message translates to:
  /// **'Transport Cost'**
  String get transportCost;

  /// Input field label for date of purchase
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get purchaseDate;

  /// Input field label for invoice reference number
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// Button label for creating an invoice document
  ///
  /// In en, this message translates to:
  /// **'Generate Invoice'**
  String get generateInvoice;

  /// Button label for printing an invoice
  ///
  /// In en, this message translates to:
  /// **'Print Invoice'**
  String get printInvoice;

  /// Button label for sharing an invoice via other apps
  ///
  /// In en, this message translates to:
  /// **'Share Invoice'**
  String get shareInvoice;

  /// Button label for downloading invoice as PDF
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// Input field label for the user's business name in settings
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// Input field label for the user's business address in settings
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get businessAddress;

  /// Input field label for the user's business phone in settings
  ///
  /// In en, this message translates to:
  /// **'Business Phone'**
  String get businessPhone;

  /// Report type: daily summary
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dailyReport;

  /// Report type: weekly summary
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// Report type: monthly summary
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// Report type: profit and loss statement
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get profitLoss;

  /// Report type: inventory status summary
  ///
  /// In en, this message translates to:
  /// **'Inventory Report'**
  String get inventoryReport;

  /// Report type: sales performance summary
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get salesReport;

  /// Report type: outstanding debts summary
  ///
  /// In en, this message translates to:
  /// **'Debt Report'**
  String get debtReport;

  /// Button label for exporting data as PDF
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// Button label for exporting data as Excel spreadsheet
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// Label for the current synchronization state
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// Sync status: data is fully synced with cloud
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// Sync status: data is waiting to be synced
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get pendingSyncLabel;

  /// Sync status: data is currently being synced
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// Sync status: synchronization encountered an error
  ///
  /// In en, this message translates to:
  /// **'Sync Failed'**
  String get syncFailed;

  /// Connectivity status: device is connected to internet
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Connectivity status: device has no internet connection
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// Label for the timestamp of last successful sync
  ///
  /// In en, this message translates to:
  /// **'Last Synced'**
  String get lastSynced;

  /// Button label to trigger manual sync
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// Theme option: light color scheme
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Theme option: dark color scheme
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Settings label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Settings label for currency selection
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Navigation label for employee management section
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// Button label for adding a new employee
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// Button/page title for editing an employee
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// Input field label for employee role
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// Employee role: administrator with full access
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// Employee role: standard employee with limited access
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// Page title for system activity/audit log
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// Button label for creating a data backup
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// Button label for restoring data from backup
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Generic confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic edit button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Generic add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Generic search button/field label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Generic filter button label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Generic clear/reset button label
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Empty state message when no data exists
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error;

  /// Button label to retry a failed operation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Generic success message/title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// Confirmation dialog message for delete action
  ///
  /// In en, this message translates to:
  /// **'This item will be permanently deleted.'**
  String get deleteConfirmation;

  /// Warning text shown in destructive action confirmations
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotUndo;

  /// Input field label for general notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Generic date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Label for creation timestamp
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// Label for last update timestamp
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// Generic total label for summations
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Generic average label for statistics
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// Generic count label for statistics
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// Generic minimum label for statistics
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get minimum;

  /// Generic maximum label for statistics
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get maximum;

  /// Date range filter: current day
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Date range filter: current week
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Date range filter: current month
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Date range filter: current year
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// Date range filter: custom date range
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// Label for custom date range selector
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// Filter option: show all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Status filter: active items
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Status filter: inactive items
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Welcome greeting for first-time users
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Welcome greeting for returning users
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Warning message when a product's stock falls below the minimum threshold
  ///
  /// In en, this message translates to:
  /// **'{productName} is running low ({quantity} remaining)'**
  String lowStockWarning(String productName, int quantity);

  /// Reminder message showing a customer's unpaid debt amount
  ///
  /// In en, this message translates to:
  /// **'{customerName} has outstanding debt of {amount}'**
  String debtReminder(String customerName, String amount);

  /// Success message after creating a new sale
  ///
  /// In en, this message translates to:
  /// **'Sale #{invoiceNumber} created successfully'**
  String saleCreated(String invoiceNumber);

  /// Success message after recording a payment
  ///
  /// In en, this message translates to:
  /// **'Payment of {amount} recorded'**
  String paymentRecorded(String amount);

  /// Success message after adding a new product
  ///
  /// In en, this message translates to:
  /// **'{productName} added to inventory'**
  String productAdded(String productName);

  /// Success message when all pending data has been synced
  ///
  /// In en, this message translates to:
  /// **'All data synced successfully'**
  String get syncComplete;

  /// Status message showing number of items waiting to sync
  ///
  /// In en, this message translates to:
  /// **'{count} items pending sync'**
  String syncPending(int count);

  /// Error message when device has no network connectivity
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// Iraqi Dinar currency symbol, same across all locales
  ///
  /// In en, this message translates to:
  /// **'IQD'**
  String get currencySymbol;

  /// Full name of the Iraqi Dinar currency
  ///
  /// In en, this message translates to:
  /// **'IQD'**
  String get iraqiDinar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ku'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ku':
      return AppLocalizationsKu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
