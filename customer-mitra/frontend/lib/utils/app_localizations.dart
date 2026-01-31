import 'package:easy_localization/easy_localization.dart';

/// Helper class for translations
/// Usage: AppLocalizations.language instead of 'language'.tr()
class AppLocalizations {
  // Common
  static String get appName => 'app_name'.tr();
  static String get welcome => 'welcome'.tr();
  static String get login => 'login'.tr();
  static String get logout => 'logout'.tr();
  static String get email => 'email'.tr();
  static String get password => 'password'.tr();
  static String get confirmPassword => 'confirm_password'.tr();
  static String get forgotPassword => 'forgot_password'.tr();
  static String get dontHaveAccount => 'dont_have_account'.tr();
  static String get register => 'register'.tr();
  static String get name => 'name'.tr();
  static String get phone => 'phone'.tr();
  static String get address => 'address'.tr();

  // Profile & Account
  static String get profile => 'profile'.tr();
  static String get editProfile => 'edit_profile'.tr();
  static String get account => 'account'.tr();
  static String get security => 'security'.tr();
  static String get changePassword => 'change_password'.tr();
  static String get language => 'language'.tr();
  static String get helpCenter => 'help_center'.tr();
  static String get others => 'others'.tr();
  static String get rewardPoint => 'reward_point'.tr();
  static String get createPin => 'create_pin'.tr();

  // Navigation
  static String get home => 'home'.tr();
  static String get order => 'order'.tr();
  static String get history => 'history'.tr();
  static String get promo => 'promo'.tr();

  // Services
  static String get nebengMotor => 'nebeng_motor'.tr();
  static String get nebengMobil => 'nebeng_mobil'.tr();
  static String get nebengBarang => 'nebeng_barang'.tr();
  static String get titipBarang => 'titip_barang'.tr();

  // Locations & Trips
  static String get originLocation => 'origin_location'.tr();
  static String get destinationLocation => 'destination_location'.tr();
  static String get selectLocation => 'select_location'.tr();
  static String get departureDate => 'departure_date'.tr();
  static String get departureTime => 'departure_time'.tr();
  static String get searchTrip => 'search_trip'.tr();

  // Booking & Payment
  static String get price => 'price'.tr();
  static String get seatAvailable => 'seat_available'.tr();
  static String get bookNow => 'book_now'.tr();
  static String get detail => 'detail'.tr();
  static String get payment => 'payment'.tr();
  static String get paymentMethod => 'payment_method'.tr();
  static String get totalPayment => 'total_payment'.tr();
  static String get payNow => 'pay_now'.tr();

  // Status
  static String get success => 'success'.tr();
  static String get failed => 'failed'.tr();
  static String get processing => 'processing'.tr();
  static String get cancelled => 'cancelled'.tr();
  static String get completed => 'completed'.tr();

  // Actions
  static String get confirmation => 'confirmation'.tr();
  static String get areYouSureLogout => 'are_you_sure_logout'.tr();
  static String get yes => 'yes'.tr();
  static String get no => 'no'.tr();
  static String get cancel => 'cancel'.tr();
  static String get save => 'save'.tr();
  static String get delete => 'delete'.tr();
  static String get edit => 'edit'.tr();
  static String get search => 'search'.tr();
  static String get filter => 'filter'.tr();
  static String get sort => 'sort'.tr();

  // Messages
  static String get loading => 'loading'.tr();
  static String get noData => 'no_data'.tr();
  static String get errorOccurred => 'error_occurred'.tr();
  static String get tryAgain => 'try_again'.tr();

  // Language Settings
  static String get languageChangedSuccess => 'language_changed_success'.tr();
  static String get selectLanguageForApp => 'select_language_for_app'.tr();
  static String get indonesian => 'indonesian'.tr();
  static String get english => 'english'.tr();

  // Verification
  static String get verifiedPhone => 'verified_phone'.tr();
  static String get verification => 'verification'.tr();
  static String get documentVerification => 'document_verification'.tr();

  // History & Transactions
  static String get tripHistory => 'trip_history'.tr();
  static String get transactionHistory => 'transaction_history'.tr();
  static String get refund => 'refund'.tr();

  // Info
  static String get driverInfo => 'driver_info'.tr();
  static String get vehicleInfo => 'vehicle_info'.tr();
  static String get passengerInfo => 'passenger_info'.tr();

  // Settings & About
  static String get notifications => 'notifications'.tr();
  static String get settings => 'settings'.tr();
  static String get about => 'about'.tr();
  static String get termsAndConditions => 'terms_and_conditions'.tr();
  static String get privacyPolicy => 'privacy_policy'.tr();
}
