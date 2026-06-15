import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/qc_providers.dart';
import '../../domain/models/qc_item.dart';

class QCDailyLogScreen extends ConsumerStatefulWidget {
  const QCDailyLogScreen({Key? key}) : super(key: key);

  @override
  _QCDailyLogScreenState createState() => _QCDailyLogScreenState();
}

class _QCDailyLogScreenState extends ConsumerState<QCDailyLogScreen> {
  DateTime _selectedDate = DateTime.now();
  
  String _selectedProcess = 'Finish Checking';
  final List<String> _processes = ['Finish Checking', 'In-Process Checking', 'Final Inspection'];
  
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _itemCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _uomController = TextEditingController(text: 'NOS');
  final TextEditingController _quantityController = TextEditingController();
  
  final List<Map<String, dynamic>> _entries = [];
  bool _isSubmitting = false;

  void _addEntry() {
    if (_itemCodeController.text.trim().isEmpty || _quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Item Code and Quantity')),
      );
      return;
    }

    final int? quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() {
      _entries.add({
        'process': _selectedProcess,
        'category': _categoryController.text.trim(),
        'itemCode': _itemCodeController.text.trim().toUpperCase(),
        'description': _descriptionController.text.trim(),
        'uom': _uomController.text.trim().toUpperCase(),
        'quantity': quantity,
      });
      // Reset form fields
      _itemCodeController.clear();
      _descriptionController.clear();
      _quantityController.clear();
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one entry')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(qcRepositoryProvider);
      
      final submitEntries = _entries.map((e) => {
        'process': e['process'],
        'category': e['category'],
        'itemCode': e['itemCode'],
        'description': e['description'],
        'uom': e['uom'],
        'quantity': e['quantity'],
      }).toList();

      await repository.submitQCReport(_selectedDate, submitEntries);
      
      // Invalidate history provider to refresh data
      ref.invalidate(qcReportsHistoryProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QC Report submitted successfully')),
        );
        Navigator.pop(context); // Go back or show success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showAddQCItemDialog(BuildContext context, List<String> existingCategories) async {
    final itemCodeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final uomCtrl = TextEditingController(text: 'NOS');
    String? newCategory;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Add New QC Item', style: TextStyle(color: Colors.black)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: newCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(color: Colors.black54),
                        ),
                        style: const TextStyle(color: Colors.black),
                        items: existingCategories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        )).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            newCategory = val;
                          });
                        },
                        validator: (val) => val == null ? 'Select a category' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: itemCodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Item Code',
                          labelStyle: TextStyle(color: Colors.black54),
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Colors.black54),
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: uomCtrl,
                        decoration: const InputDecoration(
                          labelText: 'UOM (e.g. NOS, PAIR)',
                          labelStyle: TextStyle(color: Colors.black54),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        final repo = ref.read(qcRepositoryProvider);
                        await repo.addQCItem(
                          itemCodeCtrl.text.trim(),
                          newCategory!,
                          descCtrl.text.trim(),
                          uomCtrl.text.trim(),
                        );
                        // Refresh items
                        ref.invalidate(qcItemsGroupedProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Item added successfully')),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _itemCodeController.dispose();
    _descriptionController.dispose();
    _uomController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupedItemsAsync = ref.watch(qcItemsGroupedProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('QC Daily Report'),
        elevation: 0,
      ),
      body: groupedItemsAsync.when(
        data: (groupedItems) {
          final categories = groupedItems.keys.toList()..sort();
          
          List<QCItem> categoryItems = [];
          if (_selectedCategory != null) {
            categoryItems = groupedItems[_selectedCategory] ?? [];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Picker
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                    title: Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.black54),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Form Area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add New Entry',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddQCItemDialog(context, categories),
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text('New Item'),
                            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Process Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: _selectedProcess,
                        decoration: const InputDecoration(
                          labelText: 'Process',
                        items: _processes.map((proc) => DropdownMenuItem(
                          value: proc,
                          child: Text(proc),
                        )).toList(),
                        onChanged: (val) {
                          setState(() {
                            if (val != null) _selectedProcess = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Category
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Particulars (Category)',
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      
                      // Item Code
                      TextFormField(
                        controller: _itemCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Item Code',
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      
                      // Row for UOM and Quantity
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _uomController,
                              decoration: const InputDecoration(
                                labelText: 'UOM',
                                labelStyle: TextStyle(color: Colors.black54),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                labelStyle: TextStyle(color: Colors.black54),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Add Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addEntry,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Entry', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Added Entries List
                if (_entries.isNotEmpty) ...[
                  const Text(
                    'Added Entries',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '[${entry['process']}] ${entry['itemCode']} - ${entry['quantity']} ${entry['uom']}',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${entry['category']} - ${entry['description']}',
                            style: const TextStyle(color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _removeEntry(index),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit QC Report',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ]
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error loading items: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
