import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
    Locale('vi'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to Super App'**
  String get signInToContinue;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @quickLogin.
  ///
  /// In en, this message translates to:
  /// **'Quick Login (Test Accounts)'**
  String get quickLogin;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// No description provided for @roleMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get roleMerchant;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'What are you craving?'**
  String get searchPlaceholder;

  /// No description provided for @serviceRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get serviceRide;

  /// No description provided for @serviceFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get serviceFood;

  /// No description provided for @serviceMart.
  ///
  /// In en, this message translates to:
  /// **'Mart'**
  String get serviceMart;

  /// No description provided for @serviceCourier.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get serviceCourier;

  /// No description provided for @serviceGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get serviceGift;

  /// No description provided for @serviceTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get serviceTickets;

  /// No description provided for @serviceMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get serviceMore;

  /// No description provided for @specialOffers.
  ///
  /// In en, this message translates to:
  /// **'Special Offers'**
  String get specialOffers;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature is under development.'**
  String get comingSoonMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @promo1.
  ///
  /// In en, this message translates to:
  /// **'30% Off Rides'**
  String get promo1;

  /// No description provided for @promo2.
  ///
  /// In en, this message translates to:
  /// **'Free Burger'**
  String get promo2;

  /// No description provided for @promo3.
  ///
  /// In en, this message translates to:
  /// **'Grocery Deal'**
  String get promo3;

  /// No description provided for @sectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sectionGeneral;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get sectionSupport;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInfo;

  /// No description provided for @profilePaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get profilePaymentMethods;

  /// No description provided for @profileSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get profileSavedAddresses;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get profileHelpCenter;

  /// No description provided for @profileAboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get profileAboutUs;

  /// No description provided for @profileRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get profileRateApp;

  /// No description provided for @profileLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogOut;

  /// No description provided for @dialogLogOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get dialogLogOutTitle;

  /// No description provided for @dialogLogOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get dialogLogOutMessage;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @dialogEditProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get dialogEditProfileTitle;

  /// No description provided for @dialogDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get dialogDisplayNameLabel;

  /// No description provided for @dialogSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dialogSave;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get gettingLocation;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @enterPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter Pickup Location'**
  String get enterPickupLocation;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @enterPickupAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter pickup address...'**
  String get enterPickupAddress;

  /// No description provided for @enterDestination.
  ///
  /// In en, this message translates to:
  /// **'Enter Destination'**
  String get enterDestination;

  /// No description provided for @nearbyDrivers.
  ///
  /// In en, this message translates to:
  /// **'Nearby Drivers'**
  String get nearbyDrivers;

  /// No description provided for @radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get radius;

  /// No description provided for @selectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectDriver;

  /// No description provided for @noDriversFound.
  ///
  /// In en, this message translates to:
  /// **'No drivers found within {radius}km'**
  String noDriversFound(String radius);

  /// No description provided for @expandRadiusPrompt.
  ///
  /// In en, this message translates to:
  /// **'Do you want to expand the search radius?'**
  String get expandRadiusPrompt;

  /// No description provided for @searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search Again'**
  String get searchAgain;

  /// No description provided for @driverApproaching.
  ///
  /// In en, this message translates to:
  /// **'{name} is approaching!'**
  String driverApproaching(String name);

  /// No description provided for @pleaseSelectRideOption.
  ///
  /// In en, this message translates to:
  /// **'Please select a ride option'**
  String get pleaseSelectRideOption;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @driverInfo.
  ///
  /// In en, this message translates to:
  /// **'Driver/Merchant Info'**
  String get driverInfo;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @orderTime.
  ///
  /// In en, this message translates to:
  /// **'Order Time'**
  String get orderTime;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @popularRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Popular Restaurants'**
  String get popularRestaurants;

  /// No description provided for @promo.
  ///
  /// In en, this message translates to:
  /// **'PROMO'**
  String get promo;

  /// No description provided for @fastDelivery.
  ///
  /// In en, this message translates to:
  /// **'Fast Delivery'**
  String get fastDelivery;

  /// No description provided for @foodCategoryBurger.
  ///
  /// In en, this message translates to:
  /// **'Burger'**
  String get foodCategoryBurger;

  /// No description provided for @foodCategoryPizza.
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get foodCategoryPizza;

  /// No description provided for @foodCategoryAsian.
  ///
  /// In en, this message translates to:
  /// **'Asian'**
  String get foodCategoryAsian;

  /// No description provided for @foodCategoryMexican.
  ///
  /// In en, this message translates to:
  /// **'Mexican'**
  String get foodCategoryMexican;

  /// No description provided for @foodCategoryDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get foodCategoryDrinks;

  /// No description provided for @foodCategoryVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get foodCategoryVegan;

  /// No description provided for @promoFreeDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get promoFreeDeliveryTitle;

  /// No description provided for @promoFreeDeliverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'On your first order over 100k'**
  String get promoFreeDeliverySubtitle;

  /// No description provided for @promoPizzaTitle.
  ///
  /// In en, this message translates to:
  /// **'50% Off Pizza'**
  String get promoPizzaTitle;

  /// No description provided for @promoPizzaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use code: PIZZA50'**
  String get promoPizzaSubtitle;

  /// No description provided for @profileFavoritePlaces.
  ///
  /// In en, this message translates to:
  /// **'Favorite Places (Home/Work)'**
  String get profileFavoritePlaces;

  /// No description provided for @profileInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends (Get 50K)'**
  String get profileInviteFriends;

  /// No description provided for @profileDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get profileDarkMode;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get walletTitle;

  /// No description provided for @walletTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get walletTotalBalance;

  /// No description provided for @walletTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top Up'**
  String get walletTopUp;

  /// No description provided for @walletTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get walletTransfer;

  /// No description provided for @walletScanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get walletScanQR;

  /// No description provided for @walletWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get walletWithdraw;

  /// No description provided for @walletRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get walletRecentTransactions;

  /// No description provided for @walletViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get walletViewAll;

  /// No description provided for @walletNoRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions.'**
  String get walletNoRecentTransactions;

  /// No description provided for @featureUnderDev.
  ///
  /// In en, this message translates to:
  /// **'Feature under development'**
  String get featureUnderDev;

  /// No description provided for @selectLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocationTitle;

  /// No description provided for @homeAddress.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeAddress;

  /// No description provided for @workAddress.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workAddress;

  /// No description provided for @addHomeAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Home Address'**
  String get addHomeAddress;

  /// No description provided for @addWorkAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Work Address'**
  String get addWorkAddress;

  /// No description provided for @noSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get noSavedAddresses;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @addressNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Home, Work)'**
  String get addressNameHint;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

  /// No description provided for @sendPackage.
  ///
  /// In en, this message translates to:
  /// **'Send Package'**
  String get sendPackage;

  /// No description provided for @senderDetails.
  ///
  /// In en, this message translates to:
  /// **'Sender Details'**
  String get senderDetails;

  /// No description provided for @receiverDetails.
  ///
  /// In en, this message translates to:
  /// **'Receiver Details'**
  String get receiverDetails;

  /// No description provided for @addReceiverInfo.
  ///
  /// In en, this message translates to:
  /// **'Add receiver info'**
  String get addReceiverInfo;

  /// No description provided for @addSenderInfo.
  ///
  /// In en, this message translates to:
  /// **'Add sender info'**
  String get addSenderInfo;

  /// No description provided for @packageSize.
  ///
  /// In en, this message translates to:
  /// **'Package Size'**
  String get packageSize;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// No description provided for @sizeDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get sizeDocument;

  /// No description provided for @instantDelivery.
  ///
  /// In en, this message translates to:
  /// **'Instant Delivery'**
  String get instantDelivery;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @orderSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order Success!'**
  String get orderSuccess;

  /// No description provided for @orderSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your package has been scheduled for delivery.'**
  String get orderSuccessMessage;

  /// No description provided for @deliveryTo.
  ///
  /// In en, this message translates to:
  /// **'Delivery to'**
  String get deliveryTo;

  /// No description provided for @searchSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Search supermarkets, stores...'**
  String get searchSupermarket;

  /// No description provided for @nearbySupermarkets.
  ///
  /// In en, this message translates to:
  /// **'Nearby Supermarkets'**
  String get nearbySupermarkets;

  /// No description provided for @convenienceStore.
  ///
  /// In en, this message translates to:
  /// **'Convenience'**
  String get convenienceStore;

  /// No description provided for @grocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get grocery;

  /// No description provided for @pharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacy;

  /// No description provided for @meat.
  ///
  /// In en, this message translates to:
  /// **'Meat/Fish'**
  String get meat;

  /// No description provided for @bakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get bakery;

  /// No description provided for @beverage.
  ///
  /// In en, this message translates to:
  /// **'Beverage'**
  String get beverage;

  /// No description provided for @fruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get fruits;

  /// No description provided for @vegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get vegetables;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
