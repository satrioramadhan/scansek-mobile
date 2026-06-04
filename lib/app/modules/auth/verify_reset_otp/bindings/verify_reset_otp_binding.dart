import 'package:get/get.dart';
import '../controllers/verify_reset_otp_controller.dart';

class VerifyResetOtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerifyResetOtpController>(() => VerifyResetOtpController());
  }
}
