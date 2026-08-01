import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

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
    Locale('en'),
    Locale('gu'),
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Floraprise'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyDesigns.
  ///
  /// In en, this message translates to:
  /// **'My Designs'**
  String get navMyDesigns;

  /// No description provided for @navWalkinSales.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Sales'**
  String get navWalkinSales;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get navBarcode;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @inventoryShortcut.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryShortcut;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @lowStockItems.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get lowStockItems;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search Product'**
  String get searchProduct;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @categoryFlowers.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get categoryFlowers;

  /// No description provided for @categoryHardGoods.
  ///
  /// In en, this message translates to:
  /// **'Hard Goods'**
  String get categoryHardGoods;

  /// No description provided for @categoryAddons.
  ///
  /// In en, this message translates to:
  /// **'Add-ons'**
  String get categoryAddons;

  /// No description provided for @productList.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productList;

  /// No description provided for @productDetail.
  ///
  /// In en, this message translates to:
  /// **'Product Detail'**
  String get productDetail;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @purchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get purchasePrice;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPrice;

  /// No description provided for @gstPercent.
  ///
  /// In en, this message translates to:
  /// **'GST %'**
  String get gstPercent;

  /// No description provided for @currentStock.
  ///
  /// In en, this message translates to:
  /// **'Current Stock'**
  String get currentStock;

  /// No description provided for @minimumStock.
  ///
  /// In en, this message translates to:
  /// **'Minimum Stock'**
  String get minimumStock;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @addStock.
  ///
  /// In en, this message translates to:
  /// **'Add Stock'**
  String get addStock;

  /// No description provided for @removeStock.
  ///
  /// In en, this message translates to:
  /// **'Remove Stock'**
  String get removeStock;

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get adjustStock;

  /// No description provided for @stockHistory.
  ///
  /// In en, this message translates to:
  /// **'Stock history'**
  String get stockHistory;

  /// No description provided for @generateBarcode.
  ///
  /// In en, this message translates to:
  /// **'Generate barcode'**
  String get generateBarcode;

  /// No description provided for @printBarcode.
  ///
  /// In en, this message translates to:
  /// **'Print barcode'**
  String get printBarcode;

  /// No description provided for @barcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcode Management'**
  String get barcodeTitle;

  /// No description provided for @scanBarcodeBtn.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcodeBtn;

  /// No description provided for @generateBarcodeBtn.
  ///
  /// In en, this message translates to:
  /// **'Generate Barcode'**
  String get generateBarcodeBtn;

  /// No description provided for @printBarcodeBtn.
  ///
  /// In en, this message translates to:
  /// **'Print Barcode'**
  String get printBarcodeBtn;

  /// No description provided for @searchProductBarcode.
  ///
  /// In en, this message translates to:
  /// **'Search Product'**
  String get searchProductBarcode;

  /// No description provided for @barcodePreview.
  ///
  /// In en, this message translates to:
  /// **'Barcode Preview'**
  String get barcodePreview;

  /// No description provided for @manufacturerBarcode.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer Barcode'**
  String get manufacturerBarcode;

  /// No description provided for @floristBarcode.
  ///
  /// In en, this message translates to:
  /// **'Florist Generated Barcode'**
  String get floristBarcode;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @gst.
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get gst;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @gstRate0.
  ///
  /// In en, this message translates to:
  /// **'0%'**
  String get gstRate0;

  /// No description provided for @gstRate5.
  ///
  /// In en, this message translates to:
  /// **'5%'**
  String get gstRate5;

  /// No description provided for @gstRate12.
  ///
  /// In en, this message translates to:
  /// **'12%'**
  String get gstRate12;

  /// No description provided for @gstRate18.
  ///
  /// In en, this message translates to:
  /// **'18%'**
  String get gstRate18;

  /// No description provided for @walkinSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Sales'**
  String get walkinSalesTitle;

  /// No description provided for @howCustomerReceive.
  ///
  /// In en, this message translates to:
  /// **'How will the customer receive the order?'**
  String get howCustomerReceive;

  /// No description provided for @takeAway.
  ///
  /// In en, this message translates to:
  /// **'Take Away'**
  String get takeAway;

  /// No description provided for @takeAwayDesc.
  ///
  /// In en, this message translates to:
  /// **'Customer takes now'**
  String get takeAwayDesc;

  /// No description provided for @pickupLater.
  ///
  /// In en, this message translates to:
  /// **'Pickup Later'**
  String get pickupLater;

  /// No description provided for @pickupLaterDesc.
  ///
  /// In en, this message translates to:
  /// **'Customer picks up later'**
  String get pickupLaterDesc;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @deliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Deliver to address'**
  String get deliveryDesc;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @addAnotherProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Another Product'**
  String get addAnotherProduct;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @occasion.
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get occasion;

  /// No description provided for @existingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Existing Customer'**
  String get existingCustomer;

  /// No description provided for @previousOrders.
  ///
  /// In en, this message translates to:
  /// **'Previous Orders'**
  String get previousOrders;

  /// No description provided for @lifetimePurchase.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Purchase'**
  String get lifetimePurchase;

  /// No description provided for @lastOrder.
  ///
  /// In en, this message translates to:
  /// **'Last Order'**
  String get lastOrder;

  /// No description provided for @favouriteDesign.
  ///
  /// In en, this message translates to:
  /// **'Favourite Design'**
  String get favouriteDesign;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @upi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upi;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @saveOrder.
  ///
  /// In en, this message translates to:
  /// **'Save Order'**
  String get saveOrder;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @orderSaved.
  ///
  /// In en, this message translates to:
  /// **'Order Saved'**
  String get orderSaved;

  /// No description provided for @orderSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Order has been saved and added to Scheduler!'**
  String get orderSavedMessage;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @printBill.
  ///
  /// In en, this message translates to:
  /// **'Print Bill'**
  String get printBill;

  /// No description provided for @shareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share WhatsApp'**
  String get shareWhatsApp;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved successfully'**
  String get draftSaved;

  /// No description provided for @printingBill.
  ///
  /// In en, this message translates to:
  /// **'Printing bill...'**
  String get printingBill;

  /// No description provided for @sharingWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Sharing on WhatsApp...'**
  String get sharingWhatsApp;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get selectPaymentMethod;

  /// No description provided for @selectDeliveryDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select delivery date and time'**
  String get selectDeliveryDateTime;

  /// No description provided for @selectPickupDateTime.
  ///
  /// In en, this message translates to:
  /// **'Please select pickup date and time'**
  String get selectPickupDateTime;

  /// No description provided for @pickupSchedule.
  ///
  /// In en, this message translates to:
  /// **'Pickup Schedule'**
  String get pickupSchedule;

  /// No description provided for @selectPickupDate.
  ///
  /// In en, this message translates to:
  /// **'Select Pickup Date'**
  String get selectPickupDate;

  /// No description provided for @selectPickupTime.
  ///
  /// In en, this message translates to:
  /// **'Select Pickup Time'**
  String get selectPickupTime;

  /// No description provided for @deliveryInfo.
  ///
  /// In en, this message translates to:
  /// **'Delivery Info'**
  String get deliveryInfo;

  /// No description provided for @recipientName.
  ///
  /// In en, this message translates to:
  /// **'Recipient Name'**
  String get recipientName;

  /// No description provided for @recipientPhone.
  ///
  /// In en, this message translates to:
  /// **'Recipient Phone'**
  String get recipientPhone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'Pin Code'**
  String get pinCode;

  /// No description provided for @landmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery Date'**
  String get deliveryDate;

  /// No description provided for @preferredTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred Time'**
  String get preferredTime;

  /// No description provided for @cardMessage.
  ///
  /// In en, this message translates to:
  /// **'Card Message'**
  String get cardMessage;

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get specialInstructions;

  /// No description provided for @senderInfo.
  ///
  /// In en, this message translates to:
  /// **'Sender Info'**
  String get senderInfo;

  /// No description provided for @senderName.
  ///
  /// In en, this message translates to:
  /// **'Sender Name'**
  String get senderName;

  /// No description provided for @senderPhone.
  ///
  /// In en, this message translates to:
  /// **'Sender Phone'**
  String get senderPhone;

  /// No description provided for @myDesignsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Designs'**
  String get myDesignsTitle;

  /// No description provided for @allDesigns.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allDesigns;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get filterBy;

  /// No description provided for @flower.
  ///
  /// In en, this message translates to:
  /// **'Flower'**
  String get flower;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @designDetail.
  ///
  /// In en, this message translates to:
  /// **'Design Detail'**
  String get designDetail;

  /// No description provided for @addToOrder.
  ///
  /// In en, this message translates to:
  /// **'Add to Order'**
  String get addToOrder;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get hindi;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી'**
  String get gujarati;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @todayIs.
  ///
  /// In en, this message translates to:
  /// **'Today is'**
  String get todayIs;

  /// No description provided for @youHave.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get youHave;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @pickups.
  ///
  /// In en, this message translates to:
  /// **'Pickups'**
  String get pickups;

  /// No description provided for @ordersToPrepare.
  ///
  /// In en, this message translates to:
  /// **'Orders to Prepare'**
  String get ordersToPrepare;

  /// No description provided for @haveWonderfulDay.
  ///
  /// In en, this message translates to:
  /// **'Have a wonderful day!'**
  String get haveWonderfulDay;

  /// No description provided for @everydayAppForFlorists.
  ///
  /// In en, this message translates to:
  /// **'Everyday App for Florists'**
  String get everydayAppForFlorists;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaySales;

  /// No description provided for @todayOrders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get todayOrders;

  /// No description provided for @todayDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Deliveries'**
  String get todayDeliveries;

  /// No description provided for @todayTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todayTasks;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// No description provided for @preparingOrders.
  ///
  /// In en, this message translates to:
  /// **'Preparing Orders'**
  String get preparingOrders;

  /// No description provided for @readyOrders.
  ///
  /// In en, this message translates to:
  /// **'Ready Orders'**
  String get readyOrders;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out For Delivery'**
  String get outForDelivery;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStockCount;

  /// No description provided for @flowerOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Flower of the Day'**
  String get flowerOfTheDay;

  /// No description provided for @workspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaces;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaySchedule;

  /// No description provided for @shopDetails.
  ///
  /// In en, this message translates to:
  /// **'Shop Details'**
  String get shopDetails;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice Input'**
  String get voiceInput;

  /// No description provided for @voiceInputDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable voice dictation for text fields'**
  String get voiceInputDesc;

  /// No description provided for @howCustomerReceiveOrder.
  ///
  /// In en, this message translates to:
  /// **'How will the customer receive the order?'**
  String get howCustomerReceiveOrder;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get notificationsOn;

  /// No description provided for @businessSettings.
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSettings;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;

  /// No description provided for @shopAddress.
  ///
  /// In en, this message translates to:
  /// **'Shop Address'**
  String get shopAddress;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @currencyINR.
  ///
  /// In en, this message translates to:
  /// **'₹ (INR)'**
  String get currencyINR;

  /// No description provided for @dataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataStorage;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backupData;

  /// No description provided for @lastBackupToday.
  ///
  /// In en, this message translates to:
  /// **'Last backup: Today'**
  String get lastBackupToday;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportToCSV.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get exportToCSV;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @deleteAllAppData.
  ///
  /// In en, this message translates to:
  /// **'Delete all app data'**
  String get deleteAllAppData;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @faqsAndGuides.
  ///
  /// In en, this message translates to:
  /// **'FAQs and guides'**
  String get faqsAndGuides;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @getHelpFromTeam.
  ///
  /// In en, this message translates to:
  /// **'Get help from our team'**
  String get getHelpFromTeam;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareFeedback.
  ///
  /// In en, this message translates to:
  /// **'Share your feedback'**
  String get shareFeedback;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ for Indian Florists'**
  String get madeWithLove;

  /// No description provided for @walkinSales.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Sales'**
  String get walkinSales;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @scanBarcodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan product barcode'**
  String get scanBarcodeDesc;

  /// No description provided for @myDesigns.
  ///
  /// In en, this message translates to:
  /// **'My Designs'**
  String get myDesigns;

  /// No description provided for @myDesignsDesc.
  ///
  /// In en, this message translates to:
  /// **'Select from design library'**
  String get myDesignsDesc;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @searchStaff.
  ///
  /// In en, this message translates to:
  /// **'Search by staff ID, name, role...'**
  String get searchStaff;

  /// No description provided for @filterStaff.
  ///
  /// In en, this message translates to:
  /// **'Filter Staff'**
  String get filterStaff;

  /// No description provided for @searchOrders.
  ///
  /// In en, this message translates to:
  /// **'Search orders...'**
  String get searchOrders;

  /// No description provided for @filterOrders.
  ///
  /// In en, this message translates to:
  /// **'Filter Orders'**
  String get filterOrders;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomers;

  /// No description provided for @filterCustomers.
  ///
  /// In en, this message translates to:
  /// **'Filter Customers'**
  String get filterCustomers;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @filterProducts.
  ///
  /// In en, this message translates to:
  /// **'Filter Products'**
  String get filterProducts;

  /// No description provided for @searchInventory.
  ///
  /// In en, this message translates to:
  /// **'Search inventory...'**
  String get searchInventory;

  /// No description provided for @filterInventory.
  ///
  /// In en, this message translates to:
  /// **'Filter Inventory'**
  String get filterInventory;

  /// No description provided for @searchDesigns.
  ///
  /// In en, this message translates to:
  /// **'Search designs...'**
  String get searchDesigns;

  /// No description provided for @filterDesigns.
  ///
  /// In en, this message translates to:
  /// **'Filter Designs'**
  String get filterDesigns;

  /// No description provided for @searchReminders.
  ///
  /// In en, this message translates to:
  /// **'Search reminders...'**
  String get searchReminders;

  /// No description provided for @filterReminders.
  ///
  /// In en, this message translates to:
  /// **'Filter Reminders'**
  String get filterReminders;

  /// No description provided for @allOrders.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get allOrders;

  /// No description provided for @confirmedOrders.
  ///
  /// In en, this message translates to:
  /// **'Confirmed Orders'**
  String get confirmedOrders;

  /// No description provided for @deliveredOrders.
  ///
  /// In en, this message translates to:
  /// **'Delivered Orders'**
  String get deliveredOrders;

  /// No description provided for @cancelledOrders.
  ///
  /// In en, this message translates to:
  /// **'Cancelled Orders'**
  String get cancelledOrders;

  /// No description provided for @allCustomers.
  ///
  /// In en, this message translates to:
  /// **'All Customers'**
  String get allCustomers;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @activeProducts.
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get activeProducts;

  /// No description provided for @inactiveProducts.
  ///
  /// In en, this message translates to:
  /// **'Inactive Products'**
  String get inactiveProducts;

  /// No description provided for @allStaff.
  ///
  /// In en, this message translates to:
  /// **'All Staff'**
  String get allStaff;

  /// No description provided for @activeStaff.
  ///
  /// In en, this message translates to:
  /// **'Active Staff'**
  String get activeStaff;

  /// No description provided for @inactiveStaff.
  ///
  /// In en, this message translates to:
  /// **'Inactive Staff'**
  String get inactiveStaff;

  /// No description provided for @allReminders.
  ///
  /// In en, this message translates to:
  /// **'All Reminders'**
  String get allReminders;

  /// No description provided for @todayReminders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reminders'**
  String get todayReminders;

  /// No description provided for @upcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Reminders'**
  String get upcomingReminders;

  /// No description provided for @completedReminders.
  ///
  /// In en, this message translates to:
  /// **'Completed Reminders'**
  String get completedReminders;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get addStaff;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @editStaff.
  ///
  /// In en, this message translates to:
  /// **'Edit Staff'**
  String get editStaff;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// No description provided for @deleteCustomer.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get deleteCustomer;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteStaff.
  ///
  /// In en, this message translates to:
  /// **'Delete Staff'**
  String get deleteStaff;

  /// No description provided for @deleteReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminder;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDeleteMessage;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @noStaffFound.
  ///
  /// In en, this message translates to:
  /// **'No staff found'**
  String get noStaffFound;

  /// No description provided for @noRemindersFound.
  ///
  /// In en, this message translates to:
  /// **'No reminders found'**
  String get noRemindersFound;

  /// No description provided for @noDesignsFound.
  ///
  /// In en, this message translates to:
  /// **'No designs found'**
  String get noDesignsFound;

  /// No description provided for @loadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading orders...'**
  String get loadingOrders;

  /// No description provided for @loadingCustomers.
  ///
  /// In en, this message translates to:
  /// **'Loading customers...'**
  String get loadingCustomers;

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @loadingStaff.
  ///
  /// In en, this message translates to:
  /// **'Loading staff...'**
  String get loadingStaff;

  /// No description provided for @loadingReminders.
  ///
  /// In en, this message translates to:
  /// **'Loading reminders...'**
  String get loadingReminders;

  /// No description provided for @loadingDesigns.
  ///
  /// In en, this message translates to:
  /// **'Loading designs...'**
  String get loadingDesigns;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @productCode.
  ///
  /// In en, this message translates to:
  /// **'Product Code'**
  String get productCode;

  /// No description provided for @minStock.
  ///
  /// In en, this message translates to:
  /// **'Min Stock'**
  String get minStock;

  /// No description provided for @stockLevel.
  ///
  /// In en, this message translates to:
  /// **'Stock Level'**
  String get stockLevel;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @stockTransaction.
  ///
  /// In en, this message translates to:
  /// **'Stock Transaction'**
  String get stockTransaction;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @staffId.
  ///
  /// In en, this message translates to:
  /// **'Staff ID'**
  String get staffId;

  /// No description provided for @staffName.
  ///
  /// In en, this message translates to:
  /// **'Staff Name'**
  String get staffName;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Title'**
  String get reminderTitle;

  /// No description provided for @reminderDate.
  ///
  /// In en, this message translates to:
  /// **'Reminder Date'**
  String get reminderDate;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @reminderNotes.
  ///
  /// In en, this message translates to:
  /// **'Reminder Notes'**
  String get reminderNotes;

  /// No description provided for @designName.
  ///
  /// In en, this message translates to:
  /// **'Design Name'**
  String get designName;

  /// No description provided for @designImage.
  ///
  /// In en, this message translates to:
  /// **'Design Image'**
  String get designImage;

  /// No description provided for @designPrice.
  ///
  /// In en, this message translates to:
  /// **'Design Price'**
  String get designPrice;

  /// No description provided for @createDesign.
  ///
  /// In en, this message translates to:
  /// **'Create Design'**
  String get createDesign;

  /// No description provided for @selectDesign.
  ///
  /// In en, this message translates to:
  /// **'Select Design'**
  String get selectDesign;

  /// No description provided for @designLibrary.
  ///
  /// In en, this message translates to:
  /// **'Design Library'**
  String get designLibrary;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @staffDetails.
  ///
  /// In en, this message translates to:
  /// **'Staff Details'**
  String get staffDetails;

  /// No description provided for @reminderDetails.
  ///
  /// In en, this message translates to:
  /// **'Reminder Details'**
  String get reminderDetails;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumber;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatus;

  /// No description provided for @orderType.
  ///
  /// In en, this message translates to:
  /// **'Order Type'**
  String get orderType;

  /// No description provided for @fulfilmentType.
  ///
  /// In en, this message translates to:
  /// **'Fulfilment Type'**
  String get fulfilmentType;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer Phone'**
  String get customerPhone;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @balanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Balance Amount'**
  String get balanceAmount;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @netBanking.
  ///
  /// In en, this message translates to:
  /// **'Net Banking'**
  String get netBanking;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @partiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get partiallyPaid;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @startPreparing.
  ///
  /// In en, this message translates to:
  /// **'Start Preparing'**
  String get startPreparing;

  /// No description provided for @markReady.
  ///
  /// In en, this message translates to:
  /// **'Mark Ready'**
  String get markReady;

  /// No description provided for @startDelivery.
  ///
  /// In en, this message translates to:
  /// **'Start Delivery'**
  String get startDelivery;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get markDelivered;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt'**
  String get shareReceipt;

  /// No description provided for @whatsappShare.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Share'**
  String get whatsappShare;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed'**
  String get orderConfirmed;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order Cancelled'**
  String get orderCancelled;

  /// No description provided for @orderPreparing.
  ///
  /// In en, this message translates to:
  /// **'Order Preparing'**
  String get orderPreparing;

  /// No description provided for @orderReady.
  ///
  /// In en, this message translates to:
  /// **'Order Ready'**
  String get orderReady;

  /// No description provided for @orderOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Order Out For Delivery'**
  String get orderOutForDelivery;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order Delivered'**
  String get orderDelivered;

  /// No description provided for @customerAdded.
  ///
  /// In en, this message translates to:
  /// **'Customer Added'**
  String get customerAdded;

  /// No description provided for @customerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer Updated'**
  String get customerUpdated;

  /// No description provided for @customerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Customer Deleted'**
  String get customerDeleted;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product Added'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product Updated'**
  String get productUpdated;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product Deleted'**
  String get productDeleted;

  /// No description provided for @staffAdded.
  ///
  /// In en, this message translates to:
  /// **'Staff Added'**
  String get staffAdded;

  /// No description provided for @staffUpdated.
  ///
  /// In en, this message translates to:
  /// **'Staff Updated'**
  String get staffUpdated;

  /// No description provided for @staffDeleted.
  ///
  /// In en, this message translates to:
  /// **'Staff Deleted'**
  String get staffDeleted;

  /// No description provided for @reminderAdded.
  ///
  /// In en, this message translates to:
  /// **'Reminder Added'**
  String get reminderAdded;

  /// No description provided for @reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder Updated'**
  String get reminderUpdated;

  /// No description provided for @reminderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reminder Deleted'**
  String get reminderDeleted;

  /// No description provided for @designAdded.
  ///
  /// In en, this message translates to:
  /// **'Design Added'**
  String get designAdded;

  /// No description provided for @designUpdated.
  ///
  /// In en, this message translates to:
  /// **'Design Updated'**
  String get designUpdated;

  /// No description provided for @designDeleted.
  ///
  /// In en, this message translates to:
  /// **'Design Deleted'**
  String get designDeleted;

  /// No description provided for @stockUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stock Updated'**
  String get stockUpdated;

  /// No description provided for @invalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid Input'**
  String get invalidInput;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @pleaseEnterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhone;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @pleaseEnterValidDate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid date'**
  String get pleaseEnterValidDate;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @operationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation Successful'**
  String get operationSuccess;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation Failed'**
  String get operationFailed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// No description provided for @pleaseCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get pleaseCheckConnection;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get serverError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Timeout Error'**
  String get timeoutError;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get cameraPermissionRequired;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required'**
  String get storagePermissionRequired;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermissionRequired;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @qrBarcodeScanningReserved.
  ///
  /// In en, this message translates to:
  /// **'QR/Barcode scanning reserved for future implementation'**
  String get qrBarcodeScanningReserved;

  /// No description provided for @navigateToMyDesigns.
  ///
  /// In en, this message translates to:
  /// **'Navigate to My Designs - placeholder'**
  String get navigateToMyDesigns;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogoutMessage;

  /// No description provided for @assignedOrders.
  ///
  /// In en, this message translates to:
  /// **'Assigned Orders'**
  String get assignedOrders;

  /// No description provided for @currentTask.
  ///
  /// In en, this message translates to:
  /// **'Current Task'**
  String get currentTask;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @searchByOrderIdCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search by order ID, customer...'**
  String get searchByOrderIdCustomer;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @fulfilment.
  ///
  /// In en, this message translates to:
  /// **'Fulfilment'**
  String get fulfilment;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @relay.
  ///
  /// In en, this message translates to:
  /// **'Relay'**
  String get relay;

  /// No description provided for @corporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get corporate;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @searchByCustomerIdNamePhone.
  ///
  /// In en, this message translates to:
  /// **'Search by customer ID, name, phone...'**
  String get searchByCustomerIdNamePhone;

  /// No description provided for @pendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Pending Payment'**
  String get pendingPayment;

  /// No description provided for @birthdayMonth.
  ///
  /// In en, this message translates to:
  /// **'Birthday Month'**
  String get birthdayMonth;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @searchByProductStockCategory.
  ///
  /// In en, this message translates to:
  /// **'Search by product, stock, category...'**
  String get searchByProductStockCategory;

  /// No description provided for @flowers.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get flowers;

  /// No description provided for @readyProducts.
  ///
  /// In en, this message translates to:
  /// **'Ready Products'**
  String get readyProducts;

  /// No description provided for @addons.
  ///
  /// In en, this message translates to:
  /// **'Add-ons'**
  String get addons;

  /// No description provided for @barcodeScannerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Barcode scanner coming soon'**
  String get barcodeScannerComingSoon;

  /// No description provided for @lowStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStockLabel;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @searchByIdFlowerColorOccasion.
  ///
  /// In en, this message translates to:
  /// **'Search by ID, flower, color, occasion...'**
  String get searchByIdFlowerColorOccasion;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @addDesign.
  ///
  /// In en, this message translates to:
  /// **'Add Design'**
  String get addDesign;

  /// No description provided for @scheduler.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get scheduler;

  /// No description provided for @noTasksForToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today and overdue queue.'**
  String get noTasksForToday;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @scanBarcodeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode coming soon'**
  String get scanBarcodeComingSoon;

  /// No description provided for @generateNewFloristBarcode.
  ///
  /// In en, this message translates to:
  /// **'Generate a new florist barcode for a product'**
  String get generateNewFloristBarcode;

  /// No description provided for @productIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Product ID (Optional)'**
  String get productIdOptional;

  /// No description provided for @barcodeGenerated.
  ///
  /// In en, this message translates to:
  /// **'Barcode generated'**
  String get barcodeGenerated;

  /// No description provided for @todaysBirthdays.
  ///
  /// In en, this message translates to:
  /// **'🎂 Today\'s Birthdays'**
  String get todaysBirthdays;

  /// No description provided for @todaysAnniversaries.
  ///
  /// In en, this message translates to:
  /// **'💕 Today\'s Anniversaries'**
  String get todaysAnniversaries;

  /// No description provided for @paymentFollowup.
  ///
  /// In en, this message translates to:
  /// **'💰 Payment Follow-up'**
  String get paymentFollowup;

  /// No description provided for @festivalReminders.
  ///
  /// In en, this message translates to:
  /// **'🎉 Festival Reminders'**
  String get festivalReminders;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount: '**
  String get discountLabel;

  /// No description provided for @occasionOptional.
  ///
  /// In en, this message translates to:
  /// **'Occasion (Optional)'**
  String get occasionOptional;

  /// No description provided for @mixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get mixed;

  /// No description provided for @scanProductBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan product barcode'**
  String get scanProductBarcode;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take Picture'**
  String get takePicture;

  /// No description provided for @captureProductPhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture product photo'**
  String get captureProductPhoto;

  /// No description provided for @selectFromDesignLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select from design library'**
  String get selectFromDesignLibrary;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @typeProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Type product details'**
  String get typeProductDetails;

  /// No description provided for @cameraUiPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Camera UI - placeholder'**
  String get cameraUiPlaceholder;

  /// No description provided for @designIdOrDescription.
  ///
  /// In en, this message translates to:
  /// **'Design ID or Description'**
  String get designIdOrDescription;

  /// No description provided for @eG20RedRosesCustomArrangement.
  ///
  /// In en, this message translates to:
  /// **'e.g., 20 Red Roses, Custom Arrangement'**
  String get eG20RedRosesCustomArrangement;

  /// No description provided for @eG850.
  ///
  /// In en, this message translates to:
  /// **'e.g., ₹850'**
  String get eG850;

  /// No description provided for @discountOptional.
  ///
  /// In en, this message translates to:
  /// **'Discount (Optional)'**
  String get discountOptional;

  /// No description provided for @eG50.
  ///
  /// In en, this message translates to:
  /// **'e.g., ₹50'**
  String get eG50;

  /// No description provided for @pickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup Date'**
  String get pickupDate;

  /// No description provided for @pickupTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup Time'**
  String get pickupTime;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @pleaseSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectPaymentMethod;

  /// No description provided for @pleaseSelectPickupDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Please select pickup date and time'**
  String get pleaseSelectPickupDateAndTime;

  /// No description provided for @orderSavedAndAddedToScheduler.
  ///
  /// In en, this message translates to:
  /// **'Order has been saved and added to Scheduler!'**
  String get orderSavedAndAddedToScheduler;

  /// No description provided for @draftSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Draft saved successfully'**
  String get draftSavedSuccessfully;

  /// No description provided for @couldNotSaveOrder.
  ///
  /// In en, this message translates to:
  /// **'Could not save order'**
  String get couldNotSaveOrder;

  /// No description provided for @deliverySchedule.
  ///
  /// In en, this message translates to:
  /// **'Delivery Schedule'**
  String get deliverySchedule;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// No description provided for @pleaseSelectDeliveryDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Please select delivery date and time'**
  String get pleaseSelectDeliveryDateAndTime;

  /// No description provided for @billingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Billing Customer'**
  String get billingCustomer;

  /// No description provided for @orderSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order has been saved successfully!'**
  String get orderSavedSuccessfully;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @stockAdded.
  ///
  /// In en, this message translates to:
  /// **'Stock added'**
  String get stockAdded;

  /// No description provided for @stockRemoved.
  ///
  /// In en, this message translates to:
  /// **'Stock removed'**
  String get stockRemoved;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @wedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get wedding;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @seasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get seasonal;

  /// No description provided for @customerProfile.
  ///
  /// In en, this message translates to:
  /// **'Customer Profile'**
  String get customerProfile;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @customerAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully'**
  String get customerAddedSuccessfully;

  /// No description provided for @failedToAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Failed to add customer'**
  String get failedToAddCustomer;

  /// No description provided for @customerUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully'**
  String get customerUpdatedSuccessfully;

  /// No description provided for @failedToUpdateCustomer.
  ///
  /// In en, this message translates to:
  /// **'Failed to update customer'**
  String get failedToUpdateCustomer;

  /// No description provided for @customerDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted successfully'**
  String get customerDeletedSuccessfully;

  /// No description provided for @failedToDeleteCustomer.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete customer'**
  String get failedToDeleteCustomer;

  /// No description provided for @deleteCustomerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteCustomerConfirm;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @priceRangeExamples.
  ///
  /// In en, this message translates to:
  /// **'Under ₹100, ₹100-₹500, ₹500+'**
  String get priceRangeExamples;

  /// No description provided for @mostSoldItems.
  ///
  /// In en, this message translates to:
  /// **'Most sold items'**
  String get mostSoldItems;

  /// No description provided for @purchaseList.
  ///
  /// In en, this message translates to:
  /// **'Purchase List'**
  String get purchaseList;

  /// No description provided for @todayPurchaseList.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Purchase List'**
  String get todayPurchaseList;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchased;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @generateAutoSuggest.
  ///
  /// In en, this message translates to:
  /// **'Generate Auto-Suggest'**
  String get generateAutoSuggest;

  /// No description provided for @autoSuggestDescription.
  ///
  /// In en, this message translates to:
  /// **'Add items where Current Stock < Minimum Stock'**
  String get autoSuggestDescription;

  /// No description provided for @clearPurchased.
  ///
  /// In en, this message translates to:
  /// **'Clear Purchased'**
  String get clearPurchased;

  /// No description provided for @clearPurchasedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all purchased items?'**
  String get clearPurchasedConfirm;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items in purchase list'**
  String get noItems;

  /// No description provided for @addFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add your first item'**
  String get addFirstItem;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter Quantity'**
  String get enterQuantity;

  /// No description provided for @enterSupplier.
  ///
  /// In en, this message translates to:
  /// **'Enter Supplier (Optional)'**
  String get enterSupplier;

  /// No description provided for @enterRemarks.
  ///
  /// In en, this message translates to:
  /// **'Enter Remarks (Optional)'**
  String get enterRemarks;

  /// No description provided for @itemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added successfully'**
  String get itemAdded;

  /// No description provided for @itemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated successfully'**
  String get itemUpdated;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted successfully'**
  String get itemDeleted;

  /// No description provided for @failedToAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item'**
  String get failedToAdd;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update item'**
  String get failedToUpdate;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item'**
  String get failedToDelete;

  /// No description provided for @fillers.
  ///
  /// In en, this message translates to:
  /// **'Fillers'**
  String get fillers;

  /// No description provided for @foliage.
  ///
  /// In en, this message translates to:
  /// **'Foliage'**
  String get foliage;

  /// No description provided for @packing.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get packing;

  /// No description provided for @accessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get accessories;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @onboardingChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get onboardingChooseLanguage;

  /// No description provided for @onboardingPoweringModernFlorists.
  ///
  /// In en, this message translates to:
  /// **'Powering Modern Florists'**
  String get onboardingPoweringModernFlorists;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Floraprise!'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Run your florist business with\nBilling, Inventory, Orders,\nCustomers, Delivery,\nReminders and much more.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingBusinessSetup.
  ///
  /// In en, this message translates to:
  /// **'Business Setup'**
  String get onboardingBusinessSetup;

  /// No description provided for @onboardingShopNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Shop Name *'**
  String get onboardingShopNameRequired;

  /// No description provided for @onboardingMobileNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number *'**
  String get onboardingMobileNumberRequired;

  /// No description provided for @onboardingUseSameWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Use same number for WhatsApp'**
  String get onboardingUseSameWhatsapp;

  /// No description provided for @onboardingWhatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get onboardingWhatsappNumber;

  /// No description provided for @onboardingGstRegisteredRequired.
  ///
  /// In en, this message translates to:
  /// **'GST Registered *'**
  String get onboardingGstRegisteredRequired;

  /// No description provided for @onboardingGstNumber.
  ///
  /// In en, this message translates to:
  /// **'GST Number'**
  String get onboardingGstNumber;

  /// No description provided for @onboardingShopLogoOptional.
  ///
  /// In en, this message translates to:
  /// **'Shop Logo (Optional)'**
  String get onboardingShopLogoOptional;

  /// No description provided for @onboardingLogoSelected.
  ///
  /// In en, this message translates to:
  /// **'Logo Selected'**
  String get onboardingLogoSelected;

  /// No description provided for @onboardingAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get onboardingAddressOptional;

  /// No description provided for @onboardingRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Would you like Floraprise to prepare your shop with a recommended florist setup?'**
  String get onboardingRecommendedTitle;

  /// No description provided for @onboardingRecommendedBody.
  ///
  /// In en, this message translates to:
  /// **'This is recommended for new florist shops.'**
  String get onboardingRecommendedBody;

  /// No description provided for @onboardingRecommendedDefault.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get onboardingRecommendedDefault;

  /// No description provided for @onboardingRecommendedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Install starter categories, products, staff and defaults.'**
  String get onboardingRecommendedSubtitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get onboardingPermissionsTitle;

  /// No description provided for @onboardingContactsPermission.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get onboardingContactsPermission;

  /// No description provided for @onboardingCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get onboardingCameraPermission;

  /// No description provided for @onboardingStoragePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage (if required)'**
  String get onboardingStoragePermission;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingPreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing Your Florist Shop...'**
  String get onboardingPreparingTitle;

  /// No description provided for @onboardingCreatingCategories.
  ///
  /// In en, this message translates to:
  /// **'Creating Categories'**
  String get onboardingCreatingCategories;

  /// No description provided for @onboardingCreatingProducts.
  ///
  /// In en, this message translates to:
  /// **'Creating Products'**
  String get onboardingCreatingProducts;

  /// No description provided for @onboardingCreatingStaff.
  ///
  /// In en, this message translates to:
  /// **'Creating Staff'**
  String get onboardingCreatingStaff;

  /// No description provided for @onboardingConfiguringSettings.
  ///
  /// In en, this message translates to:
  /// **'Configuring Settings'**
  String get onboardingConfiguringSettings;

  /// No description provided for @onboardingReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get onboardingReady;

  /// No description provided for @onboardingSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Setup failed. Please try again.'**
  String get onboardingSetupFailed;

  /// No description provided for @onboardingShopNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Shop name is required.'**
  String get onboardingShopNameRequiredError;

  /// No description provided for @onboardingMobileRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Valid mobile number is required.'**
  String get onboardingMobileRequiredError;

  /// No description provided for @onboardingWhatsappRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Valid WhatsApp number is required.'**
  String get onboardingWhatsappRequiredError;

  /// No description provided for @onboardingGstRequiredError.
  ///
  /// In en, this message translates to:
  /// **'GST number is required.'**
  String get onboardingGstRequiredError;

  /// No description provided for @gettingStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get gettingStartedTitle;

  /// No description provided for @onboardingChecklistShopSetup.
  ///
  /// In en, this message translates to:
  /// **'Shop Setup'**
  String get onboardingChecklistShopSetup;

  /// No description provided for @onboardingChecklistStarterCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Starter Catalogue'**
  String get onboardingChecklistStarterCatalogue;

  /// No description provided for @onboardingChecklistAddFirstCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add First Customer'**
  String get onboardingChecklistAddFirstCustomer;

  /// No description provided for @onboardingChecklistCreateFirstSale.
  ///
  /// In en, this message translates to:
  /// **'Create First Sale'**
  String get onboardingChecklistCreateFirstSale;

  /// No description provided for @onboardingChecklistTestPrinter.
  ///
  /// In en, this message translates to:
  /// **'Test Printer'**
  String get onboardingChecklistTestPrinter;

  /// No description provided for @resetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Reset Onboarding'**
  String get resetOnboarding;

  /// No description provided for @resetOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For demo/testing'**
  String get resetOnboardingSubtitle;

  /// No description provided for @resetOnboardingDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will show first install onboarding again. Continue?'**
  String get resetOnboardingDialogMessage;
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
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
