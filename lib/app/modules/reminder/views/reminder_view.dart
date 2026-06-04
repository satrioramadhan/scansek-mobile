import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:scansek/app/data/models/reminder_model.dart';
import '../../../widgets/snackbars/snackbar_designs.dart'; // ElegantSnackbar
import '../controllers/reminder_controller.dart';

class ReminderView extends GetView<ReminderController> {
  const ReminderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background
      appBar: AppBar(
        title: const Text(
          'Pengingat',
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
      body:
      Obx(() {
        if (controller.isLoading.value && controller.reminders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.reminders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.reminders.length,
          itemBuilder: (context, index) {
            final reminder = controller.reminders[index];
            return _buildReminderCard(reminder);
          },
        );
      }),
      floatingActionButton: SizedBox(
        width: 65,
        height: 65,
        child: FloatingActionButton(
          onPressed: () => _showAddReminderDialog(context),
          backgroundColor: const Color(0xFF80CBC4), // Soft teal to match app theme
          elevation: 8,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada pengingat nih, yuk tambah!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambahkan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF80CBC4).withOpacity(0.15), // Unified teal theme
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  reminder.type.iconData,
                  color: const Color(0xFF80CBC4), // Soft teal for all icons
                  size: 28,
                ),
              ),
              title: Text(
                reminder.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${reminder.time.format(Get.context!)} • ${reminder.frequency.label}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (reminder.frequency == ReminderFrequency.custom) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getCustomDaysText(reminder.customDays),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  // Show custom message if exists
                  if (reminder.customMessage?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF80CBC4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF80CBC4).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.message,
                            size: 12,
                            color: const Color(0xFF80CBC4),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              reminder.customMessage!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: reminder.isEnabled,
                    onChanged: (_) => controller.toggleReminder(reminder.id),
                    activeColor: const Color(0xFF80CBC4), // Soft teal for switch
                  ),
                  // Three-dot menu button
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditReminderDialog(Get.context!, reminder);
                      } else if (value == 'delete') {
                        controller.deleteReminder(reminder.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: const Color(0xFF80CBC4)),
                            const SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: const Color(0xFFEF9A9A)),
                            const SizedBox(width: 12),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }

  String _getCustomDaysText(List<int> days) {
    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final sortedDays = List<int>.from(days)..sort();
    return sortedDays.map((d) => dayNames[d - 1]).join(', ');
  }

  void _showAddReminderDialog(BuildContext context) {
    _showReminderDialog(context, null);
  }

  void _showEditReminderDialog(BuildContext context, ReminderModel reminder) {
    _showReminderDialog(context, reminder);
  }

  void _showReminderDialog(BuildContext context, ReminderModel? existingReminder) {
    final isEdit = existingReminder != null;
    final titleController = TextEditingController(text: existingReminder?.title ?? '');
    final customMessageController = TextEditingController(text: existingReminder?.customMessage ?? '');
    final typeController = (existingReminder?.type ?? ReminderType.water).obs;
    final timeController = (existingReminder?.time ?? TimeOfDay.now()).obs;
    final frequencyController = (existingReminder?.frequency ?? ReminderFrequency.daily).obs;
    final customDays = <int>[].obs;
    if (existingReminder?.customDays != null) {
      customDays.addAll(existingReminder!.customDays);
    }
    
    // Add FormKey for validation
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            existingReminder == null ? 'Tambah Pengingat' : 'Edit Pengingat',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Type selector
                    const Text(
                      'Jenis Pengingat',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                      children: [
                        Expanded(
                          child: _buildTypeOption(
                            ReminderType.water,
                            typeController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeOption(
                            ReminderType.activity,
                            typeController,
                          ),
                        ),
                      ],
                    )),

                    const SizedBox(height: 20),

                    // Title input - Changed to TextFormField
                    const Text(
                      'Judul',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Misalnya: Minum Air Pagi',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judulnya di isi dong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Custom Message input (optional)
                    const Text(
                      'Pesan Notifikasi (opsional)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kosongkan untuk menggunakan pesan default',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customMessageController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Contoh: jangan lupa minum yaa bestie 😘',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Time picker
                    const Text(
                      'Waktu',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: timeController.value,
                            );
                            if (time != null) {
                              timeController.value = time;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time),
                                const SizedBox(width: 12),
                                Text(
                                  timeController.value.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )),

                    const SizedBox(height: 20),

                    // Frequency selector
                    const Text(
                      'Frekuensi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Column(
                          children: ReminderFrequency.values
                              .map((freq) => RadioListTile<ReminderFrequency>(
                                    title: Text(freq.label),
                                    value: freq,
                                    groupValue: frequencyController.value,
                                    onChanged: (value) {
                                      if (value != null) {
                                        frequencyController.value = value;
                                      }
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        )),

                    // Custom days selector (only if custom frequency)
                    Obx(() {
                      if (frequencyController.value != ReminderFrequency.custom) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            'Pilih Hari',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: List.generate(7, (index) {
                              final day = index + 1;
                              const dayNames = [
                                'Sen',
                                'Sel',
                                'Rab',
                                'Kam',
                                'Jum',
                                'Sab',
                                'Min'
                              ];

                              return Obx(() => FilterChip(
                                    label: Text(dayNames[index]),
                                    selected: customDays.contains(day),
                                    onSelected: (selected) {
                                      if (selected) {
                                        customDays.add(day);
                                      } else {
                                        customDays.remove(day);
                                      }
                                    },
                                    selectedColor: const Color(0xFF80CBC4), // Soft teal
                                    checkmarkColor: Colors.white,
                                  ));
                            }),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Validate form first
                              if (!formKey.currentState!.validate()) {
                                return;
                              }
                              
                              final title = titleController.text.trim();

                              if (frequencyController.value ==
                                      ReminderFrequency.custom &&
                                  customDays.isEmpty) {
                                ElegantSnackbar.error(
                                  context,
                                  'Pilih minimal 1 hari dulu yuk',
                                );
                                return;
                              }

                              final reminder = ReminderModel(
                                id: existingReminder?.id ??
                                    DateTime.now().millisecondsSinceEpoch.toString(),
                                title: title,
                                type: typeController.value,
                                time: timeController.value,
                                frequency: frequencyController.value,
                                customDays: customDays.toList(),
                                isEnabled: true,
                                customMessage: customMessageController.text.trim().isEmpty 
                                    ? null 
                                    : customMessageController.text.trim(),
                              );

                              if (isEdit) {
                                controller.updateReminder(reminder);
                              } else {
                                controller.addReminder(reminder);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF80CBC4), // Soft teal
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Simpan',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(ReminderType type, Rx<ReminderType> controller) {
    final isSelected = controller.value == type;

    return InkWell(
      onTap: () => controller.value = type,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF80CBC4).withOpacity(0.15) // Unified teal theme
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF80CBC4) // Soft teal for all types
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              type.iconData,
              size: 32,
              color: isSelected
                  ? const Color(0xFF80CBC4) // Soft teal for all types
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
