import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/admin_providers.dart';
import '../../data/admin_repository_impl.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _empIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _selectedRoleId;
  String? _selectedDeptId;
  String _status = 'Active';

  void _showUserDialog([Map<String, dynamic>? user]) {
    final isEditing = user != null;
    if (isEditing) {
      _empIdController.text = user['employeeId'] ?? '';
      _nameController.text = user['name'] ?? '';
      _mobileController.text = user['mobile'] ?? '';
      _emailController.text = user['email'] ?? '';
      _selectedRoleId = user['roleId']?.toString();
      _selectedDeptId = user['departmentId']?.toString();
      _status = user['status'] ?? 'Active';
    } else {
      _empIdController.clear();
      _nameController.clear();
      _mobileController.clear();
      _emailController.clear();
      _passwordController.clear();
      _selectedRoleId = null;
      _selectedDeptId = null;
      _status = 'Active';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final rolesAsync = ref.watch(rolesProvider);
            final deptsAsync = ref.watch(departmentsProvider);

            return AlertDialog(
              title: Text(isEditing ? 'Edit User' : 'New User'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _empIdController,
                        decoration: const InputDecoration(labelText: 'Employee ID *'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name *'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(labelText: 'Mobile'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 16),
                      if (!isEditing) ...[
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password *'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setStateDialog(() => _status = v!),
                      ),
                      const SizedBox(height: 16),
                      rolesAsync.when(
                        data: (roles) => DropdownButtonFormField<String>(
                          value: _selectedRoleId,
                          decoration: const InputDecoration(labelText: 'Role *'),
                          items: roles.map((r) => DropdownMenuItem(value: r['id'].toString(), child: Text(r['name']))).toList(),
                          onChanged: (v) => setStateDialog(() => _selectedRoleId = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, s) => const Text('Failed to load roles'),
                      ),
                      const SizedBox(height: 16),
                      deptsAsync.when(
                        data: (depts) => DropdownButtonFormField<String>(
                          value: _selectedDeptId,
                          decoration: const InputDecoration(labelText: 'Department *'),
                          items: depts.map((d) => DropdownMenuItem(value: d['id'].toString(), child: Text(d['name']))).toList(),
                          onChanged: (v) => setStateDialog(() => _selectedDeptId = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, s) => const Text('Failed to load depts'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final data = {
                        'employeeId': _empIdController.text,
                        'name': _nameController.text,
                        'mobile': _mobileController.text,
                        'email': _emailController.text,
                        'roleId': int.parse(_selectedRoleId!),
                        'departmentId': int.parse(_selectedDeptId!),
                        'status': _status,
                      };
                      if (!isEditing) {
                        data['password'] = _passwordController.text;
                      }

                      try {
                        if (isEditing) {
                          await ref.read(adminRepositoryProvider).updateUser(user['id'].toString(), data);
                        } else {
                          await ref.read(adminRepositoryProvider).createUser(data);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          ref.invalidate(usersProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEditing ? 'User updated' : 'User created'), backgroundColor: AppTheme.success),
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

  void _resetPassword(String id) {
    final pwdController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: pwdController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (pwdController.text.isEmpty) return;
              try {
                await ref.read(adminRepositoryProvider).resetUserPassword(id, pwdController.text);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully'), backgroundColor: AppTheme.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger));
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
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
        await ref.read(adminRepositoryProvider).deleteUser(id);
        ref.invalidate(usersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted'), backgroundColor: AppTheme.success));
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
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('No users found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(user['name'][0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor)),
                  ),
                  title: Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user['employeeId']} | ${user['role']['name']} | ${user['department']['name']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _showUserDialog(user);
                      if (value == 'reset') _resetPassword(user['id'].toString());
                      if (value == 'delete') _deleteUser(user['id'].toString());
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.danger))),
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
