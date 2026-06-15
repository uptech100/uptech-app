import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/screens/main_navigation_screen.dart';
import '../providers/worklog_providers.dart';
import '../../../checklists/presentation/providers/checklist_providers.dart';
import '../../../qc/presentation/screens/qc_history_screen.dart';
import '../../../dashboard/presentation/screens/worker_dashboard_screen.dart';
import '../../data/worklog_repository_impl.dart';

class WorkHistoryScreen extends ConsumerStatefulWidget {
  const WorkHistoryScreen({super.key});

  @override
  ConsumerState<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends ConsumerState<WorkHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showEditEntryDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> entry) async {
    final quantityController = TextEditingController(text: entry['quantity']?.toString() ?? '');
    final sizeController = TextEditingController(text: entry['size']?.toString() ?? '');
    final remarksController = TextEditingController(text: entry['remarks']?.toString() ?? '');
    String selectedUom = entry['uom']?.toString() ?? 'nos';
    if (!['nos', 'pair', 'set', 'kg', 'ltr'].contains(selectedUom)) selectedUom = 'nos';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sizeController,
                decoration: const InputDecoration(labelText: 'Material Size'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'UoM'),
                      value: selectedUom,
                      items: ['nos', 'pair', 'set', 'kg', 'ltr']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase())))
                          .toList(),
                      onChanged: (val) => selectedUom = val!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(worklogRepositoryProvider).updateWorkEntry(
                  entry['id'],
                  {
                    'quantity': quantityController.text,
                    'uom': selectedUom,
                    'size': sizeController.text,
                    'remarks': remarksController.text,
                  },
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      ref.invalidate(workHistoryProvider);
      ref.invalidate(todayLogProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry updated successfully')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(workHistoryProvider);
    final departmentAsync = ref.watch(userDepartmentProvider);
    final isQC = departmentAsync.value?.contains('QC') == true || departmentAsync.value?.contains('QUALITY') == true;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              ref.read(bottomNavIndexProvider.notifier).state = 0;
            },
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: isQC ? 'QC Logs' : 'Daily Logs', icon: const Icon(Icons.work_history)),
              const Tab(text: 'Checklists', icon: Icon(Icons.checklist_rtl)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(workHistoryProvider);
                ref.invalidate(checklistHistoryProvider);
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Daily Logs (Original Work History or QC History)
            isQC ? const QCHistoryScreen() : Column(
        children: [
          // Filter / Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filter by Process or Product name...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          // History List
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (logs) {
                if (logs.isEmpty) {
                  return const Center(child: Text('No work history found.'));
                }

                // Filter logs based on search query
                final filteredLogs = logs.where((log) {
                  if (_searchQuery.isEmpty) return true;
                  
                  // Check if any entry matches the search query
                  final entries = log['entries'] as List<dynamic>? ?? [];
                  return entries.any((entry) {
                    final processName = entry['process']['name']?.toString().toLowerCase() ?? '';
                    final productName = entry['product']['name']?.toString().toLowerCase() ?? '';
                    return processName.contains(_searchQuery) || productName.contains(_searchQuery);
                  });
                }).toList();

                if (filteredLogs.isEmpty) {
                  return const Center(child: Text('No matching records found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final date = DateFormat('dd MMM yyyy').format(DateTime.parse(log['date']));
                    final totalHours = (log['totalHours'] as num).toDouble();
                    final isLocked = log['isLocked'] == true;
                    final entries = log['entries'] as List<dynamic>? ?? [];

                    // Further filter entries to only show matching ones if searching
                    final visibleEntries = _searchQuery.isEmpty 
                      ? entries 
                      : entries.where((entry) {
                          final processName = entry['process']['name']?.toString().toLowerCase() ?? '';
                          final productName = entry['product']['name']?.toString().toLowerCase() ?? '';
                          return processName.contains(_searchQuery) || productName.contains(_searchQuery);
                        }).toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isLocked ? AppTheme.success.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: index == 0 && _searchQuery.isEmpty, // Expand first item by default
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLocked ? AppTheme.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isLocked ? 'FINALIZED' : 'IN PROGRESS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isLocked ? AppTheme.success : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('Total Hours: ${totalHours.toStringAsFixed(1)} | Entries: ${entries.length}', style: const TextStyle(color: AppTheme.textMuted)),
                          children: visibleEntries.map((entry) {
                            final start = DateFormat('hh:mm a').format(DateTime.parse(entry['startTime']));
                            final end = DateFormat('hh:mm a').format(DateTime.parse(entry['endTime']));
                            final size = entry['size'] != null && entry['size'].toString().isNotEmpty ? entry['size'] : 'N/A';
                            final uom = entry['uom']?.toString().toUpperCase() ?? '';

                            return ListTile(
                              leading: const CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryColor,
                                child: Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                              title: Text('${entry['process']['name']} - ${entry['product']['name']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: Text('Time: $start to $end\nSJO: ${entry['sjoNumber'] ?? 'N/A'}\nSize: ${entry['size'] ?? 'N/A'} | Qty: ${entry['quantity'] ?? 'N/A'} ${entry['uom']?.toString().toUpperCase() ?? ''}\nRemarks: ${entry['remarks'] ?? 'None'}', style: const TextStyle(fontSize: 13)),
                              isThreeLine: true,
                              trailing: isLocked ? null : IconButton(
                                icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                                onPressed: () => _showEditEntryDialog(context, ref, entry),
                              ),
                            );
                          }).toList(),
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
      // Tab 2: Checklist History
      _buildChecklistHistoryTab(context, ref),
    ],
  ),
),
    );
  }

  Widget _buildChecklistHistoryTab(BuildContext context, WidgetRef ref) {
    final checklistHistoryAsync = ref.watch(checklistHistoryProvider);

    return checklistHistoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: AppTheme.textMuted),
                SizedBox(height: 16),
                Text('No checklist history found.', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final template = log['template'];
            final date = DateFormat('dd MMM yyyy').format(DateTime.parse(log['date']).toUtc());
            final completedAt = log['completedAt'] != null 
                ? DateFormat('hh:mm a').format(DateTime.parse(log['completedAt']).toLocal()) 
                : 'N/A';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.success.withOpacity(0.1),
                  child: const Icon(Icons.check_circle, color: AppTheme.success),
                ),
                title: Text(template['taskName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Due: $date | Done: $completedAt\nFrequency: ${template['frequency']}'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
