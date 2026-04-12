// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get signInToContinue => 'Sign in to continue to Super App';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get or => 'OR';

  @override
  String get quickLogin => 'Quick Login (Test Accounts)';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleMerchant => 'Merchant';

  @override
  String get roleDriver => 'Driver';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get navHome => 'Home';

  @override
  String get navActivity => 'Activity';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navAccount => 'Account';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get searchPlaceholder => 'What are you craving?';

  @override
  String get serviceRide => 'Ride';

  @override
  String get serviceFood => 'Food';

  @override
  String get serviceMart => 'Mart';

  @override
  String get serviceCourier => 'Courier';

  @override
  String get serviceGift => 'Gift';

  @override
  String get serviceTickets => 'Tickets';

  @override
  String get serviceMore => 'More';

  @override
  String get specialOffers => 'Special Offers';

  @override
  String get seeAll => 'See All';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get comingSoonTitle => 'Coming Soon';

  @override
  String get comingSoonMessage => 'This feature is under development.';

  @override
  String get ok => 'OK';

  @override
  String get promo1 => '30% Off Rides';

  @override
  String get promo2 => 'Free Burger';

  @override
  String get promo3 => 'Grocery Deal';

  @override
  String get sectionGeneral => 'General';

  @override
  String get sectionSupport => 'Support';

  @override
  String get profilePersonalInfo => 'Personal Information';

  @override
  String get profilePaymentMethods => 'Payment Methods';

  @override
  String get profileSavedAddresses => 'Saved Addresses';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileHelpCenter => 'Help Center';

  @override
  String get profileAboutUs => 'About Us';

  @override
  String get profileRateApp => 'Rate App';

  @override
  String get profileLogOut => 'Log Out';

  @override
  String get dialogLogOutTitle => 'Log Out';

  @override
  String get dialogLogOutMessage => 'Are you sure you want to log out?';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogEditProfileTitle => 'Edit Profile';

  @override
  String get dialogDisplayNameLabel => 'Display Name';

  @override
  String get dialogSave => 'Save';

  @override
  String get gettingLocation => 'Getting location...';

  @override
  String get whereTo => 'Where to?';

  @override
  String get enterPickupLocation => 'Enter Pickup Location';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get enterPickupAddress => 'Enter pickup address...';

  @override
  String get enterDestination => 'Enter Destination';

  @override
  String get nearbyDrivers => 'Nearby Drivers';

  @override
  String get radius => 'Radius';

  @override
  String get selectDriver => 'Select';

  @override
  String noDriversFound(String radius) {
    return 'No drivers found within ${radius}km';
  }

  @override
  String get expandRadiusPrompt => 'Do you want to expand the search radius?';

  @override
  String get searchAgain => 'Search Again';

  @override
  String driverApproaching(String name) {
    return '$name is approaching!';
  }

  @override
  String get pleaseSelectRideOption => 'Please select a ride option';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get driverInfo => 'Driver/Merchant Info';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get total => 'Total';

  @override
  String get orderTime => 'Order Time';

  @override
  String get orderId => 'Order ID';

  @override
  String get categories => 'Categories';

  @override
  String get popularRestaurants => 'Popular Restaurants';

  @override
  String get promo => 'PROMO';

  @override
  String get fastDelivery => 'Fast Delivery';

  @override
  String get foodCategoryBurger => 'Burger';

  @override
  String get foodCategoryPizza => 'Pizza';

  @override
  String get foodCategoryAsian => 'Asian';

  @override
  String get foodCategoryMexican => 'Mexican';

  @override
  String get foodCategoryDrinks => 'Drinks';

  @override
  String get foodCategoryVegan => 'Vegan';

  @override
  String get promoFreeDeliveryTitle => 'Free Delivery';

  @override
  String get promoFreeDeliverySubtitle => 'On your first order over 100k';

  @override
  String get promoPizzaTitle => '50% Off Pizza';

  @override
  String get promoPizzaSubtitle => 'Use code: PIZZA50';

  @override
  String get profileFavoritePlaces => 'Favorite Places (Home/Work)';

  @override
  String get profileInviteFriends => 'Invite Friends (Get 50K)';

  @override
  String get profileDarkMode => 'Dark Mode';

  @override
  String get walletTitle => 'My Wallet';

  @override
  String get walletTotalBalance => 'Total Balance';

  @override
  String get walletTopUp => 'Top Up';

  @override
  String get walletTransfer => 'Transfer';

  @override
  String get walletScanQR => 'Scan QR';

  @override
  String get walletWithdraw => 'Withdraw';

  @override
  String get walletRecentTransactions => 'Recent Transactions';

  @override
  String get walletViewAll => 'View All';

  @override
  String get walletNoRecentTransactions => 'No recent transactions.';

  @override
  String get featureUnderDev => 'Feature under development';

  @override
  String get selectLocationTitle => 'Select Location';

  @override
  String get homeAddress => 'Home';

  @override
  String get workAddress => 'Work';

  @override
  String get addHomeAddress => 'Add Home Address';

  @override
  String get addWorkAddress => 'Add Work Address';

  @override
  String get noSavedAddresses => 'No saved addresses';

  @override
  String get savedAddresses => 'Saved Addresses';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String get addressNameHint => 'Name (e.g. Home, Work)';

  @override
  String get fullAddress => 'Full Address';

  @override
  String get sendPackage => 'Send Package';

  @override
  String get senderDetails => 'Sender Details';

  @override
  String get receiverDetails => 'Receiver Details';

  @override
  String get addReceiverInfo => 'Add receiver info';

  @override
  String get addSenderInfo => 'Add sender info';

  @override
  String get packageSize => 'Package Size';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String get sizeDocument => 'Document';

  @override
  String get instantDelivery => 'Instant Delivery';

  @override
  String get distance => 'Distance';

  @override
  String get continueButton => 'Continue';

  @override
  String get orderSuccess => 'Order Success!';

  @override
  String get orderSuccessMessage =>
      'Your package has been scheduled for delivery.';

  @override
  String get deliveryTo => 'Delivery to';

  @override
  String get searchSupermarket => 'Search supermarkets, stores...';

  @override
  String get nearbySupermarkets => 'Nearby Supermarkets';

  @override
  String get convenienceStore => 'Convenience';

  @override
  String get grocery => 'Grocery';

  @override
  String get pharmacy => 'Pharmacy';

  @override
  String get meat => 'Meat/Fish';

  @override
  String get bakery => 'Bakery';

  @override
  String get beverage => 'Beverage';

  @override
  String get fruits => 'Fruits';

  @override
  String get vegetables => 'Vegetables';
}
