import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mosposudit_shared/services/category_service.dart';
import 'package:mosposudit_shared/services/utility_service.dart';
import 'package:mosposudit_shared/models/category.dart';
import 'package:intl/intl.dart';
import '../core/snackbar_helper.dart';

class CategoriesManagementPage extends StatefulWidget {
  const CategoriesManagementPage({super.key});

  @override
  State<CategoriesManagementPage> createState() => _CategoriesManagementPageState();
}

enum ViewMode { card, table }

class _CategoriesManagementPageState extends State<CategoriesManagementPage> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;
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
      final results = await _categoryService.fetchCategories();
      setState(() {
        _categories = results;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<CategoryModel> get _filteredCategories {
    var filtered = _categories;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((category) {
        final name = (category.name ?? '').toLowerCase();
        final description = (category.description ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }
    
    return filtered;
  }
  
  List<CategoryModel> get _paginatedCategories {
    if (_viewMode != ViewMode.table) {
      return _filteredCategories;
    }
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredCategories.sublist(
      startIndex,
      endIndex > _filteredCategories.length ? _filteredCategories.length : endIndex,
    );
  }
  
  int get _totalPages {
    if (_viewMode != ViewMode.table) return 1;
    return (_filteredCategories.length / _itemsPerPage).ceil();
  }


  Future<void> _showAddEditDialog({CategoryModel? category}) async {
    final nameController = TextEditingController(text: category?.name);
    final descriptionController = TextEditingController(text: category?.description);
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
                category == null ? Icons.add_circle_outline : Icons.edit_outlined,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                category == null ? 'Add Category' : 'Edit Category',
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
                          : category?.imageBase64 != null 
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
        };

        // Add image base64 if selected
        if (selectedImageBase64 != null) {
          data['imageBase64'] = selectedImageBase64;
        }

        if (category == null) {
          await _categoryService.create(data);
          SnackbarHelper.showSuccess(context, 'Category added successfully');
        } else {
          await _categoryService.update(category.id, data);
          SnackbarHelper.showSuccess(context, 'Category updated successfully');
        }
        _loadData();
      } catch (e) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
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
              'Are you sure you want to delete this category?',
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
                  Icon(Icons.category_outlined, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.name ?? 'Unknown Category',
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
        await _categoryService.delete(category.id);
        SnackbarHelper.showSuccess(context, 'Category deleted successfully');
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
                  'Category Management',
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
                      label: const Text('Add Category'),
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
                hintText: 'Search categories...',
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

            // Content
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
                      : _filteredCategories.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No categories match your search'
                                        : 'No categories available',
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
                                        itemCount: _filteredCategories.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                                        itemBuilder: (context, index) {
                                          final category = _filteredCategories[index];
                                          return _CategoryListCard(
                                            category: category,
                                            index: index,
                                            onEdit: () => _showAddEditDialog(category: category),
                                            onDelete: () => _deleteCategory(category),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: _CategoriesTableView(
                                        categories: _paginatedCategories,
                                        allCategories: _filteredCategories,
                                        currentPage: _currentPage,
                                        itemsPerPage: _itemsPerPage,
                                        totalPages: _totalPages,
                                        onPageChanged: (page) {
                                          setState(() {
                                            _currentPage = page;
                                          });
                                        },
                                        onEdit: (category) => _showAddEditDialog(category: category),
                                        onDelete: (category) => _deleteCategory(category),
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

class _CategoryListCard extends StatelessWidget {
  final CategoryModel category;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryListCard({
    required this.category,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildCategoryImage() {
    // Priority: base64 > asset filename (generated from name) > default icon
    if (category.imageBase64 != null && category.imageBase64!.isNotEmpty) {
      try {
        // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
        String base64Data = category.imageBase64!;
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',').last;
        }
        
        final bytes = base64Decode(base64Data);
        if (bytes.isEmpty) {
          return _defaultIcon();
        }
        
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _defaultIcon();
              },
            ),
          ),
        );
      } catch (e) {
        return _defaultIcon();
      }
    } else if (category.name != null && category.name!.isNotEmpty) {
      final fileName = UtilityService.generateImageFileName(category.name);
      if (fileName.isNotEmpty) {
        // Asset image from shared package
        final assetPath = 'packages/mosposudit_shared/assets/images/categories/$fileName';
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.category_outlined,
        size: 40,
        color: Colors.blue.shade700,
      ),
    );
  }

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
            // Category image/icon
            _buildCategoryImage(),
            const SizedBox(width: 20),
            // Category info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category name
                  Text(
                    category.name ?? 'Unknown Category',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  if (category.description != null && category.description!.isNotEmpty)
                    Text(
                      category.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'No description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
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

class _CategoriesTableView extends StatelessWidget {
  final List<CategoryModel> categories;
  final List<CategoryModel> allCategories;
  final int currentPage;
  final int itemsPerPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<CategoryModel> onEdit;
  final ValueChanged<CategoryModel> onDelete;

  const _CategoriesTableView({
    required this.categories,
    required this.allCategories,
    required this.currentPage,
    required this.itemsPerPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildCategoryImage(CategoryModel category) {
    // Priority: base64 > asset filename (generated from name) > default icon
    if (category.imageBase64 != null && category.imageBase64!.isNotEmpty) {
      try {
        // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
        String base64Data = category.imageBase64!;
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',').last;
        }
        
        final bytes = base64Decode(base64Data);
        if (bytes.isEmpty) {
          return _defaultIcon();
        }
        
        return Container(
          width: 40,
          height: 40,
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
    } else if (category.name != null && category.name!.isNotEmpty) {
      final fileName = UtilityService.generateImageFileName(category.name);
      if (fileName.isNotEmpty) {
        final assetPath = 'packages/mosposudit_shared/assets/images/categories/$fileName';
        return Container(
          width: 40,
          height: 40,
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.category_outlined,
        size: 20,
        color: Colors.blue.shade700,
      ),
    );
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
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Description',
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
                  rows: categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
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
                          Row(
                            children: [
                              _buildCategoryImage(category),
                              const SizedBox(width: 12),
                              Text(
                                category.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Tooltip(
                            message: category.description ?? '',
                            child: SizedBox(
                              width: 300,
                              child: Text(
                                category.description ?? 'No description',
                                style: TextStyle(
                                  color: category.description != null && category.description!.isNotEmpty
                                      ? Colors.black87
                                      : Colors.grey[400],
                                  fontStyle: category.description == null || category.description!.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => onEdit(category),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: BorderSide(color: Colors.blue),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => onDelete(category),
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
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
        // Pagination controls
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1
                      ? () => onPageChanged(currentPage - 1)
                      : null,
                  tooltip: 'Previous',
                ),
                const SizedBox(width: 16),
                Text(
                  'Page $currentPage of $totalPages (${allCategories.length} total)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                  tooltip: 'Next',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
