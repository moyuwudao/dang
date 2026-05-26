import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? remindAt;
  final bool isCompleted;
  final String? relatedRecordId;

  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.remindAt,
    this.isCompleted = false,
    this.relatedRecordId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'remindAt': remindAt?.toIso8601String(),
        'isCompleted': isCompleted,
        'relatedRecordId': relatedRecordId,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        remindAt: json['remindAt'] != null
            ? DateTime.parse(json['remindAt'] as String)
            : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
        relatedRecordId: json['relatedRecordId'] as String?,
      );

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? remindAt,
    bool? isCompleted,
    String? relatedRecordId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      remindAt: remindAt ?? this.remindAt,
      isCompleted: isCompleted ?? this.isCompleted,
      relatedRecordId: relatedRecordId ?? this.relatedRecordId,
    );
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<Reminder>>((ref) {
  return RemindersNotifier();
});

class RemindersNotifier extends StateNotifier<List<Reminder>> {
  static const String _storageKey = 'changji_reminders';

  RemindersNotifier() : super([]) {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> data = jsonDecode(jsonStr);
        state = data
            .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }
            if (a.remindAt != null && b.remindAt != null) {
              return a.remindAt!.compareTo(b.remindAt!);
            }
            return b.createdAt.compareTo(a.createdAt);
          });
      } catch (e) {
        AppLogger().e('Reminders', 'Failed to load reminders: $e');
      }
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> addReminder(String title,
      {String? description,
      DateTime? remindAt,
      String? relatedRecordId}) async {
    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      remindAt: remindAt,
      relatedRecordId: relatedRecordId,
    );
    state = [...state, reminder];
    await _saveReminders();
  }

  Future<void> toggleComplete(String id) async {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(isCompleted: !r.isCompleted);
      }
      return r;
    }).toList();
    await _saveReminders();
  }

  Future<void> deleteReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _saveReminders();
  }

  Future<void> updateReminder(String id,
      {String? title, String? description, DateTime? remindAt}) async {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(
          title: title ?? r.title,
          description: description ?? r.description,
          remindAt: remindAt ?? r.remindAt,
        );
      }
      return r;
    }).toList();
    await _saveReminders();
  }
}

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reminders = ref.watch(remindersProvider);
    final notifier = ref.read(remindersProvider.notifier);

    final pendingReminders = reminders.where((r) => !r.isCompleted).toList();
    final completedReminders = reminders.where((r) => r.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.smartReminders),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: reminders.isEmpty
          ? _buildEmptyState(context, l10n)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pendingReminders.isNotEmpty) ...[
                  _buildSectionTitle(
                      context, '${l10n.statusPending} (${pendingReminders.length})'),
                  const SizedBox(height: 8),
                  ...pendingReminders.map((r) => _ReminderCard(
                        reminder: r,
                        onToggle: () => notifier.toggleComplete(r.id),
                        onDelete: () => _confirmDelete(context, notifier, r, l10n),
                        onEdit: () => _showEditDialog(context, notifier, r, l10n),
                        l10n: l10n,
                      )),
                ],
                if (completedReminders.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                      context, '${l10n.statusCompleted} (${completedReminders.length})'),
                  const SizedBox(height: 8),
                  ...completedReminders.map((r) => _ReminderCard(
                        reminder: r,
                        onToggle: () => notifier.toggleComplete(r.id),
                        onDelete: () => _confirmDelete(context, notifier, r, l10n),
                        onEdit: () => _showEditDialog(context, notifier, r, l10n),
                        l10n: l10n,
                      )),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, notifier, l10n),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noReminders,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tapToAddReminder,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  void _showAddDialog(BuildContext context, RemindersNotifier notifier, AppLocalizations l10n) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.addReminder),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: l10n.title,
                    hintText: l10n.title,
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.description,
                    hintText: l10n.description,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(selectedDate == null
                      ? l10n.selectDate
                      : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'),
                  trailing: selectedDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            selectedDate = null;
                            selectedTime = null;
                          }),
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    }
                  },
                ),
                if (selectedTime != null)
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(
                        '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  DateTime? remindAt;
                  if (selectedDate != null && selectedTime != null) {
                    remindAt = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                  } else if (selectedDate != null) {
                    remindAt = selectedDate;
                  }
                  notifier.addReminder(
                    titleController.text.trim(),
                    description: descController.text.trim().isNotEmpty
                        ? descController.text.trim()
                        : null,
                    remindAt: remindAt,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, RemindersNotifier notifier, Reminder reminder, AppLocalizations l10n) {
    final titleController = TextEditingController(text: reminder.title);
    final descController =
        TextEditingController(text: reminder.description ?? '');
    DateTime? selectedDate = reminder.remindAt;
    TimeOfDay? selectedTime = reminder.remindAt != null
        ? TimeOfDay(
            hour: reminder.remindAt!.hour, minute: reminder.remindAt!.minute)
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.editReminder),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: l10n.title,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.description,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(selectedDate == null
                      ? l10n.selectDate
                      : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'),
                  trailing: selectedDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            selectedDate = null;
                            selectedTime = null;
                          }),
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  DateTime? remindAt;
                  if (selectedDate != null && selectedTime != null) {
                    remindAt = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                  } else if (selectedDate != null) {
                    remindAt = selectedDate;
                  }
                  notifier.updateReminder(
                    reminder.id,
                    title: titleController.text.trim(),
                    description: descController.text.trim().isNotEmpty
                        ? descController.text.trim()
                        : null,
                    remindAt: remindAt,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, RemindersNotifier notifier, Reminder reminder, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text('${l10n.confirmDelete} "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              notifier.deleteReminder(reminder.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final AppLocalizations l10n;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = reminder.remindAt != null &&
        !reminder.isCompleted &&
        reminder.remindAt!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isOverdue ? AppColors.error.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: reminder.isCompleted,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: reminder.isCompleted
                            ? AppColors.textTertiary
                            : null,
                      ),
                    ),
                    if (reminder.description != null &&
                        reminder.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (reminder.remindAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isOverdue ? AppColors.error : AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(context, reminder.remindAt!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isOverdue ? AppColors.error : AppColors.info,
                              fontWeight: isOverdue ? FontWeight.w600 : null,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.overdue,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today,
                    color: AppColors.info, size: 20),
                onPressed: () => _addToCalendar(context),
                tooltip: l10n.addToCalendar,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.textTertiary),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (dateDay == today) {
      dateStr = l10n.today;
    } else if (dateDay == today.add(const Duration(days: 1))) {
      dateStr = l10n.tomorrow;
    } else {
      dateStr = '${dateTime.month}${l10n.month}${dateTime.day}${l10n.day}';
    }

    return '$dateStr ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _addToCalendar(BuildContext context) async {
    final title = Uri.encodeComponent(reminder.title);
    final desc = Uri.encodeComponent(reminder.description ?? '');
    final startTime =
        reminder.remindAt ?? DateTime.now().add(const Duration(hours: 1));
    final endTime = startTime.add(const Duration(hours: 1));

    final startStr =
        '${startTime.year}${startTime.month.toString().padLeft(2, '0')}${startTime.day.toString().padLeft(2, '0')}T${startTime.hour.toString().padLeft(2, '0')}${startTime.minute.toString().padLeft(2, '0')}00';
    final endStr =
        '${endTime.year}${endTime.month.toString().padLeft(2, '0')}${endTime.day.toString().padLeft(2, '0')}T${endTime.hour.toString().padLeft(2, '0')}${endTime.minute.toString().padLeft(2, '0')}00';

    final url = Uri.parse(
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&details=$desc&dates=$startStr/$endStr');

    if (context.mounted) {
      try {
        await _launchUrl(url);
      } catch (e) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.cannotOpenCalendar(e.toString())), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _launchUrl(Uri url) async {
    final uri = url;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $uri';
    }
  }
}
