import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/routes/app_pages.dart';
import '../controllers/profile_controller.dart';
import 'package:scansek/app/widgets/bottom_sheets/update_body_metrics_bottom_sheet.dart' as scansek_bottom_sheet;
import 'about_view.dart';
import 'security_view.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF80CBC4),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchUserProfile,
        color: const Color(0xFF80CBC4),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Metrics Update Banner removed and moved to inline badge
            // Profile Card with BMI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF80CBC4).withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar + Name + Email
                  Row(
                    children: [
                      // Avatar
                      Obx(() {
                        final userName = controller.userName.value;
                        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
                        
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF80CBC4).withOpacity(0.15),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Color(0xFF80CBC4),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(width: 16),
                      
                      // Name + Email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Obx(() => Text(
                                    controller.userName.value.isNotEmpty
                                        ? controller.userName.value
                                        : 'User',
                                    style: AppTextStyles.h3.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                ),
                                Obx(() {
                                  if (controller.isFastingMode.value) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E88E5).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.nights_stay, color: Color(0xFF1E88E5), size: 12),
                                          SizedBox(width: 4),
                                          Text('Puasa', style: TextStyle(color: Color(0xFF1E88E5), fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                                Obx(() {
                                  if (controller.shouldShowUpdateMetricsBanner.value) {
                                    return GestureDetector(
                                      onTap: () {
                                        Get.bottomSheet(
                                          const scansek_bottom_sheet.UpdateBodyMetricsBottomSheet(),
                                          isScrollControlled: true,
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 12),
                                            const SizedBox(width: 4),
                                            Text('Update BB/TB', style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Obx(() => Text(
                              controller.userEmail.value.isNotEmpty
                                  ? controller.userEmail.value
                                  : 'user@example.com',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // BMI Section (only if profile complete)
                  Obx(() {
                    if (controller.bmi.value != null && 
                        controller.weight.value != null && 
                        controller.height.value != null) {
                      final bmiValue = controller.bmi.value!;
                      final category = controller.getBmiCategory();
                      final color = controller.getBmiColor();
                      
                      return Column(
                        children: [
                          const Divider(height: 24),
                          
                          // BMI Header
                          Row(
                            children: [
                              Text(
                                'Status Kesehatan',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'BMI: ${bmiValue.toStringAsFixed(1)}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '($category)',
                                      style: AppTextStyles.caption.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          
                          const SizedBox(height: 12),
                          
                          // Weight & Height Stats
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.monitor_weight_outlined,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Berat',
                                            style: AppTextStyles.caption.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            '${controller.weight.value!.toStringAsFixed(1)} kg',
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.height_outlined,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tinggi',
                                            style: AppTextStyles.caption.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            '${controller.height.value!.toStringAsFixed(0)} cm',
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.bold,
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
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Settings Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF80CBC4),
                    iconBgColor: const Color(0xFF80CBC4).withOpacity(0.15),
                    title: 'Edit Profil',
                    subtitle: 'Ubah nama dan foto profil',
                    onTap: () => Get.toNamed(Routes.EDIT_PROFILE),
                  ),
                  
                  const Divider(height: 24),
                  
                  _buildMenuItem(
                    icon: Icons.notifications_active_outlined,
                    iconColor: const Color(0xFFFFCC80),
                    iconBgColor: const Color(0xFFFFCC80).withOpacity(0.15),
                    title: 'Notifikasi',
                    subtitle: 'Pengaturan mode puasa dan jadwal',
                    onTap: () => Get.toNamed(Routes.SYSTEM_NOTIFICATIONS),
                  ),
                  
                  const Divider(height: 24),
                  
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFF90CAF9),
                    iconBgColor: const Color(0xFF90CAF9).withOpacity(0.15),
                    title: 'Keamanan',
                    subtitle: 'Ubah kata sandi',
                    onTap: () => Get.to(() => const SecurityView()),
                  ),
                  
                  const Divider(height: 24),
                  
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFFB39DDB),
                    iconBgColor: const Color(0xFFB39DDB).withOpacity(0.15),
                    title: 'Tentang Aplikasi',
                    subtitle: 'Informasi dan versi aplikasi',
                    onTap: () => Get.to(() => const AboutView()),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF9A9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                label: const Text(
                  'Keluar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
