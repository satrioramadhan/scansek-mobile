import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/widgets/states/error_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/providers/api/api_client.dart';
import '../../../../data/providers/api/api_endpoints.dart';
import '../../../../data/providers/api/network_exception.dart';
import '../../../../data/providers/local/storage_service.dart';
import '../../../../routes/app_pages.dart';
import '../../../../widgets/snackbars/snackbar_designs.dart';

class LoginController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final StorageService _storage = Get.find<StorageService>();

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Validate and login
  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Save tokens
        await _storage.saveAccessToken(data['accessToken']);
        await _storage.saveRefreshToken(data['refreshToken']);

        // Save user data
        await _storage.saveUserData(data['user']);

        // Navigate to main (dashboard with bottom nav)
        Get.offAllNamed(Routes.MAIN);
      }
    } on ForbiddenException catch (e) {
      // Email not verified - redirect to OTP with email
      ElegantSnackbar.error(
        Get.context,
        'Email kamu belum diverifikasi nih. Verifikasi dulu ya.',
      );
      
      // Wait a bit for snackbar to show
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to OTP verification with email parameter
      Get.toNamed(
        Routes.OTP_VERIFICATION,
        arguments: {
          'email': emailController.text.trim(),
          'fromLogin': true, // flag untuk tahu dari login
        },
      );
    } on UnauthorizedException catch (e) {
      ElegantSnackbar.error(Get.context, e.message);
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Waduh, ada error nih');
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to register
  void goToRegister() {
    Get.toNamed(Routes.REGISTER);
  }

  /// Navigate to forgot password
  void goToForgotPassword() {
    Get.toNamed(Routes.FORGOT_PASSWORD);
  }

  /// Google sign in
  Future<void> googleSignIn() async {
    try {
      isLoading.value = true;

      // Initialize Google Sign In with Web Client ID
      final googleSignIn = GoogleSignIn(
        serverClientId: '632959232338-cgjg02lnblo2hrs7es7l7359i1qjmjrj.apps.googleusercontent.com',
      );
      final firebaseAuth = FirebaseAuth.instance;

      // Trigger Google Sign In
      GoogleSignInAccount? googleUser;
      try {
        // Sign out first to ensure clean state
        await googleSignIn.signOut();
        
        // Then sign in
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        print('Google Sign In Error: $e');
        // If main sign in fails, don't try silent sign in
        // This often causes the PigeonUserDetails error
        ElegantSnackbar.error(
          Get.context,
          'Gagal masuk pake Google nih. Cek internet kamu ya.',
        );
        isLoading.value = false;
        return;
      }
      
      if (googleUser == null) {
        // User canceled sign in
        isLoading.value = false;
        return;
      }

      print('✅ Step 1: Google user obtained');

      // Get Google Auth credentials
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        print('✅ Step 2: Google authentication obtained');
      } catch (e) {
        print('❌ Error at googleUser.authentication: $e');
        throw Exception('Gagal mendapatkan kredensial Google: $e');
      }

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('✅ Step 3: Firebase credential created');

      // Sign in to Firebase
      // WORKAROUND: signInWithCredential throws type cast error due to Pigeon bug
      // BUT authentication actually succeeds! So we catch and ignore the error
      try {
        await firebaseAuth.signInWithCredential(credential);
        print('✅ Step 4: Firebase sign in successful (no error)');
      } catch (e) {
        // Check if it's the known PigeonUserDetails error
        if (e.toString().contains('PigeonUserDetails')) {
          print('⚠️ Step 4: PigeonUserDetails error caught (expected), but auth likely succeeded');
          // Continue - Firebase Auth actually works despite the error
        } else {
          print('❌ Error at signInWithCredential: $e');
          throw Exception('Gagal sign in ke Firebase: $e');
        }
      }

      // Wait a bit for Firebase to fully authenticate
      await Future.delayed(const Duration(milliseconds: 300));

      // Get current user - this will verify if auth actually succeeded
      final currentUser = firebaseAuth.currentUser;
      print('✅ Step 5: Current user obtained: ${currentUser?.uid}');
      
      if (currentUser == null) {
        throw Exception('Gagal mendapatkan user Firebase');
      }

      // Get Firebase ID token from currentUser
      String? idToken;
      try {
        idToken = await currentUser.getIdToken();
        print('✅ Step 6: ID token obtained');
      } catch (e) {
        print('❌ Error at getIdToken: $e');
        throw Exception('Gagal mendapatkan ID token: $e');
      }

      if (idToken == null) {
        throw Exception('ID token is null');
      }

      print('✅ Firebase ID Token obtained, calling backend...');

      // Send to backend
      final response = await _apiClient.post(
        ApiEndpoints.googleLogin,
        data: {'idToken': idToken},
      );

      print('✅ Backend response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];

        // Save tokens
        await _storage.saveAccessToken(data['accessToken']);
        await _storage.saveRefreshToken(data['refreshToken']);
        await _storage.saveUserData(data['user']);

        // Check if new user
        final isNewUser = data['isNewUser'] ?? false;
        final userData = data['user'];

        // Check if profile is complete (has weight, height, dateOfBirth)
        final hasWeight = userData['weight'] != null;
        final hasHeight = userData['height'] != null;
        final hasDateOfBirth = userData['dateOfBirth'] != null;
        final isProfileComplete = hasWeight && hasHeight && hasDateOfBirth;

        if (isNewUser && !isProfileComplete) {
          // New Google user with incomplete profile → Complete Profile screen
          Get.offAllNamed(Routes.COMPLETE_PROFILE);
        } else {
          // Complete profile or returning user → Main/Dashboard
          Get.offAllNamed(Routes.MAIN);
        }
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      ElegantSnackbar.error(
        Get.context!,
        'Ada masalah sama Firebase: ${e.message}',
      );
    } catch (e) {
      print('❌ Google Login Error: $e');
      ElegantSnackbar.error(
        Get.context!,
        'Gagal login Google: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
