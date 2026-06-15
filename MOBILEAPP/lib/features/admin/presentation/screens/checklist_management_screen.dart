import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../checklists/presentation/providers/checklist_providers.dart';
import '../../../checklists/data/checklist_repository_impl.dart';
import '../providers/admin_providers.dart';

class ChecklistManagementScreen extends ConsumerStatefulWidget {
  const ChecklistManagementScreen({super.key});

  @override
  ConsumerState<ChecklistManagementScreen> createState() => _ChecklistManagementScreenState();
}

class _ChecklistManagementScreenState extends ConsumerState<ChecklistManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _taskName = '';
  int? _selectedDepartmentId;
  int? _selectedUserId;
  String _selectedFrequency = 'Daily';
  int? _selectedFrequencyValue;
  bool _isSubmitting = false;

  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedDepartmentId != null && _selectedUserId != null) {
      _formKey.currentState!.save();
      setState(() => _isSubmitting = true);

      try {
        final repo = ref.read(checklistRepositoryProvider);
        await repo.createChecklistTemplate({
          'taskName': _taskName,
          'departmentId': _selectedDepartmentId,
          'userId': _selectedUserId,
          'frequency': _selectedFrequency,
          'frequencyValue': _selectedFrequencyValue,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist created successfully'), backgroundColor: AppTheme.success),
        );
        ref.invalidate(adminChecklistsProvider);
        _formKey.currentState!.reset();
        setState(() {
          _selectedUserId = null;
          _selectedDepartmentId = null;
          _selectedFrequency = 'Daily';
          _selectedFrequencyValue = null;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.warning),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(departmentsProvider);
    final usersAsync = ref.watch(usersProvider);
    final checklistsAsync = ref.watch(adminChecklistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Form
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create New Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Task Name', prefixIcon: Icon(Icons.task_alt)),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        onSaved: (value) => _taskName = value!,
                      ),
                      const SizedBox(height: 16),
                      deptsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, st) => Text('Error: $e'),
                        data: (depts) => DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Select Department', prefixIcon: Icon(Icons.business)),
                          value: _selectedDepartmentId,
                          items: depts.map<DropdownMenuItem<int>>((d) {
                            return DropdownMenuItem<int>(
                              value: d['id'],
                              child: Text(d['name']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedDepartmentId = val;
                              _selectedUserId = null; // reset user
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      usersAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, st) => Text('Error: $e'),
                        data: (users) {
                          // Filter users by selected department
                          final filteredUsers = users.where((u) => u['departmentId'] == _selectedDepartmentId && u['status'] == 'Active').toList();
                          return DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Select Active Worker', prefixIcon: Icon(Icons.person)),
                            value: _selectedUserId,
                            items: filteredUsers.map<DropdownMenuItem<int>>((u) {
                              return DropdownMenuItem<int>(
                                value: u['id'],
                                child: Text('${u['name']} (${u['employeeId']})'),
                              );
                            }).toList(),
                            onChanged: _selectedDepartmentId == null ? null : (val) {
                              setState(() => _selectedUserId = val);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Frequency', prefixIcon: Icon(Icons.schedule)),
                        value: _selectedFrequency,
                        items: ['Daily', 'Weekly', 'Monthly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedFrequency = val;
                              if (val == 'Weekly') {
                                _selectedFrequencyValue = 1; // Default to Monday
                              } else if (val == 'Monthly') {
                                _selectedFrequencyValue = 1; // Default to 1st
                              } else {
                                _selectedFrequencyValue = null;
                              }
                            });
                          }
                        },
                      ),
                      if (_selectedFrequency == 'Weekly') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Day of Week', prefixIcon: Icon(Icons.event)),
                          value: _selectedFrequencyValue,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Monday')),
                            DropdownMenuItem(value: 2, child: Text('Tuesday')),
                            DropdownMenuItem(value: 3, child: Text('Wednesday')),
                            DropdownMenuItem(value: 4, child: Text('Thursday')),
                            DropdownMenuItem(value: 5, child: Text('Friday')),
                            DropdownMenuItem(value: 6, child: Text('Saturday')),
                            DropdownMenuItem(value: 7, child: Text('Sunday')),
                          ],
                          onChanged: (val) => setState(() => _selectedFrequencyValue = val),
                        ),
                      ],
                      if (_selectedFrequency == 'Monthly') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Date of Month', prefixIcon: Icon(Icons.date_range)),
                          value: _selectedFrequencyValue,
                          items: List.generate(31, (index) {
                            final val = index + 1;
                            return DropdownMenuItem(value: val, child: Text('$val'));
                          }),
                          onChanged: (val) => setState(() => _selectedFrequencyValue = val),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add),
                          label: Text(_isSubmitting ? 'Creating...' : 'Create Checklist'),
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            const Text('Active Checklists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            checklistsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (checklists) {
                if (checklists.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No active checklists found.', style: TextStyle(color: AppTheme.textMuted)),
                  ));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: checklists.length,
                  itemBuilder: (context, index) {
                    final c = checklists[index];
                    String frequencyDisplay = c['frequency'];
                    if (c['frequency'] == 'Weekly' && c['frequencyValue'] != null) {
                      const days = ['-', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      frequencyDisplay = 'Weekly on ${days[c['frequencyValue']]}';
                    } else if (c['frequency'] == 'Monthly' && c['frequencyValue'] != null) {
                      frequencyDisplay = 'Monthly on ${c['frequencyValue']}';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.assignment, color: AppTheme.primaryColor),
                        ),
                        title: Text(c['taskName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${c['user']['name']} (${c['department']['name']})'),
                        trailing: Chip(
                          label: Text(frequencyDisplay, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          backgroundColor: AppTheme.warning,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
