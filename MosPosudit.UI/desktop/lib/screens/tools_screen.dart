import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mosposudit_shared/services/tool_service.dart';
import 'package:mosposudit_shared/services/utility_service.dart';
import 'package:mosposudit_shared/models/tool.dart';
import 'package:mosposudit_shared/models/category.dart';
import 'package:mosposudit_shared/widgets/tool_availability_dialog.dart';

class ToolsManagementPage extends StatefulWidget {
  const ToolsManagementPage({super.key});

  @override
  State<ToolsManagementPage> createState() => _ToolsManagementPageState();
}

class _ToolsManagementPageState extends State<ToolsManagementPage> {
  final ToolService _toolService = ToolService();
  List<ToolModel> _tools = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedCategoryId;

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
        _error = 'Greška: ${e.toString()}';
        _isLoading = false;
      });
      print('Error loading tools: $e');
      print('Stack trace: $stackTrace');
    }
  }

  List<ToolModel> get _filteredTools {
    // Filter by category if selected, otherwise show all
    if (_selectedCategoryId == null) return _tools;
    return _tools.where((tool) => tool.categoryId == _selectedCategoryId).toList();
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
          title: Text(tool == null ? 'Dodaj alat' : 'Uredi alat'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategorija *',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name ?? 'Nepoznato'),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => selectedCategoryId = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dailyRateController,
                  decoration: const InputDecoration(
                    labelText: 'Cijena po danu (KM) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Količina *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: depositAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Depozit (KM)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Dostupno'),
                  value: isAvailable,
                  onChanged: (value) => setDialogState(() => isAvailable = value),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
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
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Greška pri učitavanju slike: $e')),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: Text(selectedImageBase64 != null 
                      ? 'Slika odabrana' 
                      : tool?.imageBase64 != null 
                          ? 'Promijeni sliku' 
                          : 'Odaberi sliku'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naziv je obavezan')),
                  );
                  return;
                }
                if (selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategorija je obavezna')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Sačuvaj'),
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
        } else {
          await _toolService.update(tool.id, data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tool == null
                  ? 'Alat uspješno dodat'
                  : 'Alat uspješno ažuriran'),
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Greška: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteTool(ToolModel tool) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdi brisanje'),
        content: Text('Da li ste sigurni da želite da obrišete alat "${tool.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _toolService.delete(tool.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alat uspješno obrisan')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Greška: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tools',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                if (!_isLoading && _error == null)
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Total: ${_tools.length}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Search and Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tool...',
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
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ],
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
                              Text('Greška: $_error', style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Pokušaj ponovo'),
                              ),
                            ],
                          ),
                        )
                      : _filteredTools.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Nema dostupnih alata', style: TextStyle(color: Colors.grey, fontSize: 18)),
                                ],
                              ),
                            )
                          : ListView.separated(
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
                                  onCheckAvailability: () {
                                    ToolAvailabilityDialog.show(
                                      context,
                                      tool,
                                    );
                                  },
                                );
                              },
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
  final VoidCallback onCheckAvailability;

  const _ToolListCard({
    required this.tool,
    required this.index,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
    required this.onCheckAvailability,
  });


  Widget _buildToolImage() {
    // Priority: base64 > asset filename (generated from name) > default icon
    if (tool.imageBase64 != null && tool.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(tool.imageBase64!);
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

  // Mock average score (until we have reviews in the model)
  double get _averageScore => 4.2 + (tool.id % 3) * 0.3; // Temporary: 4.2, 4.5, or 3.8

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
                    tool.name ?? 'Nepoznat alat',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
                                  ? Icons.inventory_2 
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
                      // Score
                      Text(
                        '${_averageScore.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'score',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: onCheckAvailability,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text('Check Availability'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
