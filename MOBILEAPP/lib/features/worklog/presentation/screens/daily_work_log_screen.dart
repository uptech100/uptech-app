import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/screens/main_navigation_screen.dart';
import '../providers/worklog_providers.dart';
import '../../data/worklog_repository_impl.dart';

class DailyWorkLogScreen extends ConsumerStatefulWidget {
  const DailyWorkLogScreen({super.key});

  @override
  ConsumerState<DailyWorkLogScreen> createState() => _DailyWorkLogScreenState();
}

class _DailyWorkLogScreenState extends ConsumerState<DailyWorkLogScreen> {
  final _formKey = GlobalKey<FormState>();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedProcessId;
  String? _selectedProductId;
  final _sjoController = TextEditingController();
  final _sizeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _remarksController = TextEditingController();
  String _selectedUom = 'nos';

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final minDate = todayOnly.subtract(const Duration(days: 2));

    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedDateProvider),
      firstDate: DateTime(2020), // Allow clicking to test the popup logic
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final pickedOnly = DateTime(picked.year, picked.month, picked.day);
      
      if (pickedOnly.isAfter(todayOnly)) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Invalid Date Selection', style: TextStyle(color: AppTheme.danger)),
            content: const Text("You can only update today's or past 2 days' tasks. Future date tasks cannot be updated."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      } else if (pickedOnly.isBefore(minDate)) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Invalid Date Selection', style: TextStyle(color: AppTheme.danger)),
            content: const Text("You can only update tasks up to 2 days in the past."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      } else {
        // Valid date within past 2 days!
        ref.read(selectedDateProvider.notifier).state = pickedOnly;
      }
    }
  }

  void _addEntry(int logId) async {
    if (_formKey.currentState!.validate() && _startTime != null && _endTime != null) {
      final now = DateTime.now();
      final startDateTime = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
      final endDateTime = DateTime(now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);

      if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
        return;
      }

      final data = {
        'logId': logId,
        'startTime': startDateTime.toIso8601String(),
        'endTime': endDateTime.toIso8601String(),
        'processId': int.parse(_selectedProcessId!),
        'productId': int.parse(_selectedProductId!),
        'sjoNumber': _sjoController.text,
        'size': _sizeController.text,
        'quantity': _quantityController.text,
        'uom': _selectedUom,
        'remarks': _remarksController.text,
      };

      try {
        await ref.read(worklogRepositoryProvider).addWorkEntry(data);
        ref.invalidate(todayLogProvider);
        setState(() {
          _startTime = null;
          _endTime = null;
          _selectedProcessId = null;
          _selectedProductId = null;
          _sjoController.clear();
          _sizeController.clear();
          _quantityController.clear();
          _remarksController.clear();
          _selectedUom = 'nos';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry added successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all fields')));
    }
  }

  void _finalizeLog(int logId, double totalHours) async {
    if (totalHours < 10) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('10 Hour Warning', style: TextStyle(color: AppTheme.danger)),
          content: Text('Your 10 hr is not completed (Current: ${totalHours.toStringAsFixed(1)} hrs).\n\nDo you still want to finalize? You will not be able to update this later.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finalize Day'),
          content: const Text('Are you sure you want to finalize your log for today?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finalize')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      await ref.read(worklogRepositoryProvider).finalizeLog(logId);
      ref.invalidate(todayLogProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Day finalized successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayLogAsync = ref.watch(todayLogProvider);
    final optionsAsync = ref.watch(workerOptionsProvider);

    final selectedDate = ref.watch(selectedDateProvider);
    final isToday = selectedDate.year == DateTime.now().year && 
                    selectedDate.month == DateTime.now().month && 
                    selectedDate.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: Text(isToday ? 'Update Today Task' : 'Update Past Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              ref.read(bottomNavIndexProvider.notifier).state = 0;
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              ref.read(bottomNavIndexProvider.notifier).state = 3;
            },
            tooltip: 'View History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(todayLogProvider);
              ref.invalidate(workerOptionsProvider);
            },
          ),
        ],
      ),
      body: todayLogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
        data: (log) {
          final isLocked = log['isLocked'] == true;
          final totalHours = (log['totalHours'] as num).toDouble();
          final entries = log['entries'] as List<dynamic>;

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryColor.withOpacity(0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Date: ${DateFormat('dd MMM yyyy').format(DateTime.parse(log['date']).toUtc())}', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.calendar_month, size: 18, color: AppTheme.primaryColor),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Total Hours: ${totalHours.toStringAsFixed(1)} / 10.0', style: TextStyle(color: totalHours >= 10 ? Colors.green : AppTheme.danger, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (isLocked)
                      const Chip(label: Text('Locked', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
                    else
                      ElevatedButton(
                        onPressed: () => _finalizeLog(log['id'], totalHours),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
                        child: const Text('Finalize Day'),
                      ),
                  ],
                ),
              ),

              if (!isLocked) ...[
                // Input Form
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: optionsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Text(e.toString()),
                        data: (options) {
                          final processes = options['processes'] as List<dynamic>;
                          final products = options['products'] as List<dynamic>;

                          return Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _selectTime(context, true),
                                        icon: const Icon(Icons.access_time),
                                        label: Text(_startTime?.format(context) ?? 'Start Time'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _selectTime(context, false),
                                        icon: const Icon(Icons.access_time),
                                        label: Text(_endTime?.format(context) ?? 'End Time'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(labelText: 'Work Process'),
                                  value: _selectedProcessId,
                                  items: processes.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name']))).toList(),
                                  onChanged: (val) => setState(() => _selectedProcessId = val),
                                  validator: (val) => val == null ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(labelText: 'Product'),
                                  value: _selectedProductId,
                                  items: products.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name']))).toList(),
                                  onChanged: (val) => setState(() => _selectedProductId = val),
                                  validator: (val) => val == null ? 'Required' : null,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _sjoController,
                                        decoration: const InputDecoration(labelText: 'SJO Number'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _sizeController,
                                        decoration: const InputDecoration(labelText: 'Material Size'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _quantityController,
                                        decoration: const InputDecoration(labelText: 'Quantity'),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(labelText: 'UoM'),
                                        value: _selectedUom,
                                        items: ['nos', 'pair', 'set', 'kg', 'ltr']
                                            .map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase())))
                                            .toList(),
                                        onChanged: (val) => setState(() => _selectedUom = val!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _remarksController,
                                  decoration: const InputDecoration(labelText: 'Remarks (Optional)'),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _addEntry(log['id']),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Entry'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],

              // Entries List
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No entries added today.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final start = DateFormat('hh:mm a').format(DateTime.parse(entry['startTime']));
                          final end = DateFormat('hh:mm a').format(DateTime.parse(entry['endTime']));

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: AppTheme.primaryColor, child: Icon(Icons.check, color: Colors.white)),
                              title: Text('${entry['process']['name']} - ${entry['product']['name']}'),
                              subtitle: Text('Time: $start to $end\nSJO: ${entry['sjoNumber'] ?? 'N/A'}\nSize: ${entry['size'] ?? 'N/A'} | Qty: ${entry['quantity'] ?? 'N/A'} ${entry['uom']?.toString().toUpperCase() ?? ''}'),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
