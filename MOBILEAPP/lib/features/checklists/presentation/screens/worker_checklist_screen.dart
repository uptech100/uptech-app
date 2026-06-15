import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/checklist_providers.dart';
import '../../data/checklist_repository_impl.dart';

class WorkerChecklistScreen extends ConsumerWidget {
  const WorkerChecklistScreen({super.key});

  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(checklistDateProvider),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      ref.read(checklistDateProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistsAsync = ref.watch(myChecklistsProvider);
    final selectedDate = ref.watch(checklistDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Daily Checklists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDate(context, ref),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppTheme.primaryColor.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Showing checklists for:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: checklistsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (checklists) {
                if (checklists.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success),
                        SizedBox(height: 16),
                        Text('No checklists due for this date!', style: TextStyle(fontSize: 18, color: AppTheme.textMuted)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: checklists.length,
                  itemBuilder: (context, index) {
                    final c = checklists[index];
                    final isCompleted = c['status'] == 'Completed';

                    return Card(
                      elevation: isCompleted ? 0 : 2,
                      color: isCompleted ? Colors.grey.shade100 : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isCompleted ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isCompleted ? AppTheme.success.withOpacity(0.2) : AppTheme.warning.withOpacity(0.2),
                          child: Icon(
                            isCompleted ? Icons.check : Icons.pending_actions,
                            color: isCompleted ? AppTheme.success : AppTheme.warning,
                          ),
                        ),
                        title: Text(
                          c['taskName'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            color: isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text('Frequency: ${c['frequency']}'),
                        trailing: isCompleted
                            ? const Chip(label: Text('Completed', style: TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: AppTheme.success)
                            : ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final repo = ref.read(checklistRepositoryProvider);
                                    final dateString = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                                    await repo.markChecklistComplete({
                                      'templateId': c['id'],
                                      'date': dateString,
                                    });
                                    ref.invalidate(myChecklistsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as complete!'), backgroundColor: AppTheme.success));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Complete'),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
