import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/admin_providers.dart';
import '../../data/admin_repository_impl.dart';

class DepartmentManagementScreen extends ConsumerStatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  ConsumerState<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends ConsumerState<DepartmentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  String _status = 'Active';

  void _showDepartmentDialog([Map<String, dynamic>? dept]) {
    final isEditing = dept != null;
    if (isEditing) {
      _nameController.text = dept['name'] ?? '';
      _codeController.text = dept['departmentCode'] ?? '';
      _descController.text = dept['description'] ?? '';
      _status = dept['status'] ?? 'Active';
    } else {
      _nameController.clear();
      _codeController.clear();
      _descController.clear();
      _status = 'Active';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Department' : 'New Department'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Department Name *'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(labelText: 'Department Code'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setStateDialog(() => _status = v!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final data = {
                        'name': _nameController.text,
                        'departmentCode': _codeController.text,
                        'description': _descController.text,
                        'status': _status,
                      };
                      try {
                        if (isEditing) {
                          await ref.read(adminRepositoryProvider).updateDepartment(dept['id'].toString(), data);
                        } else {
                          await ref.read(adminRepositoryProvider).createDepartment(data);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          ref.invalidate(departmentsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEditing ? 'Department updated' : 'Department created'), backgroundColor: AppTheme.success),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger));
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteDepartment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this department?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminRepositoryProvider).deleteDepartment(id);
        ref.invalidate(departmentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department deleted'), backgroundColor: AppTheme.success));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDepartmentDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: deptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (depts) {
          if (depts.isEmpty) {
            return const Center(child: Text('No departments found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: depts.length,
            itemBuilder: (context, index) {
              final dept = depts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(dept['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Code: ${dept['departmentCode'] ?? 'N/A'} | Status: ${dept['status'] ?? 'Active'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showDepartmentDialog(dept),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.danger),
                        onPressed: () => _deleteDepartment(dept['id'].toString()),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
