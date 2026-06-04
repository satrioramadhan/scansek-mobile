import 'package:get/get.dart';

import '../modules/activity_tracker/bindings/activity_tracker_binding.dart';
import '../modules/activity_tracker/views/activity_tracker_view.dart';
import '../modules/activity_tracker/views/start_activity_view.dart';
import '../modules/add_food/bindings/add_food_binding.dart';
import '../modules/add_food/views/add_food_view.dart';

import '../modules/add_water/bindings/add_water_binding.dart';
import '../modules/auth/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/auth/forgot_password/views/forgot_password_view.dart';
import '../modules/auth/login/bindings/login_binding.dart';
import '../modules/auth/login/views/login_view.dart';
import '../modules/auth/otp_verification/bindings/otp_verification_binding.dart';
import '../modules/auth/otp_verification/views/otp_verification_view.dart';
import '../modules/auth/register/bindings/register_binding.dart';
import '../modules/auth/register/views/register_view.dart';
import '../modules/auth/reset_password/bindings/reset_password_binding.dart';
import '../modules/auth/reset_password/views/reset_password_view.dart';
import '../modules/auth/verify_reset_otp/bindings/verify_reset_otp_binding.dart';
import '../modules/auth/verify_reset_otp/views/verify_reset_otp_view.dart';
import '../modules/auth/complete_profile/bindings/complete_profile_binding.dart';
import '../modules/auth/complete_profile/views/complete_profile_view.dart';
import '../modules/goals/bindings/goals_binding.dart';
import '../modules/goals/views/goals_view.dart';
import '../modules/graphs/bindings/graphs_binding.dart';
import '../modules/graphs/views/graphs_view.dart';
import '../modules/history/bindings/history_binding.dart';
import '../modules/history/views/history_view.dart';

import '../modules/main/bindings/main_binding.dart';
import '../modules/main/views/main_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/profile/views/edit_profile_view.dart';
import '../modules/reminder/bindings/reminder_binding.dart';
import '../modules/reminder/views/reminder_view.dart';
import '../modules/reminders/bindings/reminders_binding.dart';
import '../modules/reminders/views/reminders_view.dart';
import '../modules/scanner/bindings/scanner_binding.dart';
import '../modules/scanner/views/scanner_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/system_notifications/bindings/system_notifications_binding.dart';
import '../modules/system_notifications/views/system_notifications_view.dart';
import '../modules/insight/bindings/insight_binding.dart';
import '../modules/insight/views/insight_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.OTP_VERIFICATION,
      page: () => const OtpVerificationView(),
      binding: OtpVerificationBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.VERIFY_RESET_OTP,
      page: () => const VerifyResetOtpView(),
      binding: VerifyResetOtpBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.RESET_PASSWORD,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.COMPLETE_PROFILE,
      page: () => const CompleteProfileView(),
      binding: CompleteProfileBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.MAIN,
      page: () => const MainView(),
      binding: MainBinding(),
    ),

    GetPage(
      name: _Paths.SCANNER,
      page: () => const ScannerView(),
      binding: ScannerBinding(),
    ),
    GetPage(
      name: _Paths.ADD_FOOD,
      page: () => const AddFoodView(),
      binding: AddFoodBinding(),
    ),

    GetPage(
      name: _Paths.HISTORY,
      page: () => const HistoryView(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_PROFILE,
      page: () => const EditProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.GOALS,
      page: () => const GoalsView(),
      binding: GoalsBinding(),
    ),
    GetPage(
      name: _Paths.REMINDERS,
      page: () => const RemindersView(),
      binding: RemindersBinding(),
    ),
    GetPage(
      name: _Paths.GRAPHS,
      page: () => const GraphsView(),
      binding: GraphsBinding(),
    ),
    GetPage(
      name: _Paths.ACTIVITY_TRACKER,
      page: () => const ActivityTrackerView(),
      binding: ActivityTrackerBinding(),
    ),
    GetPage(
      name: _Paths.START_ACTIVITY,
      page: () => const StartActivityView(),
      binding: ActivityTrackerBinding(),
    ),
    GetPage(
      name: _Paths.REMINDER,
      page: () => const ReminderView(),
      binding: ReminderBinding(),
    ),
    GetPage(
      name: _Paths.SYSTEM_NOTIFICATIONS,
      page: () => const SystemNotificationsView(),
      binding: SystemNotificationsBinding(),
    ),
    GetPage(
      name: _Paths.INSIGHT,
      page: () => const InsightView(),
      binding: InsightBinding(),
    ),
  ];
}
