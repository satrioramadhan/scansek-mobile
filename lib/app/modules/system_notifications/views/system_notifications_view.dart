import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import '../controllers/system_notifications_controller.dart';

class SystemNotificationsView extends GetView<SystemNotificationsController> {
  const SystemNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Notifikasi Sistem',
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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan Mode',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Obx(() => SwitchListTile(
                value: controller.isFastingMode.value,
                onChanged: controller.toggleFastingMode,
                activeColor: Colors.blueAccent,
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: controller.isFastingMode.value ? Colors.blueAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.nights_stay_rounded, 
                    color: controller.isFastingMode.value ? Colors.blueAccent : Colors.grey,
                  ),
                ),
                title: const Text('Mode Puasa', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Nonaktifkan pengingat makan siang dan sesuaikan notifikasi.', style: TextStyle(fontSize: 12)),
              )),
            ),

            const SizedBox(height: 32),

            const Text(
              'Jadwal Bawaan Saat Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            Obx(() {
              if (controller.isFastingMode.value) {
                return Column(
                  children: [
                    _buildInfoCard(Icons.free_breakfast, 'Sahur', '03:10', 'Pengingat makan bergizi sebelum ibadah puasa dimulai', Colors.deepPurple),
                    _buildInfoCard(Icons.dinner_dining, 'Buka Puasa', '18:30', 'Pengingat pencatatan nutrisi saat berbuka', Colors.orange),
                    _buildInfoCard(Icons.directions_run, 'Aktivitas', '16:00', 'Pengingat kecil untuk peregangan otot ringan', Colors.green),
                    _buildInfoCard(Icons.monitor_weight, 'Update BMI', '19:30', 'Seminggu sekali cek berat badan rutin', Colors.blue),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildInfoCard(Icons.local_drink, 'Air Putih', '09:00 & 15:00', 'Pengingat hidrasi tubuh utama', Colors.lightBlue),
                    _buildInfoCard(Icons.restaurant, 'Konsumsi', '11:00 & 18:00', 'Pengingat pencatatan makan berat & ngemil', Colors.orange),
                    _buildInfoCard(Icons.directions_run, 'Aktivitas', '16:00', 'Pengingat peregangan otot harian', Colors.green),
                    _buildInfoCard(Icons.monitor_weight, 'Update BMI', '19:30', 'Seminggu sekali cek berat badan rutin', Colors.blue),
                  ],
                );
              }
            }),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Sistem akan otomatis mengatur pengingat\ntanpa mengganggu konsentrasi harianmu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String time, String desc, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(time, style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
