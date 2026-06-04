import 'package:get/get.dart';
import 'package:scansek/app/widgets/states/error_state.dart';
import 'package:dio/dio.dart';
import '../../../data/providers/api/api_client.dart';
import '../../../data/providers/api/network_exception.dart';
import '../../../widgets/snackbars/snackbar_designs.dart';

class SecurityController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  
  final RxBool isLoading = false.obs;

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiClient.put('/users/password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200) {
        // Success - close screen first
        isLoading.value = false;
        Get.back();
        
        // Show success after navigation
        await Future.delayed(const Duration(milliseconds: 300));
        ElegantSnackbar.success(
          Get.context,
          'Password berhasil diubah! Jangan lupa ya.',
        );
      }
    } on NetworkException catch (e) {
      // Handle NetworkException from ApiClient
      isLoading.value = false;
      ErrorSnackbar.show(
        Get.context!,
        e.message,
      );
    } on DioException catch (e) {
      // Handle DioException directly
      isLoading.value = false;
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data['errors'];
        if (errors != null) {
          if (errors['oldPassword'] != null) {
            ElegantSnackbar.error(
              Get.context,
              errors['oldPassword'][0] ?? 'Password lama kamu salah nih',
            );
          } else if (errors['newPassword'] != null) {
            ElegantSnackbar.error(
              Get.context,
              errors['newPassword'][0] ?? 'Password baru kurang oke nih',
            );
          } else {
            ElegantSnackbar.error(
              Get.context,
              e.response?.data['message'] ?? 'Gagal ganti password nih',
            );
          }
        } else {
          // Google user or other message
          ElegantSnackbar.error(
            Get.context,
            e.response?.data['message'] ?? 'Gagal ganti password nih',
          );
        }
      } else {
        ElegantSnackbar.error(
          Get.context,
          'Ada masalah nih. Coba lagi nanti ya.',
        );
      }
    } catch (e) {
      isLoading.value = false;
      ElegantSnackbar.error(
        Get.context,
        'Ada masalah nih. Coba lagi nanti ya.',
      );
    }
  }
}
