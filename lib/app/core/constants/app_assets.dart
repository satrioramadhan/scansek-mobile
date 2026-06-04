/// App assets paths
class AppAssets {
  AppAssets._(); // Private constructor

  // ============================================
  // Logo
  // ============================================

  static const String logo = 'assets/logo.png';

  // ============================================
  // Images
  // ============================================

  static const String _imagesPath = 'assets/images/';

  // Placeholder paths - user akan provide nanti
  static const String placeholderFood = '${_imagesPath}placeholder_food.png';
  static const String placeholderActivity = '${_imagesPath}placeholder_activity.png';
  static const String emptyStateImage = '${_imagesPath}empty_state.png';

  // ============================================
  // Lottie Animations
  // ============================================

  static const String _lottiePath = 'assets/lottie/';

  // Placeholder paths - user akan provide nanti
  static const String loadingAnimation = '${_lottiePath}loading.json';
  static const String successAnimation = '${_lottiePath}success.json';
  static const String emptyAnimation = '${_lottiePath}empty.json';
  static const String scanAnimation = '${_lottiePath}scan.json';

  // ============================================
  // Icons
  // ============================================

  static const String _iconsPath = 'assets/icons/';

  // Custom icons jika ada
  static const String iconCalorie = '${_iconsPath}calorie.svg';
  static const String iconSugar = '${_iconsPath}sugar.svg';
  static const String iconWater = '${_iconsPath}water.svg';
  static const String iconActivity = '${_iconsPath}activity.svg';
}
