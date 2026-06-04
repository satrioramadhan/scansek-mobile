import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/core/theme/app_theme.dart';
import 'app/data/providers/api/api_client.dart';
import 'app/data/providers/local/storage_service.dart';
import 'app/services/notification_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  print('🟢 MAIN: Starting app...');
  WidgetsFlutterBinding.ensureInitialized();

  print('🟢 MAIN: Setting orientations...');
  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('🟢 MAIN: Initializing services...');
  // Initialize services
  await initServices();

  print('🟢 MAIN: Running app...');
  runApp(const MyApp());
  print('🟢 MAIN: App started!');
}

/// Initialize all services before app starts
Future<void> initServices() async {
  print('🟡 SERVICES: Initializing Firebase...');
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🟡 SERVICES: Firebase initialized ✅');
  } catch (e) {
    print('🔴 SERVICES: Firebase initialization failed: $e');
  }

  print('🟡 SERVICES: Initializing storage...');
  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();
  Get.put<StorageService>(storageService);
  print('🟡 SERVICES: Storage initialized ✅');

  print('🟡 SERVICES: Initializing API client...');
  // Initialize API client
  Get.put<ApiClient>(ApiClient());
  print('🟡 SERVICES: API client initialized ✅');
  
  print('🟡 SERVICES: Initializing notification service...');
  // Initialize notification service setup (Permissions will be requested inside app UI)
  final notificationService = NotificationService();
  await notificationService.initialize();
  print('🟡 SERVICES: Notification service initialized ✅');
  
  print('🟡 SERVICES: All services ready! ✅');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🟣 APP: Building GetMaterialApp...');
    print('🟣 APP: Initial route = ${AppPages.INITIAL}');
    
    return GetMaterialApp(
      title: 'ScanSek',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      onInit: () {
        print('🟣 APP: GetMaterialApp onInit called');
      },
      onReady: () {
        print('🟣 APP: GetMaterialApp onReady called');
      },
    );
  }
}
