import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/qc_providers.dart';

class QCHistoryScreen extends ConsumerStatefulWidget {
  const QCHistoryScreen({super.key});

  @override
  ConsumerState<QCHistoryScreen> createState() => _QCHistoryScreenState();
}

class _QCHistoryScreenState extends ConsumerState<QCHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(qcReportsHistoryProvider);

    return Column(
      children: [
        // Filter / Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Filter by Item Code or Category...',
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
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _selectedDate != null ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.calendar_month, color: _selectedDate != null ? AppTheme.primaryColor : Colors.grey),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    setState(() {
                      _selectedDate = date; // Allows null to clear date filter if they dismiss, or just use a clear button
                    });
                  },
                ),
              ),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () => setState(() => _selectedDate = null),
                ),
            ],
          ),
        ),

        // History List
        Expanded(
          child: historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(child: Text('No QC history found.'));
              }

              // Filter logs based on search query and date
              final filteredLogs = logs.where((log) {
                if (_selectedDate != null) {
                  if (log.date.year != _selectedDate!.year || 
                      log.date.month != _selectedDate!.month || 
                      log.date.day != _selectedDate!.day) {
                    return false;
                  }
                }
                
                if (_searchQuery.isEmpty) return true;
                
                return log.entries.any((entry) {
                  final code = entry.qcItem?.itemCode.toLowerCase() ?? '';
                  final cat = entry.qcItem?.category.toLowerCase() ?? '';
                  return code.contains(_searchQuery) || cat.contains(_searchQuery);
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
                  final date = DateFormat('dd MMM yyyy').format(log.date);
                  final entries = log.entries;

                  // Further filter entries to only show matching ones if searching
                  final visibleEntries = _searchQuery.isEmpty 
                    ? entries 
                    : entries.where((entry) {
                        final code = entry.qcItem?.itemCode.toLowerCase() ?? '';
                        final cat = entry.qcItem?.category.toLowerCase() ?? '';
                        return code.contains(_searchQuery) || cat.contains(_searchQuery);
                      }).toList();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0 && _searchQuery.isEmpty,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text('Entries: ${entries.length}', style: const TextStyle(color: AppTheme.textMuted)),
                      children: visibleEntries.map((entry) {
                        final item = entry.qcItem;
                        return ListTile(
                          leading: const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(Icons.check, color: Colors.white, size: 16),
                          ),
                          title: Text('${item?.itemCode ?? 'Unknown'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Qty: ${entry.quantity} ${entry.uom ?? item?.uom ?? ''} | Process: ${entry.process ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              if (entry.size != null && entry.size!.isNotEmpty)
                                Text('Size: ${entry.size}', style: const TextStyle(fontSize: 13)),
                              if (entry.sjoNumber != null && entry.sjoNumber!.isNotEmpty)
                                Text('SJO: ${entry.sjoNumber}', style: const TextStyle(fontSize: 13)),
                              if (entry.checkedByName != null && entry.checkedByName!.isNotEmpty)
                                Text('Inspector: ${entry.checkedByName}', style: const TextStyle(fontSize: 13)),
                              Text('${item?.description ?? ''}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          ),
                          isThreeLine: true,
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
