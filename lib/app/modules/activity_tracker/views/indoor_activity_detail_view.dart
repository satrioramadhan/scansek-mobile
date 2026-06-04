import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/modules/activity_tracker/controllers/activity_tracker_controller.dart';
import 'package:scansek/app/services/smartwatch_sync_service.dart';

class IndoorActivityDetailView extends StatelessWidget {
  final Map<String, dynamic> activity;

  const IndoorActivityDetailView({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final typeStr = activity['type']?.toString() ?? 'other';
    final displayType = SmartwatchSyncService.getActivityLabel(typeStr);
    final iconData = ActivityTrackerController.getActivityIcon(typeStr);
    final activityColor = ActivityTrackerController.getActivityColor(typeStr);
    
    final duration = (activity['duration'] as num?)?.toDouble() ?? 0.0;
    final calories = (activity['caloriesBurned'] as num?)?.toDouble() ?? 0.0;
    // Sengaja di-set 0 biar UI nggak nampilin langkah dan jarak (karena indoor)
    final steps = 0;
    final distance = 0.0;
    final avgHR = activity['avgHeartRate'] as num?;
    final source = activity['source']?.toString() ?? 'manual';
    final category = activity['category']?.toString() ?? 'indoor';
    
    // Format duration
    String formattedDuration;
    if (duration >= 60) {
      final hours = (duration / 60).floor();
      final mins = (duration % 60).round();
      formattedDuration = '${hours}j ${mins}m';
    } else {
      formattedDuration = '${duration.round()} menit';
    }
    
    // Parse times
    DateTime? startTime;
    DateTime? endTime;
    try {
      var startTs = activity['startTime'].toString();
      if (!startTs.endsWith('Z')) startTs += 'Z';
      var endTs = activity['endTime'].toString();
      if (!endTs.endsWith('Z')) endTs += 'Z';
      
      startTime = DateTime.parse(startTs).toLocal();
      endTime = DateTime.parse(endTs).toLocal();
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Detail Aktivitas',
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF81C784), // Solid green matching gradient top
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevent color change on scroll
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ===== HEADER SECTION =====
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF81C784), // Soft Green
                    activityColor.withOpacity(0.9), // Blend with activity color
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  // Activity Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Activity Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                        onPressed: () {
                          final controller = Get.find<ActivityTrackerController>();
                          final textController = TextEditingController(text: typeStr == 'other' ? '' : displayType);
                          
                          Get.dialog(
                            AlertDialog(
                              title: const Text('Edit Nama Aktivitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              content: TextField(
                                controller: textController,
                                decoration: InputDecoration(
                                  hintText: 'Misal: Angkat Dumble, Lompat Tali',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                textCapitalization: TextCapitalization.words,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (textController.text.trim().isNotEmpty) {
                                      // Konversi ke lowercase & underscore biar formatnya sama kayak type lain (opsional)
                                      // Tapi biarin aja sesuai input user buat custom name
                                      controller.editActivityType(activity, textController.text.trim());
                                      Get.back();
                                      Get.back(); // Kembali dari halaman detail biar UI list kereload
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: activityColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Category & Source badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(
                        category == 'indoor' ? 'Indoor' : 'Outdoor',
                        category == 'indoor' ? Icons.home_rounded : Icons.park_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        source == 'smartwatch' ? 'Smartwatch' : 'Smartphone',
                        source == 'smartwatch' ? Icons.watch_outlined : Icons.phone_android,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ===== STATS GRID =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Main stats row
                  Row(
                    children: [
                      // Kalori
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.whatshot,
                          label: 'Kalori Terbakar',
                          value: '${calories.toStringAsFixed(0)}',
                          unit: 'kcal',
                          color: const Color(0xFFFF5722),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Durasi
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer_outlined,
                          label: 'Durasi',
                          value: formattedDuration,
                          unit: '',
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Optional stats row
                  Row(
                    children: [
                      // Heart rate (if available)
                      if (avgHR != null)
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.favorite_rounded,
                            label: 'Detak Jantung',
                            value: '${avgHR.toStringAsFixed(0)}',
                            unit: 'BPM',
                            color: const Color(0xFFE91E63),
                          ),
                        ),
                      if (avgHR != null && (steps > 0 || distance > 0))
                        const SizedBox(width: 12),
                      // Steps (if > 0)
                      if (steps > 0)
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.directions_walk_rounded,
                            label: 'Langkah',
                            value: _formatNumber(steps),
                            unit: 'langkah',
                            color: const Color(0xFF43A047),
                          ),
                        ),
                      // Distance (if > 0, when there's no steps)
                      if (steps == 0 && distance > 0)
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.straighten_rounded,
                            imageAsset: 'assets/images/card/distance.png',
                            label: 'Jarak',
                            value: distance.toStringAsFixed(2),
                            unit: 'km',
                            color: const Color(0xFF8E24AA),
                          ),
                        ),
                      // Fill empty space if only one stat
                      if (avgHR == null && steps == 0 && distance == 0)
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                  
                  // Distance row (if both steps and distance exist)
                  if (steps > 0 && distance > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.straighten_rounded,
                            imageAsset: 'assets/images/card/distance.png',
                            label: 'Jarak',
                            value: distance.toStringAsFixed(2),
                            unit: 'km',
                            color: const Color(0xFF8E24AA),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ===== TIMELINE SECTION =====
            if (startTime != null && endTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTimelineRow(
                            icon: Icons.play_circle_filled,
                            color: const Color(0xFF43A047),
                            label: 'Mulai',
                            time: DateFormat('HH:mm').format(startTime),
                            date: DateFormat('dd MMM yyyy').format(startTime),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Container(
                              width: 2,
                              height: 24,
                              color: Colors.grey[300],
                            ),
                          ),
                          _buildTimelineRow(
                            icon: Icons.stop_circle,
                            color: const Color(0xFFE53935),
                            label: 'Selesai',
                            time: DateFormat('HH:mm').format(endTime),
                            date: DateFormat('dd MMM yyyy').format(endTime),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    IconData? icon,
    String? imageAsset,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: imageAsset != null
                ? Image.asset(
                    imageAsset,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  )
                : Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required IconData icon,
    required Color color,
    required String label,
    required String time,
    required String date,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
