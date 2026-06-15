import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/task_providers.dart';
import '../../data/task_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AssignTaskScreen extends ConsumerStatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  ConsumerState<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends ConsumerState<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  String? _selectedUserId;
  String _selectedPriority = 'Normal';
  DateTime? _selectedDate;
  String _assignedBy = 'Loading...';
  bool _isSubmitting = false;

  final List<String> _priorities = ['Low', 'Normal', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('uptech_user');
    if (userStr != null) {
      try {
        final user = jsonDecode(userStr);
        setState(() {
          _assignedBy = user['name'] ?? 'Unknown User';
        });
      } catch (_) {}
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user to assign the delegation to.'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target date.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(taskRepositoryProvider); // We didn't expose repo directly in providers, wait, yes we did or we can read it.
      // Better to read remote directly or add a provider. Let's just read it using ref.read
      // Wait, taskRepositoryProvider is not imported! 
    } catch (e) {
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUsersAsync = ref.watch(activeUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Delegation'),
      ),
      body: activeUsersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (users) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delegation Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  const SizedBox(height: 16),
                  
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Delegation Title',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  
                  const Text('Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  const SizedBox(height: 16),

                  // Assigned By (Read Only)
                  TextFormField(
                    initialValue: _assignedBy,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Assigned By',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Assigned To Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Assign To',
                      prefixIcon: const Icon(Icons.person_add),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: _selectedUserId,
                    items: users.map<DropdownMenuItem<String>>((u) {
                      return DropdownMenuItem<String>(
                        value: u['id'].toString(),
                        child: Text('${u['name']} (${u['employeeId']})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedUserId = val;
                      });
                    },
                    validator: (val) => val == null ? 'Please select a user' : null,
                  ),
                  const SizedBox(height: 16),

                  // Priority Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: const Icon(Icons.flag),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: _selectedPriority,
                    items: _priorities.map<DropdownMenuItem<String>>((p) {
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPriority = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Target Date
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Target Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _selectedDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_selectedDate!),
                        style: TextStyle(fontSize: 16, color: _selectedDate == null ? Colors.grey.shade600 : AppTheme.textPrimary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_selectedUserId == null || _selectedDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                          return;
                        }
                        setState(() => _isSubmitting = true);
                        try {
                          // Read repo
                          final repo = ref.read(taskRepositoryProvider);
                          await repo.assignTask({
                            'title': _titleController.text.trim(),
                            'description': _descController.text.trim(),
                            'assignedToId': int.parse(_selectedUserId!),
                            'priority': _selectedPriority,
                            'dueDate': _selectedDate!.toIso8601String(),
                          });
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delegation Assigned Successfully!'), backgroundColor: AppTheme.success));
                          Navigator.pop(context);
                        } catch (e) {
                          setState(() => _isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
                        }
                      },
                      icon: _isSubmitting ? const SizedBox.shrink() : const Icon(Icons.send),
                      label: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Delegation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
