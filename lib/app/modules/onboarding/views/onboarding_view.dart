import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/buttons/custom_button.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface, // Clean white surface
      body: SafeArea(
        child: Column(
          children: [
            // Page view
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                children: const [
                  OnboardingPage(
                    step: 1,
                    title: 'Scan Nutrisi Makanan',
                    description: 'Scan kemasan makanan dan dapatkan info nutrisi lengkap secara instan.',
                    graphic: Step1Graphic(),
                  ),
                  OnboardingPage(
                    step: 2,
                    title: 'Pantau Kesehatan Harian',
                    description: 'Catat konsumsi gula, kalori, air, dan aktivitas fisik kamu setiap hari.',
                    graphic: Step2Graphic(),
                  ),
                  OnboardingPage(
                    step: 3,
                    title: 'Lacak Aktivitas Fisik',
                    description: 'Dukung 4 mode aktivitas olahraga dan tersinkronisasi otomatis dengan Smartwatch.',
                    graphic: Step3Graphic(), // Smartwatch Graphic
                  ),
                  OnboardingPage(
                    step: 4,
                    title: 'Lihat Progress Kamu',
                    description: 'Grafik interaktif untuk memantau perkembangan kesehatan kamu.',
                    graphic: Step4Graphic(), // Rocket Graphic
                  ),
                  OnboardingPage(
                    step: 5,
                    title: 'Atur Pengingat',
                    description: 'Pengingat minum air dan aktivitas fisik agar target harian tercapai.',
                    graphic: Step5Graphic(), // Bell Graphic
                  ),
                ],
              ),
            ),

            // Dots indicator
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5, // Now 5 steps
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: controller.currentPage.value == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: controller.currentPage.value == index
                            ? AppColors.primary
                            : AppColors.gray200, // Softer gray for inactive dots
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                )),

            const SizedBox(height: 48),

            // Bottom Navigation Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip or Back Button
                    TextButton(
                      onPressed: () {
                        if (controller.currentPage.value == 0) {
                          controller.skip();
                        } else {
                          controller.pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        backgroundColor: AppColors.gray100, // Soft background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        controller.currentPage.value == 0 ? 'SKIP' : 'BACK',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Next or Start Button
                    ElevatedButton(
                      onPressed: controller.nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        backgroundColor: AppColors.primary, // Bright background
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        controller.currentPage.value == 4 ? 'START' : 'NEXT', // Check against 4
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Individual onboarding page widget with floating graphic animation
class OnboardingPage extends StatefulWidget {
  final int step;
  final String title;
  final String description;
  final Widget graphic;

  const OnboardingPage({
    super.key,
    required this.step,
    required this.title,
    required this.description,
    required this.graphic,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Graphic Area with floating animation
          Expanded(
            flex: 5,
            child: Center(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  final t = _floatController.value;
                  // Gentle vertical bobbing (8px range)
                  final offset = sin(t * pi * 2) * 8;
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: child,
                  );
                },
                child: widget.graphic,
              ),
            ),
          ),

          // Content Area
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),

                const SizedBox(height: 8),

                // Step Indicator
                Text(
                  'step ${widget.step}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Graphics that match the reference style ---

class Step1Graphic extends StatelessWidget {
  const Step1Graphic({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Giant background rotated square (Left, bleeding off)
        Positioned(
          left: -80,
          top: -20,
          child: Transform.rotate(
            angle: -0.25,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.chartWater.withOpacity(0.12),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
        ),
        // Large Background Circle (Right bottom)
        Positioned(
          right: -60,
          bottom: -20,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.chartOrange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // Floating scanner decorative elements
        Positioned(
          top: 0,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
          ),
        ),
        Positioned(
          bottom: 20,
          left: -10,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.chartOrange, size: 28),
          ),
        ),
        
        // The Mockup Phone (Center)
        Container(
          width: 170,
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray200, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera screen background
                Container(color: AppColors.gray50),
                
                // Viewfinder bracket
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                
                // Scanned Object (Packaged Food)
                const Icon(Icons.fastfood_rounded, size: 60, color: AppColors.chartOrange),
                
                // Scanning Laser Line
                Positioned(
                  top: 140, // Middle of the screen
                  child: Container(
                    width: 140,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom UI panel on phone
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
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
}

class Step2Graphic extends StatelessWidget {
  const Step2Graphic({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Giant Background blob
        Positioned(
          left: -40,
          right: -40,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(120),
                bottomRight: Radius.circular(150),
                topRight: Radius.circular(60),
                bottomLeft: Radius.circular(80),
              ),
            ),
          ),
        ),
        
        // Large Scattered elements
        Positioned(
          top: -20,
          left: 10,
          child: Transform.rotate(
            angle: -0.2,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.chartOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          right: 20,
          child: Transform.rotate(
            angle: 0.4,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.chartWater.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        
        // Floating checkmarks / icons
        Positioned(
          top: 30,
          right: -20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.chartOrange, size: 36),
          ),
        ),
        Positioned(
          bottom: 20,
          left: -10,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded, color: AppColors.chartWater, size: 36),
          ),
        ),

        // Center Task List Mockup
        Container(
          width: 200,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                height: 12, 
                width: 80, 
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                margin: const EdgeInsets.only(bottom: 24),
              ),
              
              // Task 1 (Checked)
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 8, width: double.infinity, color: AppColors.gray200),
                        const SizedBox(height: 6),
                        Container(height: 8, width: 40, color: AppColors.gray200),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Task 2 (Checked)
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.chartWater, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 8, width: double.infinity, color: AppColors.gray200),
                        const SizedBox(height: 6),
                        Container(height: 8, width: 60, color: AppColors.gray200),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Task 3 (Unchecked)
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray300, width: 3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 8, width: double.infinity, color: AppColors.gray200),
                        const SizedBox(height: 6),
                        Container(height: 8, width: 50, color: AppColors.gray200),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Step3Graphic extends StatelessWidget {
  const Step3Graphic({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Giant background
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            color: AppColors.chartOrange.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          top: -20,
          right: -20,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),

        // Activity Floating Icons
        Positioned(
          top: 0,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: const Icon(Icons.directions_run_rounded, color: AppColors.chartOrange, size: 28),
          ),
        ),
        Positioned(
          top: 60,
          right: -10,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: const Icon(Icons.directions_bike_rounded, color: AppColors.chartWater, size: 28),
          ),
        ),
        Positioned(
          bottom: 40,
          left: -10,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 28),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 30,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: const Icon(Icons.pool_rounded, color: AppColors.chartActivityWalking, size: 28),
          ),
        ),

        // Smartwatch Illustration
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Strap
            Container(
              width: 70,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            // Watch Face
            Container(
              width: 140,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50), // Dark smart watch body
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.chartCaloriesConsumed, size: 48),
                    const SizedBox(height: 8),
                    Container(height: 6, width: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(height: 6),
                    Container(height: 6, width: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(3))),
                  ],
                ),
              ),
            ),
            // Bottom Strap
            Container(
              width: 70,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Step4Graphic extends StatelessWidget {
  const Step4Graphic({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Giant Background blob 1 (cloud-like)
        Positioned(
          right: -60,
          top: -20,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.chartOrange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -40,
          bottom: -20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Clouds (Enlarged)
        Positioned(
          top: 20,
          left: -20,
          child: Icon(Icons.cloud, size: 90, color: AppColors.gray200.withOpacity(0.6)),
        ),
        Positioned(
          bottom: 10,
          right: -10,
          child: Icon(Icons.cloud, size: 120, color: AppColors.gray200.withOpacity(0.6)),
        ),
        Positioned(
          top: 80,
          right: -40,
          child: Icon(Icons.cloud, size: 60, color: AppColors.chartWater.withOpacity(0.2)),
        ),
        
        // Stars/Dots
        Positioned(
          top: -10,
          left: 60,
          child: Icon(Icons.star_rounded, size: 30, color: AppColors.chartOrange.withOpacity(0.4)),
        ),
        Positioned(
          bottom: 80,
          left: 10,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Rocket
        Transform.rotate(
          angle: 0.8, // pointing up-right
          child: const Icon(
            Icons.rocket_launch_rounded,
            size: 200,
            color: AppColors.chartWater,
          ),
        ),
        
        // Fire/Thrust
        Positioned(
          bottom: 20,
          left: 60,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.chartOrange,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          left: 20,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.chartOrange.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class Step5Graphic extends StatelessWidget {
  const Step5Graphic({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Giant Background
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.chartWater.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          right: -30,
          top: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        Positioned(
          left: -20,
          bottom: -10,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.chartOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        
        // Small decorative dots
        Positioned(
          top: 40,
          left: 20,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.chartOrange.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          right: 10,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.chartWater.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // Bell Icon
        const Icon(
          Icons.notifications_active_rounded,
          size: 180,
          color: AppColors.primary,
        ),
        
        // Calendar floating
        Positioned(
          top: 0,
          right: 10,
          child: Transform.rotate(
            angle: 0.2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppColors.chartOrange, size: 50),
            ),
          ),
        ),
        
        // Clock floating
        Positioned(
          bottom: 20,
          left: -10,
          child: Transform.rotate(
            angle: -0.2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Icon(Icons.access_time_filled_rounded, color: AppColors.chartWater, size: 50),
            ),
          ),
        ),
      ],
    );
  }
}
