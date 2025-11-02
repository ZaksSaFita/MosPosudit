import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mosposudit_shared/services/tool_service.dart';
import 'package:mosposudit_shared/services/category_service.dart';
import 'package:mosposudit_shared/services/utility_service.dart';
import 'package:mosposudit_shared/models/tool.dart';
import 'package:mosposudit_shared/models/category.dart';
import 'package:intl/intl.dart';
import '../core/snackbar_helper.dart';

class ToolsManagementPage extends StatefulWidget {
  const ToolsManagementPage({super.key});

  @override
  State<ToolsManagementPage> createState() => _ToolsManagementPageState();
}

enum ViewMode { card, table }

class _ToolsManagementPageState extends State<ToolsManagementPage> {
  final ToolService _toolService = ToolService();
  final CategoryService _categoryService = CategoryService();
  List<ToolModel> _tools = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedCategoryId;
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.card;
  
  // Pagination for table view
  int _currentPage = 1;
  int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _toolService.fetchTools(),
        _toolService.fetchCategories(),
      ]);

      setState(() {
        _tools = results[0] as List<ToolModel>;
        _categories = results[1] as List<CategoryModel>;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<ToolModel> get _filteredTools {
    var filtered = _tools;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tool) {
        final name = (tool.name ?? '').toLowerCase();
        final description = (tool.description ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }
    
    return filtered;
  }
  
  List<ToolModel> get _paginatedTools {
    if (_viewMode != ViewMode.table) {
      return _filteredTools;
    }
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredTools.sublist(
      startIndex,
      endIndex > _filteredTools.length ? _filteredTools.length : endIndex,
    );
  }
  
  int get _totalPages {
    if (_viewMode != ViewMode.table) return 1;
    return (_filteredTools.length / _itemsPerPage).ceil();
  }

  Future<void> _showAddEditDialog({ToolModel? tool}) async {
    final nameController = TextEditingController(text: tool?.name);
    final descriptionController = TextEditingController(text: tool?.description);
    final dailyRateController = TextEditingController(text: tool?.dailyRate?.toString() ?? '0');
    final quantityController = TextEditingController(text: tool?.quantity?.toString() ?? '1');
    final depositAmountController = TextEditingController(text: tool?.depositAmount?.toString() ?? '0');
    
    int? selectedCategoryId = tool?.categoryId;
    bool isAvailable = tool?.isAvailable ?? true;
    String? selectedImageBase64;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                tool == null ? Icons.add_circle_outline : Icons.edit_outlined,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                tool == null ? 'Add Tool' : 'Edit Tool',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name *',
                      prefixIcon: const Icon(Icons.label_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: _categories.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name ?? 'Unknown'),
                          )).toList(),
                          onChanged: (value) => setDialogState(() => selectedCategoryId = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () async {
                          await _showAddCategoryDialog();
                          setDialogState(() {});
                        },
                        tooltip: 'Add Category',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dailyRateController,
                          decoration: InputDecoration(
                            labelText: 'Daily Rate (\$) *',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          decoration: InputDecoration(
                            labelText: 'Quantity *',
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: depositAmountController,
                    decoration: InputDecoration(
                      labelText: 'Deposit Amount (\$)',
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Available',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text('Tool is available for rent'),
                      value: isAvailable,
                      onChanged: (value) => setDialogState(() => isAvailable = value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                      );
                      if (result != null && result.files.single.path != null) {
                        try {
                          final file = File(result.files.single.path!);
                          final bytes = await file.readAsBytes();
                          final base64 = base64Encode(bytes);
                          setDialogState(() {
                            selectedImageBase64 = base64;
                          });
                          SnackbarHelper.showSuccess(context, 'Image selected');
                        } catch (e) {
                          SnackbarHelper.showError(context, 'Error loading image: $e');
                        }
                      }
                    },
                    icon: Icon(
                      selectedImageBase64 != null 
                          ? Icons.check_circle_outline 
                          : Icons.image_outlined,
                    ),
                    label: Text(
                      selectedImageBase64 != null 
                          ? 'Image Selected' 
                          : tool?.imageBase64 != null 
                              ? 'Change Image' 
                              : 'Select Image',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  SnackbarHelper.showError(context, 'Name is required');
                  return;
                }
                if (selectedCategoryId == null) {
                  SnackbarHelper.showError(context, 'Category is required');
                  return;
                }
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final data = {
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          'categoryId': selectedCategoryId!,
          'conditionId': 1, // Default condition
          'dailyRate': double.tryParse(dailyRateController.text) ?? 0,
          'quantity': int.tryParse(quantityController.text) ?? 1,
          'depositAmount': double.tryParse(depositAmountController.text) ?? 0,
          'isAvailable': isAvailable,
        };

        // Add image base64 if selected
        if (selectedImageBase64 != null) {
          data['imageBase64'] = selectedImageBase64;
        }

        if (tool == null) {
          await _toolService.create(data);
          SnackbarHelper.showSuccess(context, 'Tool added successfully');
        } else {
          await _toolService.update(tool.id, data);
          SnackbarHelper.showSuccess(context, 'Tool updated successfully');
        }
        _loadData();
      } catch (e) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                SnackbarHelper.showError(context, 'Category name is required');
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _categoryService.create({
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        });
        SnackbarHelper.showSuccess(context, 'Category added successfully');
        _loadData();
      } catch (e) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _showManageCategoriesDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Categories'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _showAddCategoryDialog();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: _categories.isEmpty
                    ? Center(
                        child: Text(
                          'No categories',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.category, color: Colors.blue.shade700),
                              ),
                              title: Text(
                                category.name ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: category.description != null && category.description!.isNotEmpty
                                  ? Text(category.description!)
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await _showEditCategoryDialog(category);
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await _showDeleteCategoryDialog(category);
                                    },
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCategoryDialog(CategoryModel category) async {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                SnackbarHelper.showError(context, 'Category name is required');
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _categoryService.update(category.id, {
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        });
        SnackbarHelper.showSuccess(context, 'Category updated successfully');
        _loadData();
      } catch (e) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _showDeleteCategoryDialog(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete category "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _categoryService.delete(category.id);
        SnackbarHelper.showSuccess(context, 'Category deleted successfully');
        _loadData();
      } catch (e) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _deleteTool(ToolModel tool) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Delete',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this tool?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.build, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tool.name ?? 'Unknown Tool',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _toolService.delete(tool.id);
        SnackbarHelper.showSuccess(context, 'Tool deleted successfully');
        _loadData();
      } catch (e) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tool Management',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // View mode toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _viewMode = ViewMode.card;
                                _currentPage = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _viewMode == ViewMode.card ? Colors.blue : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8),
                                ),
                              ),
                              child: Icon(
                                Icons.view_module,
                                color: _viewMode == ViewMode.card ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _viewMode = ViewMode.table;
                                _currentPage = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _viewMode == ViewMode.table ? Colors.blue : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8),
                                ),
                              ),
                              child: Icon(
                                Icons.table_rows,
                                color: _viewMode == ViewMode.table ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadData,
                      tooltip: 'Refresh',
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Tool'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1; // Reset pagination on search
                });
              },
              decoration: InputDecoration(
                hintText: 'Search tools...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),

            // Tools List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredTools.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No tools match your search'
                                        : 'No tools available',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                                  ),
                                ],
                              ),
                            )
                          : _viewMode == ViewMode.card
                              ? Column(
                                  children: [
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: _filteredTools.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                                        itemBuilder: (context, index) {
                                          final tool = _filteredTools[index];
                                          return _ToolListCard(
                                            tool: tool,
                                            index: index,
                                            categories: _categories,
                                            onEdit: () => _showAddEditDialog(tool: tool),
                                            onDelete: () => _deleteTool(tool),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: _ToolsTableView(
                                        tools: _paginatedTools,
                                        categories: _categories,
                                        allTools: _filteredTools,
                                        currentPage: _currentPage,
                                        itemsPerPage: _itemsPerPage,
                                        totalPages: _totalPages,
                                        onPageChanged: (page) {
                                          setState(() {
                                            _currentPage = page;
                                          });
                                        },
                                        onEdit: (tool) => _showAddEditDialog(tool: tool),
                                        onDelete: (tool) => _deleteTool(tool),
                                      ),
                                    ),
                                  ],
                                ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolListCard extends StatelessWidget {
  final ToolModel tool;
  final int index;
  final List<CategoryModel> categories;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ToolListCard({
    required this.tool,
    required this.index,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildToolImage() {
    // Priority: base64 > asset filename (generated from name) > default icon
    if (tool.imageBase64 != null && tool.imageBase64!.isNotEmpty) {
      try {
        // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
        String base64Data = tool.imageBase64!;
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',').last;
        }
        
        final bytes = base64Decode(base64Data);
        if (bytes.isEmpty) {
          return _defaultIcon();
        }
        
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _defaultIcon();
              },
            ),
          ),
        );
      } catch (e) {
        return _defaultIcon();
      }
    } else if (tool.name != null && tool.name!.isNotEmpty) {
      final fileName = UtilityService.generateImageFileName(tool.name);
      if (fileName.isNotEmpty) {
        // Asset image from shared package
        final assetPath = 'packages/mosposudit_shared/assets/images/tools/$fileName';
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _defaultIcon();
              },
            ),
          ),
        );
      }
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.build, size: 48, color: Colors.grey[400]),
    );
  }

  String get _categoryName {
    final category = categories.firstWhere(
      (c) => c.id == tool.categoryId,
      orElse: () => CategoryModel(id: 0, name: 'Unknown'),
    );
    return category.name ?? 'Unknown';
  }

  double get _averageScore => 4.2 + (tool.id % 3) * 0.3;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sequential number
            Container(
              width: 40,
              alignment: Alignment.topCenter,
              child: Text(
                '${(index + 1).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Tool image
            _buildToolImage(),
            const SizedBox(width: 20),
            // Tool info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tool name
                  Text(
                    tool.name ?? 'Unknown Tool',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.category_outlined, size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              _categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Daily rate
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '\$${tool.dailyRate?.toStringAsFixed(2) ?? '0.00'}/day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    tool.description ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Quantity and Score
                  Row(
                    children: [
                      // Quantity
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (tool.quantity ?? 0) > 0 
                              ? Colors.green.shade50 
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (tool.quantity ?? 0) > 0 
                                ? Colors.green.shade200 
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (tool.quantity ?? 0) > 0 
                                  ? Icons.inventory_2_outlined 
                                  : Icons.inventory_2_outlined,
                              size: 14,
                              color: (tool.quantity ?? 0) > 0 
                                  ? Colors.green.shade700 
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Quantity: ${tool.quantity ?? 0}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: (tool.quantity ?? 0) > 0 
                                    ? Colors.green.shade700 
                                    : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Available status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (tool.isAvailable ?? true)
                              ? Colors.green.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (tool.isAvailable ?? true)
                                ? Colors.green.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (tool.isAvailable ?? true) ? Icons.check_circle_outline : Icons.cancel_outlined,
                              size: 14,
                              color: (tool.isAvailable ?? true)
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (tool.isAvailable ?? true) ? 'Available' : 'Unavailable',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: (tool.isAvailable ?? true)
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            SizedBox(
              width: 140,
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolsTableView extends StatelessWidget {
  final List<ToolModel> tools;
  final List<CategoryModel> categories;
  final List<ToolModel> allTools;
  final int currentPage;
  final int itemsPerPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final Function(ToolModel) onEdit;
  final Function(ToolModel) onDelete;

  const _ToolsTableView({
    required this.tools,
    required this.categories,
    required this.allTools,
    required this.currentPage,
    required this.itemsPerPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onEdit,
    required this.onDelete,
  });

  String _getCategoryName(int? categoryId) {
    if (categoryId == null) return 'Unknown';
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel(id: 0, name: 'Unknown'),
    );
    return category.name ?? 'Unknown';
  }

  String _formatCurrency(num? value) {
    if (value == null) return '\$0.00';
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 60,
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 100,
                  columnSpacing: 24,
                  headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                  columns: const [
                    DataColumn(
                      label: Text(
                        '#',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Image',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Daily Rate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Quantity',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Deposit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Available',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: tools.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tool = entry.value;
                    final globalIndex = (currentPage - 1) * itemsPerPage + index;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '${globalIndex + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        DataCell(
                          _buildToolImage(tool),
                        ),
                        DataCell(
                          Tooltip(
                            message: tool.description ?? '',
                            child: SizedBox(
                              width: 200,
                              child: Text(
                                tool.name ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              _getCategoryName(tool.categoryId),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              _formatCurrency(tool.dailyRate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (tool.quantity ?? 0) > 0
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (tool.quantity ?? 0) > 0
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              '${tool.quantity ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: (tool.quantity ?? 0) > 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(tool.depositAmount),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (tool.isAvailable ?? true)
                                  ? Colors.green.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (tool.isAvailable ?? true)
                                    ? Colors.green.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (tool.isAvailable ?? true)
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 14,
                                  color: (tool.isAvailable ?? true)
                                      ? Colors.green.shade700
                                      : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (tool.isAvailable ?? true) ? 'Yes' : 'No',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (tool.isAvailable ?? true)
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                color: Colors.blue,
                                onPressed: () => onEdit(tool),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                color: Colors.red,
                                onPressed: () => onDelete(tool),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Pagination controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${(currentPage - 1) * itemsPerPage + 1} - ${currentPage * itemsPerPage > allTools.length ? allTools.length : currentPage * itemsPerPage} of ${allTools.length}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1
                      ? () => onPageChanged(currentPage - 1)
                      : null,
                  tooltip: 'Previous',
                ),
                ...List.generate(
                  totalPages > 10 ? 10 : totalPages,
                  (index) {
                    if (totalPages > 10) {
                      // Show first, last, and pages around current
                      int pageNum;
                      if (index < 3) {
                        pageNum = index + 1;
                      } else if (index >= 7) {
                        pageNum = totalPages - (9 - index);
                      } else {
                        pageNum = currentPage - 2 + (index - 3);
                        if (pageNum < 4) pageNum = 4;
                        if (pageNum > totalPages - 3) pageNum = totalPages - 3;
                      }
                      return _buildPageButton(pageNum);
                    } else {
                      return _buildPageButton(index + 1);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                  tooltip: 'Next',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => onPageChanged(page),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentPage ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentPage ? Colors.blue : Colors.grey[300]!,
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              color: isCurrentPage ? Colors.white : Colors.grey[700],
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolImage(ToolModel tool) {
    if (tool.imageBase64 != null && tool.imageBase64!.isNotEmpty) {
      try {
        // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
        String base64Data = tool.imageBase64!;
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',').last;
        }
        
        final bytes = base64Decode(base64Data);
        if (bytes.isEmpty) {
          return _defaultIcon();
        }
        
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _defaultIcon(),
            ),
          ),
        );
      } catch (e) {
        return _defaultIcon();
      }
    } else if (tool.name != null && tool.name!.isNotEmpty) {
      final fileName = UtilityService.generateImageFileName(tool.name);
      if (fileName.isNotEmpty) {
        final assetPath = 'packages/mosposudit_shared/assets/images/tools/$fileName';
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _defaultIcon(),
            ),
          ),
        );
      }
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.build, size: 24, color: Colors.grey[400]),
    );
  }
}
