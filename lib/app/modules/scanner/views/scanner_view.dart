import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/scanner_controller.dart';

class ScannerView extends GetView<ScannerController> {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        return PopScope(
          canPop: !(controller.isShowingResult.value || controller.isShowingPhysicalPrompt.value),
          onPopInvoked: (didPop) {
            if (didPop) return;
            if (controller.isShowingResult.value || controller.isShowingPhysicalPrompt.value) {
              controller.closeAndResetScanner();
            }
          },
          child: !controller.isCameraInitialized.value
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF009688),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
            // Camera Preview (always behind everything)
            _buildCameraPreview(),

            // Only show UI overlay if no image is currently being displayed (scannedImagePath is empty)
            if (controller.scannedImagePath.value.isEmpty) ...[
              // Overlay dengan frame scan
              _buildScanOverlay(),

              // Bottom Bar
              _buildBottomBar(),
            ] else if (!controller.isShowingResult.value && (controller.isFromGallery.value || controller.showProOffer.value)) ...[
              // Action to discard frozen image if ML Kit or Gemini fails
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 2350),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Positioned(
                    bottom: 40 - (20 * (1 - value)), // Slide up animation
                    left: 24,
                    right: 24,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: ElevatedButton.icon(
                  onPressed: () {
                    controller.scannedImagePath.value = '';
                    controller.showProOffer.value = false;
                    controller.isFromGallery.value = false;
                  },
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  label: const Text(
                    'Batal & Ulangi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.red.withOpacity(0.4),
                  ),
                ),
              ),
            ],

            // Top Bar (Always visible to allow back/gallery actions, rendered ABOVE overlays unless image is frozen)
            if (controller.scannedImagePath.value.isEmpty)
              _buildTopBar(context),

            // Pro AI Offer (Banner replaces Button)
            if (controller.showProOffer.value && !controller.isCameraProMode.value && !controller.isProcessing.value)
              _buildProOfferBanner(),

            // 🌟 NEW: Persistent Bottom Sheet inside the Stack
            if (controller.isShowingResult.value)
              ScanResultBottomSheet(controller: controller),
              
            if (controller.isShowingPhysicalPrompt.value)
              PhysicalFoodPromptBottomSheet(controller: controller),

            // Processing Indicator
            if (controller.isProcessing.value || controller.isProScanning.value)
              _buildLoadingOverlay(),
          ],
        ),
      );
      }),
    );
  }

  Widget _buildLoadingOverlay() {
    final isPro = controller.isProScanning.value;
    
    return Container(
      color: isPro ? Colors.black.withOpacity(0.4) : Colors.black54,
      child: isPro
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Using a glowing progress indicator
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: Colors.orangeAccent,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 28),
                      const SizedBox(height: 16),
                      Text(
                        controller.isPhysicalFoodMode.value
                            ? 'Gemini AI sedang\nmenganalisa makanan...'
                            : 'Gemini AI sedang\nmenganalisa akurasi label...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: controller.isPhysicalFoodMode.value ? Colors.orangeAccent : const Color(0xFF009688),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.isPhysicalFoodMode.value ? 'Menganalisis Makanan...' : 'Memproses gambar...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProOfferBanner() {
    return Positioned(
      bottom: 200,
      left: 24,
      right: 24,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 2550),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 40 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gagal deteksi?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Gunakan AI Pro agar lebih akurat.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => controller.switchToProCameraMode(fromBottomSheet: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Coba AI Pro', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final imagePath = controller.scannedImagePath.value;
    
    if (imagePath.isNotEmpty) {
      return SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath), 
              fit: BoxFit.contain,
            ),
            CustomPaint(
              painter: ScannerOverlayPainter(
                sugarRect: controller.sugarRect.value,
                caloriesRect: controller.caloriesRect.value,
                imageSize: controller.imageSize.value,
              ),
            ),
          ],
        ),
      );
    }
    // Live camera preview
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.cameraController!.value.previewSize!.height,
          height: controller.cameraController!.value.previewSize!.width,
          child: CameraPreview(controller.cameraController!),
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    final frameColor = controller.isCameraProMode.value || controller.isPhysicalFoodMode.value ? Colors.orangeAccent : const Color(0xFF00BFA5);
    final hintText = controller.isPhysicalFoodMode.value 
        ? 'Arahin ke piring makanan\nuntuk ditebak AI'
        : controller.isCameraProMode.value 
            ? 'Arahin ke label khusus\nuntuk diproses AI' 
            : 'Arahin ke label\nInformasi Nilai Gizi';

    return Stack(
      children: [
        // Semi-transparent overlay (not too dark)
        Container(
          color: Colors.black.withOpacity(0.3),
        ),
        
        // Clear center area
        Center(
          child: Container(
            width: 300,
            height: 400,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Stack(
              children: [
                // Top Left Corner
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: frameColor, width: 4),
                        left: BorderSide(color: frameColor, width: 4),
                      ),
                    ),
                  ),
                ),
                
                // Top Right Corner
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: frameColor, width: 4),
                        right: BorderSide(color: frameColor, width: 4),
                      ),
                    ),
                  ),
                ),
                
                // Bottom Left Corner
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: frameColor, width: 4),
                        left: BorderSide(color: frameColor, width: 4),
                      ),
                    ),
                  ),
                ),
                
                // Bottom Right Corner
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: frameColor, width: 4),
                        right: BorderSide(color: frameColor, width: 4),
                      ),
                    ),
                  ),
                ),
                
                // Center instruction
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hintText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (controller.isCameraProMode.value) {
                    controller.isCameraProMode.value = false;
                  } else {
                    Get.back();
                  }
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Obx(() => Container(
                      height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Button Kemasan
                        GestureDetector(
                          onTap: () => controller.isPhysicalFoodMode.value = false,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: !controller.isPhysicalFoodMode.value ? const Color(0xFF009688) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.qr_code, size: 16, color: !controller.isPhysicalFoodMode.value ? Colors.white : Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  'Kemasan',
                                  style: TextStyle(
                                    color: !controller.isPhysicalFoodMode.value ? Colors.white : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: !controller.isPhysicalFoodMode.value ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Button Makanan
                        GestureDetector(
                          onTap: () => controller.isPhysicalFoodMode.value = true,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: controller.isPhysicalFoodMode.value ? Colors.orangeAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.restaurant, size: 16, color: controller.isPhysicalFoodMode.value ? Colors.white : Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  'Piring/Fisik',
                                  style: TextStyle(
                                    color: controller.isPhysicalFoodMode.value ? Colors.white : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: controller.isPhysicalFoodMode.value ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    )),
                  ),
                ),
              ),
              Obx(() => IconButton(
                onPressed: controller.toggleFlash,
                icon: Icon(
                  controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                  color: controller.isFlashOn.value ? Colors.orangeAccent : Colors.white,
                  size: 28,
                ),
              )),
              IconButton(
                onPressed: controller.pickImageFromGallery,
                icon: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Capture Button
              GestureDetector(
                onTap: controller.captureAndProcess,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.isPhysicalFoodMode.value ? Colors.orangeAccent : const Color(0xFF009688),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Manual Input Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.goToAddFoodManual,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Input Manual',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}
