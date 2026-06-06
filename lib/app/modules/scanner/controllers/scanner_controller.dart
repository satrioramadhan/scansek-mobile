import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/routes/app_pages.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as dart_math;
import '../../../widgets/snackbars/snackbar_designs.dart';
import '../../../widgets/common/teaspoon_visualizer.dart';

// Helper function to extract fraction string based on the value
String _getFractionString(double value) {
  int whole = value.floor();
  double fraction = value - whole;
  String fractionStr = '';
  
  if (fraction >= 0.125 && fraction < 0.375) {
    fractionStr = '¼';
  } else if (fraction >= 0.375 && fraction < 0.625) {
    fractionStr = '½';
  } else if (fraction >= 0.625 && fraction < 0.875) {
    fractionStr = '¾';
  }

  if (whole > 0 && fractionStr.isNotEmpty) {
    return '$whole $fractionStr';
  } else if (whole > 0) {
    return '$whole';
  } else if (fractionStr.isNotEmpty) {
    return fractionStr;
  }
  return '${value.toStringAsFixed(1)}';
}

class ScannerController extends GetxController {
  // Camera
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  final RxBool isCameraInitialized = false.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isProScanning = false.obs;
  final RxBool isCameraProMode = false.obs;
  final RxBool showProOffer = false.obs;
  final RxBool isLastScanPro = false.obs;
  final RxBool isPhysicalFoodMode = false.obs;
  final TextEditingController physicalFoodPromptController = TextEditingController();
  final RxBool isShowingPhysicalPrompt = false.obs;

  // Text Recognition
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RxString scannedImagePath = ''.obs;

  // Scan Results
  final Rx<String?> detectedName = Rx<String?>(null);
  final Rx<double?> detectedSugar = Rx<double?>(null);
  final Rx<double?> detectedCalories = Rx<double?>(null);
  final Rx<Rect?> sugarRect = Rx<Rect?>(null);
  final Rx<Rect?> caloriesRect = Rx<Rect?>(null);
  final Rx<Size?> imageSize = Rx<Size?>(null);
  final RxString detectedText = ''.obs;

  final RxBool isShowingResult = false.obs;
  final RxBool isFromGallery = false.obs;
  // Flash state
  final RxBool isFlashOn = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Reset values on init
    detectedSugar.value = null;
    detectedCalories.value = null;
    sugarRect.value = null;
    caloriesRect.value = null;
    imageSize.value = null;
    detectedText.value = '';
    _initializeCamera();
  }

  @override
  void onClose() {
    if (isFlashOn.value && cameraController != null && cameraController!.value.isInitialized) {
      cameraController!.setFlashMode(FlashMode.off);
    }
    cameraController?.dispose();
    textRecognizer.close();
    super.onClose();
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        ElegantSnackbar.error(Get.context, 'Kamera ga ketemu nih');
        return;
      }

      // Use back camera (index 0 usually)
      cameraController = CameraController(
        cameras![0],
        ResolutionPreset.veryHigh, // Upgrade from 'high' to 'veryHigh' for better OCR
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController!.initialize();
      // Ensure flash is off by default
      await cameraController!.setFlashMode(FlashMode.off);
      isCameraInitialized.value = true;
    } catch (e) {
      print('❌ Camera initialization error: $e');
      ElegantSnackbar.error(Get.context, 'Kamera ga bisa dibuka nih: $e');
    }
  }

  /// Toggle camera flash
  Future<void> toggleFlash() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    
    try {
      if (isFlashOn.value) {
        await cameraController!.setFlashMode(FlashMode.off);
        isFlashOn.value = false;
      } else {
        await cameraController!.setFlashMode(FlashMode.torch); // Torch for continuous light during scan
        isFlashOn.value = true;
      }
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Gagal menyalakan flash: $e');
    }
  }

  /// Capture and process image
  Future<void> captureAndProcess() async {
    if (isProcessing.value) return;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      ElegantSnackbar.error(Get.context, 'Kamera belum siap');
      return;
    }

    try {
      isProcessing.value = true;
      showProOffer.value = false;
      isLastScanPro.value = false;
      isFromGallery.value = false;
      isShowingResult.value = false;
      
      // Reset previous values before new scan
      detectedSugar.value = null;
      detectedCalories.value = null;
      detectedText.value = '';

      // Capture image
      final XFile image = await cameraController!.takePicture();
      scannedImagePath.value = image.path;

      // Decode the image to get its original resolution for bounding boxes mapping
      final decodedImage = await decodeImageFromList(await image.readAsBytes());
      imageSize.value = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      print('📸 Live Camera Resolution Loaded: ${imageSize.value}');

      if (isPhysicalFoodMode.value) {
        physicalFoodPromptController.clear();
        isShowingPhysicalPrompt.value = true;
        return;
      }

      if (isCameraProMode.value) {
        await processImageWithGemini();
        // Reset back to fast mode after pro capture
        isCameraProMode.value = false;
        return;
      }

      // Process with ML Kit
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      // Extract sugar and calorie values using layout-aware blocks
      _parseNutritionalInfo(recognizedText);

      // Show result bottom sheet
      if (detectedSugar.value != null || detectedCalories.value != null) {
        _showResultBottomSheet();
      } else {
        showProOffer.value = true;
        scannedImagePath.value = ''; // Reset so camera resumes and Pro Offer banner shows up plainly
        ElegantSnackbar.error(
          Get.context,
          'Waduh, gagal deteksi kalori & gula. Coba ulang lagi pake mode AI Pro.',
        );
      }
    } catch (e) {
      print('OCR Error: $e');
      ElegantSnackbar.error(Get.context, 'Gagal proses gambar: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Pick image from gallery with Mode Selection
  Future<void> pickImageFromGallery() async {
    if (isProcessing.value) return;

    if (isPhysicalFoodMode.value) {
      // Pick image first, then show the prompt dialog
      isProcessing.value = true;
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        
        if (image == null) {
          isProcessing.value = false;
          return;
        }
        
        isFromGallery.value = true;
        isShowingResult.value = false;
        scannedImagePath.value = image.path;
        
        final decodedImage = await decodeImageFromList(await image.readAsBytes());
        imageSize.value = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
        
        isProcessing.value = false;
        
        // Mode Makanan Fisik wajib pakai Gemini Pro & minta input prompt dulu
        physicalFoodPromptController.clear();
        isShowingPhysicalPrompt.value = true;
      } catch (e) {
        isProcessing.value = false;
        ElegantSnackbar.error(Get.context, 'Gagal memilih gambar dari galeri: $e');
      }
      return;
    }

    // Show Mode Selection Dialog (For Label Scan Mode)
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Mode Scan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pilih mesin AI untuk memproses gambar dari galerimu.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Standard Mode
            ListTile(
              onTap: () {
                Get.back();
                _processGalleryImage(useProMode: false);
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt, color: Color(0xFF009688)),
              ),
              title: const Text('Mode Cepat', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Instan (Tanpa Internet) - Deteksi dasar', style: TextStyle(fontSize: 12)),
            ),
            
            const SizedBox(height: 12),
            
            // Pro Mode
            ListTile(
              onTap: () {
                Get.back();
                _processGalleryImage(useProMode: true);
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.orange),
              ),
              title: const Text('Mode Pro AI', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Butuh ~3 detik (Perlu Internet) - Sangat akurat', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Internal processing after gallery selection
  Future<void> _processGalleryImage({required bool useProMode}) async {
    try {
      isProcessing.value = true;
      isFromGallery.value = true;
      isShowingResult.value = false;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        isProcessing.value = false;
        return;
      }
      scannedImagePath.value = image.path;

      // Decode the image to get its original resolution for bounding boxes mapping
      final decodedImage = await decodeImageFromList(await image.readAsBytes());
      imageSize.value = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      print('📸 Image Resolution Loaded: ${imageSize.value}');

      if (useProMode) {
        // Direct route to Gemini
        await processImageWithGemini();
      } else {
        // Standard ML Kit Route
        isLastScanPro.value = false;
        final inputImage = InputImage.fromFilePath(image.path);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        _parseNutritionalInfo(recognizedText);

        if (detectedSugar.value != null || detectedCalories.value != null) {
          _showResultBottomSheet();
        } else {
          showProOffer.value = true;
          ElegantSnackbar.error(
            Get.context,
            'Waduh, gagal deteksi kalori & gula. Coba ulang lagi pake mode AI Pro.',
          );
        }
      }
    } catch (e) {
      print('❌ Gallery OCR Error: $e');
      ElegantSnackbar.error(Get.context, 'Gagal proses gambar dari galeri: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Process image using Gemini Pro API (DISABLED FOR LITE VERSION)
  Future<void> processImageWithGemini({String? physicalPrompt}) async {
    ElegantSnackbar.error(Get.context, 'Fitur AI Pro dinonaktifkan di versi ini.');
    isProScanning.value = false;
    isLastScanPro.value = false;
  }

  /// Parse nutritional information from OCR text (DUMBED DOWN VERSION)
  void _parseNutritionalInfo(RecognizedText recognizedText) {
    String text = recognizedText.text.toLowerCase();
    detectedText.value = text;
    print('OCR Text:\n$text');

    // Reset values
    detectedSugar.value = null;
    detectedCalories.value = null;
    sugarRect.value = null;
    caloriesRect.value = null;
    
    // Dumb OCR logic - rentan salah baca
    // Cari angka sebelum 'g' atau 'gram' setelah kata 'gula'
    final sugarRegex = RegExp(r'gula.*?(\d+(?:\.\d+)?)\s*g', caseSensitive: false);
    final sugarMatch = sugarRegex.firstMatch(text);
    if (sugarMatch != null) {
      detectedSugar.value = double.tryParse(sugarMatch.group(1)!);
    }
    
    // Cari angka sebelum 'kkal' atau 'kcal'
    final calRegex = RegExp(r'energi.*?(\d+(?:\.\d+)?)\s*k', caseSensitive: false);
    final calMatch = calRegex.firstMatch(text);
    if (calMatch != null) {
      detectedCalories.value = double.tryParse(calMatch.group(1)!);
    }

    print('FINAL RESULT - Sugar: ${detectedSugar.value}g, Calories: ${detectedCalories.value}kcal');
  }

  /// Convert grams to teaspoons (1 tsp = 4g sugar)
  double convertGramToTeaspoon(double grams) {
    return grams / 4.0;
  }

  /// Show result bottom sheet (now triggers state to show in Stack)
  void _showResultBottomSheet() {
    isShowingResult.value = true;
  }

  /// Go to Add Food View pre-filled with scanned data
  void goToAddFoodWithScanData() {
    final name = detectedName.value;
    final sugar = detectedSugar.value;
    final calories = detectedCalories.value;
    
    // Reset state so when we return to ScannerView it's back to live camera
    closeAndResetScanner();
    
    Get.toNamed(
      '/add-food',
      arguments: {
        'isFromScan': true,
        'name': name,
        'sugar': sugar ?? 0.0,
        'calories': calories ?? 0.0,
      },
    );
  }

  /// Navigate to add food manual (empty)
  void goToAddFoodManual() {
    isShowingResult.value = false;
    Get.toNamed('/add-food');
  }

  /// Switch the camera view to Pro Mode explicitly (or run Pro process if image already loaded)
  void switchToProCameraMode({bool fromBottomSheet = false}) {
    if (fromBottomSheet) {
      isShowingResult.value = false; // hide bottom sheet
    }
    showProOffer.value = false;

    // If there is already an image loaded (e.g. from gallery), process it directly.
    if (scannedImagePath.value.isNotEmpty) {
      processImageWithGemini();
    } else {
      isCameraProMode.value = true;
    }
  }
  void closeAndResetScanner() {
    isShowingResult.value = false;
    scannedImagePath.value = '';
    isFromGallery.value = false;
    showProOffer.value = false;
    isShowingPhysicalPrompt.value = false;
  }
}



// ============================================
// SCAN RESULT BOTTOM SHEET WIDGET
// ============================================

class ScanResultBottomSheet extends StatelessWidget {
  final ScannerController controller;

  const ScanResultBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // Muncul setengah layar dulu
      minChildSize: 0.1, // Dikunci setengah halaman (engga bisa di-swipe habis)
      maxChildSize: 0.9, // Bisa di-scroll sampai 90% layar (hampir full)
      snap: true, // Snap to the nearest snapSize
      snapSizes: const [0.1, 0.9], // Titik nyangkut
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController, // Hubungkan controller agar support drag up/down
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 24),

              // Headers and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.isPhysicalFoodMode.value ? 'Hasil Analisis Makanan' : 'Hasil Scan Label',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cek dulu hasil deteksinya',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: controller.closeAndResetScanner,
                      icon: const Icon(Icons.close, color: Colors.grey),
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Results
              Obx(() {
                final name = controller.detectedName.value;
                final sugar = controller.detectedSugar.value;
                final calories = controller.detectedCalories.value;
                final teaspoons = sugar != null
                    ? controller.convertGramToTeaspoon(sugar)
                    : 0.0;

                return Column(
                  children: [
                    // Name Section
                    if (name != null && name.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20), 
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.restaurant, color: Colors.blue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Nama Makanan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                    // Calories Section
                    if (calories != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20), 
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.local_fire_department_outlined, color: Colors.orange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Kalori / Energi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Value Center
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  calories.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3142),
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'kcal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                     else 
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Kalorinya ga terdeteksi',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Coba atur kamera biar dekat dan fokus ke label',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    // Sugar Section
                    if (sugar != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20), 
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.cookie_outlined, color: Colors.teal, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Gula (Total)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Value Center
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  sugar.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3142),
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'gr',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Teaspoons Visualization
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                               decoration: BoxDecoration(
                                 color: Colors.grey[50],
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               child: Column(
                                 children: [
                                    TeaspoonVisualizer(
                                      sugarGrams: sugar,
                                      size: 32, // More proportionate
                                      activeColor: Colors.teal,
                                      inactiveColor: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Setara ± ${_getFractionString(teaspoons)} sendok teh',
                                      style: TextStyle(
                                        color: Colors.teal[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                 ]
                               )
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                       Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange[50], 
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Gulanya ga terdeteksi',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Coba atur kamera biar dekat dan fokus ke label',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                       ),
                    ],
                  ],
                );
              }),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.goToAddFoodWithScanData,
                  icon: const Icon(Icons.save, size: 20, color: Colors.white),
                  label: const Text(
                    'Simpan Hasil Scan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF80CBC4), // Soft Teal
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Scan Again Button
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final isGallery = controller.isFromGallery.value;
                  return TextButton.icon(
                    onPressed: controller.closeAndResetScanner,
                    icon: Icon(
                      isGallery ? Icons.arrow_back : Icons.qr_code_scanner, 
                      size: 20, 
                      color: const Color(0xFF80CBC4),
                    ),
                    label: Text(
                      isGallery ? 'Kembali' : 'Scan Lagi',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF80CBC4),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF80CBC4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  },
    );
  }
}

