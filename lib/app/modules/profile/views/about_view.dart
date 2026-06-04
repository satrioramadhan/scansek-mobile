import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF80CBC4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // App Logo/Icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Name
            Text(
              'ScanSek',
              style: AppTextStyles.h1.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF80CBC4),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Version
            Text(
              'Versi 1.0.0 (Build 1)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Description Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF80CBC4).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF80CBC4),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tentang ScanSek',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ScanSek adalah asisten "Mindful Eating" cerdas yang dibuat oleh developer tampan untuk membantu kamu memantau asupan kalori, memangkas gula berlebih, dan melacak aktivitas fisik harian tanpa diet yang menyiksa.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kini dilengkapi dengan teknologi AI Scan Pro! Kamu tidak hanya bisa memindai informasi nilai gizi pada kemasan, tapi juga bisa mengenali makanan fisik di piringmu atau sekadar mengetik menu makananmu, biarkan AI yang menghitung semuanya.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Developer Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF80CBC4).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.code,
                        color: const Color(0xFF80CBC4),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Developer',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Satrio Ramadhan',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'support@scansek.my.id',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: '© 2026 ScanSek',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Footer
            Text(
              'Dibuat dengan ❤️ untuk hidup lebih sehat',
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
