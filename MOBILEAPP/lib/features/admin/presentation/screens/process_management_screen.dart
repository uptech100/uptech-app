import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/admin_providers.dart';
import '../../data/admin_repository_impl.dart';

class ProcessManagementScreen extends ConsumerStatefulWidget {
  const ProcessManagementScreen({super.key});

  @override
  ConsumerState<ProcessManagementScreen> createState() => _ProcessManagementScreenState();
}

class _ProcessManagementScreenState extends ConsumerState<ProcessManagementScreen> {
  void _showProcessDialog([Map<String, dynamic>? process]) {
    final isEditing = process != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: process?['name'] ?? '');
    String status = process?['status'] ?? 'Active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Process' : 'Add Process', style: const TextStyle(color: AppTheme.primaryColor)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Process Name'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                    ],
                    onChanged: (val) => setState(() => status = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final data = {'name': nameController.text, 'status': status};
                  try {
                    if (isEditing) {
                      await ref.read(adminRepositoryProvider).updateProcess(process['id'], data);
                    } else {
                      await ref.read(adminRepositoryProvider).createProcess(data);
                    }
                    if (!mounted) return;
                    Navigator.pop(context);
                    ref.invalidate(processesProvider);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProcess(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Process'),
        content: const Text('Are you sure you want to delete this process?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminRepositoryProvider).deleteProcess(id);
        ref.invalidate(processesProvider);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final processesAsync = ref.watch(processesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProcessDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: processesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
        data: (processes) {
          if (processes.isEmpty) {
            return const Center(child: Text('No processes found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: processes.length,
            itemBuilder: (context, index) {
              final proc = processes[index];
              final isActive = proc['status'] == 'Active';
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(proc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${proc['status']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                        onPressed: () => _showProcessDialog(proc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.danger),
                        onPressed: () => _deleteProcess(proc['id']),
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
