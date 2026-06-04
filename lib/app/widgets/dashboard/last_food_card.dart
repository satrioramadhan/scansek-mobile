import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/core/utils/date_formatter.dart';
import 'package:scansek/app/data/models/food_model.dart';
import 'package:scansek/app/widgets/cards/custom_card.dart';

class LastFoodCard extends StatelessWidget {
  final FoodModel? food;

  const LastFoodCard({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    if (food == null) {
      return _buildEmptyState();
    }

    return CustomCard(
      // Removed onTap navigation as requested
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title + Time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    food!.isScanned ? Icons.qr_code_scanner_rounded : Icons.edit_note_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konsumsi Terakhir',
                        style: AppTextStyles.bodyLarge.copyWith( // Changed from caption (small) to bodyLarge/Medium + adjustment
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15, // Increased size
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.getTimeAgo(food!.consumptionTime),
                        style: AppTextStyles.bodyMedium.copyWith( // Changed from bodySmall
                          color: AppColors.textHint,
                          fontSize: 14, // Increased size (was 12)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Food Name - Large & Clear
            Text(
              food!.name,
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 20),

            // Details Section - Clean Row Layout (resembling a neat list/receipt but consistent UI)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA), // Very subtle grey background
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                   _buildDetailRow(
                    'Jumlah', 
                    '${food!.quantity}x',
                    Icons.layers_outlined,
                    Colors.grey,
                   ),
                   if (food!.weight > 0) ...[
                     const SizedBox(height: 12),
                     _buildDetailRow(
                      'Berat', 
                      '${food!.weight.toStringAsFixed(0)} ${food!.weightUnit}',
                      Icons.scale_outlined,
                      Colors.grey,
                     ),
                   ],
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 12),
                     child: Divider(height: 1, color: Colors.black12),
                   ),
                   _buildDetailRow(
                    'Gula', 
                    '${food!.totalSugar.toStringAsFixed(1)} g',
                    Icons.cookie_outlined,
                    const Color(0xFFE91E63), // Pink
                    isBold: true,
                   ),
                   const SizedBox(height: 12),
                   _buildDetailRow(
                    'Kalori', 
                    '${food!.totalCalories.toStringAsFixed(0)} kkal',
                    Icons.local_fire_department_outlined,
                    AppColors.chartOrange,
                    isBold: true,
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color.withOpacity(0.7)), // Increased from 16 to 17
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14, // Explicitly ensure readable size
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold, // Always bold as requested ("font kandungan kandungannya di bold")
            color: isBold ? Colors.black87 : AppColors.textPrimary, // Keep color logic or make all black87 if desired, but user just said bold. 
            // Let's stick to isBold for color distinction but force bold weight.
            // Actually user said "font kandungan kandungannya di bold coba", implying all content values.
            // But previous code only bolded Sugar and Calories.
            // "jumlah" and "berat" were not isBold.
            // I will set FontWeight.bold for ALL values.
             fontSize: 15, // Increased +1px (assuming bodyMedium is 14)
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada konsumsi',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Data makanan terakhirmu akan muncul di sini',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
