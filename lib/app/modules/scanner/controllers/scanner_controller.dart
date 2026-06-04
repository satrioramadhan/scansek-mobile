import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/routes/app_pages.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as dart_math;

import '../../../core/values/api_keys.dart';

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

  /// Process image using Gemini Pro API (Fallback if ML Kit fails or Physical Food Mode)
  Future<void> processImageWithGemini({String? physicalPrompt}) async {
    if (scannedImagePath.value.isEmpty) {
      ElegantSnackbar.error(Get.context, 'Tidak ada gambar yang diproses. Silakan scan ulang.');
      return;
    }


    try {
      isProScanning.value = true;
      isLastScanPro.value = true;

      // Initialize Gemini Model
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiKeys.geminiApiKey,
      );

      // Load image bytes
      final imageBytes = await File(scannedImagePath.value).readAsBytes();
      
      // Create prompt dynamically based on mode
      String promptText = '';
      if (isPhysicalFoodMode.value) {
        promptText = 'Anda adalah ahli gizi. Tugas Anda mengestimasi nama makanan, kalori dan gula dari foto makanan fisik/piring ini.\n\n'
            'Catatan tambahan dari pengguna: "${physicalPrompt ?? "Tidak ada catatan"}".\n\n'
            'Aturan wajib:\n'
            '1. Kembalikan HANYA JSON murni tanpa Markdown.\n'
            '2. Analisis foto dan catatan, lalu berikan nama makanan, estimasi Karbohidrat Gula (Sugar) dalam gram dan Energi Total / Kalori (Calories) dalam kkal.\n'
            '3. Jika gambar bukan makanan, kembalikan {"is_food": false}.\n'
            '4. Jika gambar makanan, kembalikan {"is_food": true, "name": "Nama Makanan", "sugar": ..., "calories": ...}.\n'
            'Format Keluaran Sukses: {"is_food": true, "name": "Nasi Padang Ayam", "sugar": 15.0, "calories": 450.0}';
      } else {
        promptText = 'Anda adalah asisten pembaca label gizi teliti. Tugas utama Anda menentukan apakah gambar ini adalah label informasi nilai gizi/komposisi, dan ekstrak nilainya secara PRESISI.\n\n'
            'Aturan wajib:\n'
            '1. Kembalikan HANYA JSON murni tanpa Markdown.\n'
            '2. JIKA GAMBAR BUKAN LABEL GIZI, kembalikan JSON: {"is_nutrition_label": false}.\n'
            '3. Jika gambar adalah label gizi, kembalikan {"is_nutrition_label": true, "sugar": ..., "calories": ...}.\n'
            '4. Ekstrak nilai Karbohidrat Gula (Sugar) dalam gram. PERHATIAN: JANGAN tertukar dengan Garam (Natrium/Sodium) yang biasanya dalam mg!\n'
            '5. Ekstrak nilai Energi Total / Kalori (Calories) dalam kkal. Biasanya terletak di paling atas Informasi Nilai Gizi.\n'
            '6. Jika nilai tidak ada di label, gunakan null.\n\n'
            'Format Keluaran Sukses: {"is_nutrition_label": true, "sugar": 4.0, "calories": 25.0}';
      }
      
      final prompt = TextPart(promptText);
      final imagePart = DataPart('image/jpeg', imageBytes);

      // Call API
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (response.text != null && response.text!.isNotEmpty) {
        // Clean markdown backticks if Gemini ignores the instruction
        String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        Map<String, dynamic> data = json.decode(cleanJson);
        
        // Handle non-nutrition / non-food labels
        if ((!isPhysicalFoodMode.value && data['is_nutrition_label'] == false) || 
            (isPhysicalFoodMode.value && data['is_food'] == false)) {
          Get.snackbar(
            'Hayo Scan Apa Tuh? 🧐',
            isPhysicalFoodMode.value ? 'AI kita gak nemu makanan di foto ini. Coba foto piring/makanan yang jelas ya.' 
                                     : 'Sistem AI kita bingung nih, kayaknya ini bukan foto label gizi makanan/minuman deh.',
            backgroundColor: Colors.red[50],
            colorText: Colors.red[900],
            icon: const Icon(Icons.mood_bad, color: Colors.red),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 5),
          );
          scannedImagePath.value = ''; // Reset image so camera resumes
          return;
        }

        final size = imageSize.value;

        if (data['name'] != null) {
          detectedName.value = data['name'].toString();
        }

        if (data['sugar'] != null) {
          detectedSugar.value = (data['sugar'] as num).toDouble();
        }
        
        if (data['calories'] != null) {
          detectedCalories.value = (data['calories'] as num).toDouble();
        }

        // Reset bounding boxes so stabilo doesn't show in Pro Mode
        sugarRect.value = null;
        caloriesRect.value = null;

        _showResultBottomSheet();
      } else {
        ElegantSnackbar.error(Get.context, 'Scan Pro Google Gemini gagal membaca label.');
      }
    } catch (e) {
      print('❌ Gemini API Error: $e');
      if (e.toString().contains('Quota exceeded') || e.toString().contains('429')) {
         ElegantSnackbar.error(Get.context, 'Tunggu sebentar! Sistem AI lagi ngerem bentar (Batas 15 kali/menit). Coba lagi dalam 30 detik ya bro.');
      } else {
         ElegantSnackbar.error(Get.context, 'Koneksi ke AI gagal, coba cek internet kamu.');
      }
    } finally {
      isProScanning.value = false;
    }
  }

  /// Parse nutritional information from OCR text
  void _parseNutritionalInfo(RecognizedText recognizedText) {
    // 1. Group texts by Y coordinate (horizontal matching) with overlapping check
    List<TextLine> allLines = [];
    for (TextBlock block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }

    // Sort by Y coordinate (top to bottom)
    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    List<List<TextLine>> rows = [];
    for (TextLine line in allLines) {
      bool added = false;
      double lineTop = line.boundingBox.top;
      double lineBottom = line.boundingBox.bottom;
      double lineHeight = lineBottom - lineTop;
      
      for (List<TextLine> row in rows) {
        // Calculate the row's bounding box top and bottom
        double rowTop = row.map((l) => l.boundingBox.top).reduce(dart_math.min);
        double rowBottom = row.map((l) => l.boundingBox.bottom).reduce(dart_math.max);
        double rowHeight = rowBottom - rowTop;
        
        // Calculate overlap length
        double overlapTop = dart_math.max(lineTop, rowTop);
        double overlapBottom = dart_math.min(lineBottom, rowBottom);
        double overlapHeight = dart_math.max(0.0, overlapBottom - overlapTop);
        
        // Minimum overlap is 40% of the smaller item's height
        double minHeight = dart_math.min(lineHeight, rowHeight);
        
        if (overlapHeight >= minHeight * 0.4) {
          row.add(line);
          added = true;
          break;
        }
      }
      if (!added) {
        rows.add([line]);
      }
    }

    // Sort each row left to right and join
    List<OCRLineData> lines = [];
    for (List<TextLine> row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      String rowText = row.map((l) => l.text).join('   '); // wide space to simulate gap
      
      // Calculate overall bounding box for the row
      double left = row.map((l) => l.boundingBox.left).reduce(dart_math.min);
      double top = row.map((l) => l.boundingBox.top).reduce(dart_math.min);
      double right = row.map((l) => l.boundingBox.right).reduce(dart_math.max);
      double bottom = row.map((l) => l.boundingBox.bottom).reduce(dart_math.max);
      
      lines.add(OCRLineData(rowText, Rect.fromLTRB(left, top, right, bottom)));
    }

    String text = lines.map((l) => l.text).join('\n');
    detectedText.value = text;
    print('OCR Layout-Aware Text:\n$text');

    // Reset values
    detectedSugar.value = null;
    detectedCalories.value = null;
    sugarRect.value = null;
    caloriesRect.value = null;
    
    // ---------------------------------------------------------
    // 1. SUGAR EXTRACTION
    // ---------------------------------------------------------
    
    // Keywords for Stopwords (Blacklist) - If substring found, stop searching for Sugar
    final nutrientBlacklist = [
      'garam', 'salt', 'natrium', 'sodium',
      'lemak', 'fat', 'jenuh', 'saturated',
      'protein', 'karbohidrat', 'carhohydrate', 'serat', 'fiber',
      'vitamin', 'kalsium', 'calcium', 'zat besi', 'iron',
      'komposisi', 'ingredients', 'cholesterol', 'kolesterol',
      'laktosa', 'sukrosa', 'glukosa', 'maltosa'
    ];

    print('--- Starting Sugar Extraction ---');
    
    for (int i = 0; i < lines.length; i++) {
        final lineData = lines[i];
        final line = lineData.text.toLowerCase();
        
        // 1. Check for valid Sugar Keywords
        bool isSugarKey = false;
        
        // Abaikan jika kata gula dibarengi tanda koma atau ada kata komposisi (menghindari salah deteksi di daftar komposisi)
        bool isIngredientList = line.contains('gula,') || line.contains(', gula') || 
                                line.contains('sugar,') || line.contains(', sugar') ||
                                line.contains('komposisi') || line.contains('ingredients');

        if (!isIngredientList) {
          if (line.contains('gula total') || line.contains('total sugar')) {
            isSugarKey = true;
          } else if (line.contains('gula (sugars)') || line.contains('gula(sugars)')) {
            isSugarKey = true;
          } else if ((line.contains('gula') || line.contains('sugar')) && 
                     !line.contains('tambahan') && !line.contains('alcohol')) {
             isSugarKey = true;
          }
        }

        if (isSugarKey) {
             print('Found Sugar Candidate at line $i: "$line"');
             
             // Check 1: Value on SAME LINE with WIDE GAP support
             final misreadRegex = RegExp(r'(?:gula|sugar).*?(\d+(?:[.,]\d+)?)([89])(?!\s*(?:mg|ml|%|kcal|kkal|keal|g|gr|gram))\b', caseSensitive: false);
             final strictRegex = RegExp(r'(?:gula|sugar).*?(\d+(?:[.,]\d+)?)\s*(?:g|gr|gram)\b', caseSensitive: false);
             final looseRegex = RegExp(r'(?:gula|sugar).*?(\d+(?:[.,]\d+)?)(?!\s*(?:mg|ml|%|kcal|kkal|keal))\b', caseSensitive: false);
             
             final misreadMatches = misreadRegex.allMatches(line);
             final strictMatches = strictRegex.allMatches(line);
             final looseMatches = looseRegex.allMatches(line);
             
             if (misreadMatches.isNotEmpty) {
               final match = misreadMatches.first;
               final choppedStr = match.group(1)!.replaceAll(',', '.');
               final tail = match.group(2)!;
               final fullVal = double.tryParse(choppedStr + tail);
               
               if (fullVal != null && fullVal > 50) {
                 final choppedVal = double.tryParse(choppedStr);
                 if (choppedVal != null) {
                   detectedSugar.value = choppedVal;
                   sugarRect.value = lineData.rect;
                   print('✅ MATCHED Same Line (Misread 8/9): ${detectedSugar.value}g');
                   break;
                 }
               }
             }
             
             if (strictMatches.isNotEmpty) {
               final match = strictMatches.first;
               final valueStr = match.group(1)!.replaceAll(',', '.');
               final val = double.tryParse(valueStr);
               if (val != null) {
                 detectedSugar.value = val;
                 sugarRect.value = lineData.rect;
                 print('✅ MATCHED Same Line (Strict): ${detectedSugar.value}g');
                 break;
               }
             } else if (looseMatches.isNotEmpty) {
               final match = looseMatches.first;
               final valueStr = match.group(1)!.replaceAll(',', '.');
               final val = double.tryParse(valueStr);
               if (val != null) {
                 detectedSugar.value = val;
                 sugarRect.value = lineData.rect;
                 print('✅ MATCHED Same Line (Loose): ${detectedSugar.value}g');
                 break;
               }
             }

             // Check 2: Lookahead next few lines if not found on same line
             if (detectedSugar.value == null) {
                final result = _extractValueFromLineOrNext(lines, i, nutrientBlacklist, maxLookahead: 2);
                if (result != null) {
                  detectedSugar.value = result['value'];
                  sugarRect.value = result['rect'];
                  print('✅ MATCHED Next Line: ${detectedSugar.value}g');
                  break;
                }
             }
        }
    }

    // ---------------------------------------------------------
    // 2. CALORIE / ENERGY EXTRACTION
    // ---------------------------------------------------------
    
    print('--- Starting Energy Extraction ---');
    
    for (int i = 0; i < lines.length; i++) {
      final lineData = lines[i];
      // Instead of skipping the whole line if it contains "dari lemak",
      // we just remove the "dari lemak" portion so it doesn't trick the regex.
      // E.g. "Energi Total 120 kkal Energi dari lemak 60 kkal" -> "Energi Total 120 kkal "
      String originalLine = lineData.text.toLowerCase();
      String cleanedLine = originalLine.replaceAll(RegExp(r'(?:energi\s+dari\s+lemak|energy\s+from\s+fat).*?(?:kkal|kcal|cal|keal)?', caseSensitive: false), '');

      if (cleanedLine.contains('energi') || cleanedLine.contains('energy') || 
          cleanedLine.contains('kalori') || cleanedLine.contains('calories')) {
         
         print('Found Energi Candidate at line $i: "$cleanedLine"');
         
         // Check SAME LINE with WIDE GAP
         // Extract ALL numbers that are followed by kcal/kkal MUST BE PRESENT to avoid grabbing "1 sajian"
         final energyRegex = RegExp(r'(?:energi|energy|kalori|calories).*?(\d+(?:[.,]\d+)?)\s*(?:kkal|kcal|cal|keal)\b', caseSensitive: false);
         final matches = energyRegex.allMatches(cleanedLine);
         
         if (matches.isNotEmpty) {
           double maxVal = -1;
           for (var match in matches) {
             final valStr = match.group(1)!.replaceAll(',', '.');
             final val = double.tryParse(valStr);
             if (val != null && val > maxVal && val < 2000) {
               maxVal = val;
             }
           }
           
           if (maxVal > 0) {
             detectedCalories.value = maxVal;
             caloriesRect.value = lineData.rect;
             print('✅ MATCHED Energi Same Line (Max): ${detectedCalories.value}kcal');
             break;
           }
         }
         
         // Fallback 1: If it says "Energi Total 120", without the unit, but very close
         if (detectedCalories.value == null) {
            final looseEnergyRegex = RegExp(r'(?:energi|energy|kalori|calories)(?:\s+total)?\s*[:=]?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false);
            final looseMatch = looseEnergyRegex.firstMatch(cleanedLine);
            if (looseMatch != null) {
               final valStr = looseMatch.group(1)!.replaceAll(',', '.');
               final val = double.tryParse(valStr);
               if (val != null && val < 2000) {
                 detectedCalories.value = val;
                 caloriesRect.value = lineData.rect;
                 print('✅ MATCHED Energi Same Line (Loose): ${detectedCalories.value}kcal');
                 break;
               }
            }
         }
         
         // Fallback 2 if not on same line (e.g. "Energi\n150 kkal")
         if (detectedCalories.value == null) {
            // Check immediately for standalone digits with kcal, or even just digits if it's the only thing
            final energyNextLineRegex = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(?:kkal|kcal|cal|keal)\b', caseSensitive: false);
            final result = _extractEnergyValue(lines, i, energyNextLineRegex);
            if (result != null) {
              detectedCalories.value = result['value'];
              caloriesRect.value = result['rect'];
              print('✅ MATCHED Energi Next Line: ${detectedCalories.value}kcal');
              break;
            }
         }
      }
    }

    print('FINAL RESULT - Sugar: ${detectedSugar.value}g, Calories: ${detectedCalories.value}kcal');
  }


  /// Helper to extract gram value from current line or next few lines
  Map<String, dynamic>? _extractValueFromLineOrNext(List<OCRLineData> lines, int index, List<String> blacklist, {int maxLookahead = 3}) {
    // Look ahead a few lines
    for (int j = index + 1; j < (index + 1 + maxLookahead).clamp(0, lines.length); j++) {
      final lineData = lines[j];
      final nextLine = lineData.text.toLowerCase();
      if (nextLine.trim().isEmpty) continue;

      // STOP if we hit a blacklist word
      for (var badWord in blacklist) {
        if (nextLine.contains(badWord)) {
          return null; 
        }
      }

      final val = _extractGramValue(nextLine);
      if (val != null) return {'value': val, 'rect': lineData.rect};
    }

    return null;
  }
  
  /// Helper to extract energy value from current line or next few lines
  Map<String, dynamic>? _extractEnergyValue(List<OCRLineData> lines, int index, RegExp regex, {int maxLookahead = 3}) {
    // Look ahead a few lines
    for (int j = index + 1; j < (index + 1 + maxLookahead).clamp(0, lines.length); j++) {
      final lineData = lines[j];
      final nextLine = lineData.text.toLowerCase();
      if (nextLine.trim().isEmpty) continue;

      if (regex.hasMatch(nextLine.trim())) {
         final valStr = regex.firstMatch(nextLine.trim())!.group(1)!.replaceAll(',', '.');
         final val = double.tryParse(valStr);
         if (val != null && val < 2000) return {'value': val, 'rect': lineData.rect};
      }
    }
    return null;
  }

  double? _extractGramValue(String text) {
    // 1. Strict check with unit
    final strictRegex = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(?:g|gr|gram)\s*$', caseSensitive: false);
    // 2. Misread 8/9 check (must have digit before 8/9)
    final misreadRegex = RegExp(r'^\s*(\d+(?:[.,]\d+)?)([89])\s*$', caseSensitive: false);
    // 3. Fallback no unit check
    final looseRegex = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*$', caseSensitive: false);
    
    String? valStr;
    
    if (strictRegex.hasMatch(text.trim())) {
      valStr = strictRegex.firstMatch(text.trim())!.group(1);
    } else if (misreadRegex.hasMatch(text.trim())) {
      final match = misreadRegex.firstMatch(text.trim())!;
      final choppedStr = match.group(1)!.replaceAll(',', '.');
      final tail = match.group(2)!;
      final fullVal = double.tryParse(choppedStr + tail);
      if (fullVal != null && fullVal > 50) {
        valStr = choppedStr;
      } else if (looseRegex.hasMatch(text.trim())) {
        valStr = looseRegex.firstMatch(text.trim())!.group(1);
      }
    } else if (looseRegex.hasMatch(text.trim())) {
      valStr = looseRegex.firstMatch(text.trim())!.group(1);
    }
    
    if (valStr != null) {
      valStr = valStr.replaceAll(',', '.');
      final val = double.tryParse(valStr);
      if (val != null && val >= 0.0 && val <= 200) {
        return val;
      }
    }
    return null;
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
// PHYSICAL FOOD PROMPT BOTTOM SHEET WIDGET
// ============================================

class PhysicalFoodPromptBottomSheet extends StatelessWidget {
  final ScannerController controller;

  const PhysicalFoodPromptBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.25, // Bisa diturunkan buat liat foto
      maxChildSize: 0.95, // Bisa ditarik full ke atas
      snap: true,
      snapSizes: const [0.25, 0.65, 0.95],
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
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Drag Handle (Tirai)
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const Text(
                      'Detail Makanan (Opsional)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bantu AI memprediksi dengan lebih akurat. Tulis detail porsi makananmu.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.scannedImagePath.value.isNotEmpty) {
                        return Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(controller.scannedImagePath.value),
                              height: 180, // Sedikit diperbesar biar jelas
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.physicalFoodPromptController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: 'Contoh: "Saya sarapan nasi uduk 2 centong, telor rebus 1 butir, ikan asin goreng 2 jari, oseng tempe 3 sendok (minyak sedang), dan es teh manis gula 2 sdt." Ceritakan juga metode masaknya (direbus/digoreng/dibakar) & takaran gula/minyaknya. Semakin detail ceritamu, semakin akurat AI memprediksi kalori dan gula!',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF009688), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                controller.closeAndResetScanner(); // Batal dan kembali ke scan
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                controller.isShowingPhysicalPrompt.value = false;
                                // Call AI with prompt
                                controller.processImageWithGemini(physicalPrompt: controller.physicalFoodPromptController.text);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009688),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Kirim ke AI', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

              Obx(() {
                final isLastPro = controller.isLastScanPro.value;
                if (isLastPro) return const SizedBox.shrink();

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Hasil scan kurang tepat atau gagal?',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => controller.switchToProCameraMode(fromBottomSheet: true),
                        icon: const Icon(Icons.auto_awesome, size: 20, color: Colors.orange),
                        label: const Text(
                          'Coba Scan Pro AI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),

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

// ============================================
// SCANNER OVERLAY PAINTER
// ============================================

class ScannerOverlayPainter extends CustomPainter {
  final Rect? sugarRect;
  final Rect? caloriesRect;
  final Size? imageSize;

  ScannerOverlayPainter({
    required this.sugarRect,
    required this.caloriesRect,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null || imageSize!.width == 0 || imageSize!.height == 0) return;

    // Calculate the scale ratios
    final double scaleX = size.width / imageSize!.width;
    final double scaleY = size.height / imageSize!.height;

    // We use a BoxFit.cover or BoxFit.contain logic depending on how we render the image.
    // Assuming we use BoxFit.contain for the preview, we need to find the actual drawn size area.
    // Let's implement a simple BoxFit.contain matching logic:
    double ratioX = size.width / imageSize!.width;
    double ratioY = size.height / imageSize!.height;
    double scale = dart_math.min(ratioX, ratioY);

    double drawnWidth = imageSize!.width * scale;
    double drawnHeight = imageSize!.height * scale;

    double dx = (size.width - drawnWidth) / 2;
    double dy = (size.height - drawnHeight) / 2;

    final paintSugar = Paint()
      ..color = const Color(0xFFEF9A9A).withOpacity(0.5) // Lower opacity for better transparency
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final paintCalories = Paint()
      ..color = const Color(0xFFFFCC80).withOpacity(0.5) // Lower opacity for better transparency
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawHorizontalHighlight(Rect? rect, Paint strokePaint, String label) {
      if (rect != null) {
        // Map original image coordinates to screen coordinates
        final scaledRect = Rect.fromLTRB(
          rect.left * scale + dx,
          rect.top * scale + dy,
          rect.right * scale + dx,
          rect.bottom * scale + dy,
        );
        
        // Geser posisi Y lebih ke atas (persis di tengah-tengah font)
        final yPosition = scaledRect.center.dy;
        
        // Perlebar garis stabilo di sisi kiri dan kanan
        final startPoint = Offset(scaledRect.left - 12, yPosition);
        final endPoint = Offset(scaledRect.right + 12, yPosition);
        
        // Ketebalan garis disesuaikan hampir sepenuh tinggi font (90%)
        strokePaint.strokeWidth = scaledRect.height * 0.9;
        if(strokePaint.strokeWidth < 6.0) strokePaint.strokeWidth = 6.0;

        canvas.drawLine(startPoint, endPoint, strokePaint);
        
        print('🖌️ Drawing $label Horizontal Highlight');
      }
    }

    drawHorizontalHighlight(sugarRect, paintSugar, 'Sugar');
    drawHorizontalHighlight(caloriesRect, paintCalories, 'Calories');
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.sugarRect != sugarRect ||
        oldDelegate.caloriesRect != caloriesRect ||
        oldDelegate.imageSize != imageSize;
  }
}

class OCRLineData {
  final String text;
  final Rect rect;
  OCRLineData(this.text, this.rect);
}
