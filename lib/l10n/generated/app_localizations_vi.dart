// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get login => 'Đăng nhập';

  @override
  String get register => 'Đăng ký';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get home => 'Trang chủ';

  @override
  String get settings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get changeLanguage => 'Đổi ngôn ngữ';

  @override
  String get welcome => 'Chào mừng';

  @override
  String get welcomeBack => 'Chào mừng trở lại!';

  @override
  String get signInToContinue => 'Đăng nhập để vào Super App';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get or => 'HOẶC';

  @override
  String get quickLogin => 'Đăng nhập nhanh (Tài khoản Test)';

  @override
  String get roleCustomer => 'Khách hàng';

  @override
  String get roleMerchant => 'Thương nhân';

  @override
  String get roleDriver => 'Tài xế';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navActivity => 'Hoạt động';

  @override
  String get navWallet => 'Ví';

  @override
  String get navAccount => 'Tài khoản';

  @override
  String get currentLocation => 'Vị trí hiện tại';

  @override
  String get searchPlaceholder => 'Bạn thèm gì hôm nay?';

  @override
  String get serviceRide => 'Đi xe';

  @override
  String get serviceFood => 'Đồ ăn';

  @override
  String get serviceMart => 'Đi chợ';

  @override
  String get serviceCourier => 'Giao hàng';

  @override
  String get serviceGift => 'Quà tặng';

  @override
  String get serviceTickets => 'Vé máy bay';

  @override
  String get serviceMore => 'Khác';

  @override
  String get specialOffers => 'Ưu đãi đặc biệt';

  @override
  String get seeAll => 'Xem tất cả';

  @override
  String get recentActivity => 'Hoạt động gần đây';

  @override
  String get noRecentActivity => 'Chưa có hoạt động gần đây';

  @override
  String get comingSoonTitle => 'Sắp ra mắt';

  @override
  String get comingSoonMessage => 'Tính năng này đang được phát triển.';

  @override
  String get ok => 'OK';

  @override
  String get promo1 => 'Giảm 30% chuyến đi';

  @override
  String get promo2 => 'Tặng Burger';

  @override
  String get promo3 => 'Giảm đi chợ';

  @override
  String get sectionGeneral => 'Chung';

  @override
  String get sectionSupport => 'Hỗ trợ';

  @override
  String get profilePersonalInfo => 'Thông tin cá nhân';

  @override
  String get profilePaymentMethods => 'Phương thức thanh toán';

  @override
  String get profileSavedAddresses => 'Địa chỉ đã lưu';

  @override
  String get profileNotifications => 'Thông báo';

  @override
  String get profileLanguage => 'Ngôn ngữ';

  @override
  String get profileHelpCenter => 'Trung tâm trợ giúp';

  @override
  String get profileAboutUs => 'Về chúng tôi';

  @override
  String get profileRateApp => 'Đánh giá ứng dụng';

  @override
  String get profileLogOut => 'Đăng xuất';

  @override
  String get dialogLogOutTitle => 'Đăng xuất';

  @override
  String get dialogLogOutMessage => 'Bạn có chắc chắn muốn đăng xuất không?';

  @override
  String get dialogCancel => 'Hủy';

  @override
  String get dialogEditProfileTitle => 'Sửa hồ sơ';

  @override
  String get dialogDisplayNameLabel => 'Tên hiển thị';

  @override
  String get dialogSave => 'Lưu';

  @override
  String get gettingLocation => 'Đang lấy vị trí...';

  @override
  String get whereTo => 'Bạn muốn đi đâu?';

  @override
  String get enterPickupLocation => 'Nhập điểm đón';

  @override
  String get useCurrentLocation => 'Sử dụng vị trí hiện tại';

  @override
  String get enterPickupAddress => 'Nhập địa chỉ đón...';

  @override
  String get enterDestination => 'Nhập điểm đến';

  @override
  String get nearbyDrivers => 'Tài xế gần đây';

  @override
  String get radius => 'Bán kính';

  @override
  String get selectDriver => 'Chọn';

  @override
  String noDriversFound(String radius) {
    return 'Không tìm thấy tài xế trong vòng ${radius}km';
  }

  @override
  String get expandRadiusPrompt =>
      'Bạn có muốn mở rộng bán kính tìm kiếm không?';

  @override
  String get searchAgain => 'Tìm kiếm lại';

  @override
  String driverApproaching(String name) {
    return '$name đang tới!';
  }

  @override
  String get pleaseSelectRideOption => 'Vui lòng chọn tùy chọn chuyến đi';

  @override
  String get orderDetails => 'Chi tiết đơn hàng';

  @override
  String get driverInfo => 'Tài xế/Quán ăn';

  @override
  String get deliveryAddress => 'Địa chỉ giao hàng';

  @override
  String get orderSummary => 'Tóm tắt khuyến mãi';

  @override
  String get total => 'Tổng cộng';

  @override
  String get orderTime => 'Thời gian đặt hàng';

  @override
  String get orderId => 'Mã HD';

  @override
  String get categories => 'Danh mục';

  @override
  String get popularRestaurants => 'Quán ngon phổ biến';

  @override
  String get promo => 'KM';

  @override
  String get fastDelivery => 'Giao nhanh';

  @override
  String get foodCategoryBurger => 'Burger';

  @override
  String get foodCategoryPizza => 'Pizza';

  @override
  String get foodCategoryAsian => 'Châu Á';

  @override
  String get foodCategoryMexican => 'Mexico';

  @override
  String get foodCategoryDrinks => 'Đồ uống';

  @override
  String get foodCategoryVegan => 'Thuần chay';

  @override
  String get promoFreeDeliveryTitle => 'Miễn phí giao hàng';

  @override
  String get promoFreeDeliverySubtitle => 'Cho đơn đầu tiên trên 100k';

  @override
  String get promoPizzaTitle => 'Giảm 50% Pizza';

  @override
  String get promoPizzaSubtitle => 'Dùng mã: PIZZA50';

  @override
  String get profileFavoritePlaces => 'Địa điểm yêu thích (Nhà/CQ)';

  @override
  String get profileInviteFriends => 'Mời bạn bè (Nhận 50K)';

  @override
  String get profileDarkMode => 'Chế độ tối';

  @override
  String get walletTitle => 'Ví của tôi';

  @override
  String get walletTotalBalance => 'Tổng số dư';

  @override
  String get walletTopUp => 'Nạp tiền';

  @override
  String get walletTransfer => 'Chuyển tiền';

  @override
  String get walletScanQR => 'Quét QR';

  @override
  String get walletWithdraw => 'Rút tiền';

  @override
  String get walletRecentTransactions => 'Giao dịch gần đây';

  @override
  String get walletViewAll => 'Xem tất cả';

  @override
  String get walletNoRecentTransactions => 'Không có giao dịch gần đây.';

  @override
  String get featureUnderDev => 'Tính năng đang phát triển';

  @override
  String get selectLocationTitle => 'Chọn vị trí';

  @override
  String get homeAddress => 'Nhà';

  @override
  String get workAddress => 'Công ty';

  @override
  String get addHomeAddress => 'Thêm địa chỉ Nhà';

  @override
  String get addWorkAddress => 'Thêm địa chỉ Công ty';

  @override
  String get noSavedAddresses => 'Không có địa chỉ đã lưu';

  @override
  String get savedAddresses => 'Địa chỉ đã lưu';

  @override
  String get addNewAddress => 'Thêm địa chỉ mới';

  @override
  String get addressNameHint => 'Tên (VD: Nhà, Công ty)';

  @override
  String get fullAddress => 'Địa chỉ đầy đủ';

  @override
  String get sendPackage => 'Gửi bưu kiện';

  @override
  String get senderDetails => 'Người Gửi';

  @override
  String get receiverDetails => 'Người Nhận';

  @override
  String get addReceiverInfo => 'Thêm thông tin người nhận';

  @override
  String get addSenderInfo => 'Thêm thông tin người gửi';

  @override
  String get packageSize => 'Cân nặng gói hàng';

  @override
  String get sizeSmall => 'Nhỏ';

  @override
  String get sizeMedium => 'Trung bình';

  @override
  String get sizeLarge => 'Lớn';

  @override
  String get sizeDocument => 'Tài liệu chứng từ';

  @override
  String get instantDelivery => 'Giao tốc hành';

  @override
  String get distance => 'Khoảng cách';

  @override
  String get continueButton => 'Tiếp tục';

  @override
  String get orderSuccess => 'Đặt hàng thành công!';

  @override
  String get orderSuccessMessage =>
      'Gói hàng của bạn đã sẵn sàng để được giao.';

  @override
  String get deliveryTo => 'Giao hàng đến';

  @override
  String get searchSupermarket => 'Tìm kiếm siêu thị, cửa hàng...';

  @override
  String get nearbySupermarkets => 'Siêu thị gần đây';

  @override
  String get convenienceStore => 'Tiện lợi';

  @override
  String get grocery => 'Bách hóa';

  @override
  String get pharmacy => 'Nhà thuốc';

  @override
  String get meat => 'Thịt cá';

  @override
  String get bakery => 'Bánh ngọt';

  @override
  String get beverage => 'Đồ uống';

  @override
  String get fruits => 'Trái cây';

  @override
  String get vegetables => 'Rau củ';
}
