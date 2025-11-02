import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mosposudit_shared/services/user_service.dart';
import 'package:mosposudit_shared/models/user.dart';
import 'package:intl/intl.dart';
import '../core/snackbar_helper.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

enum ViewMode { card, table }

class _UsersManagementPageState extends State<UsersManagementPage> {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
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
      final results = await _userService.fetchNonAdminUsers();
      setState(() {
        _users = results;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<UserModel> get _filteredUsers {
    var filtered = _users;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final firstName = (user.firstName ?? '').toLowerCase();
        final lastName = (user.lastName ?? '').toLowerCase();
        final username = (user.username ?? '').toLowerCase();
        final email = (user.email ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return firstName.contains(query) || 
               lastName.contains(query) || 
               username.contains(query) ||
               email.contains(query);
      }).toList();
    }
    
    return filtered;
  }
  
  List<UserModel> get _paginatedUsers {
    if (_viewMode != ViewMode.table) {
      return _filteredUsers;
    }
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
    );
  }
  
  int get _totalPages {
    if (_viewMode != ViewMode.table) return 1;
    return (_filteredUsers.length / _itemsPerPage).ceil();
  }

  Future<void> _showAddEditDialog({UserModel? user}) async {
    final firstNameController = TextEditingController(text: user?.firstName);
    final lastNameController = TextEditingController(text: user?.lastName);
    final usernameController = TextEditingController(text: user?.username);
    final emailController = TextEditingController(text: user?.email);
    final phoneController = TextEditingController(text: user?.phoneNumber);
    final passwordController = TextEditingController();
    
    int selectedRoleId = user?.roleId ?? 2; // Default to User role (2), Admin is typically 1
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
                user == null ? Icons.add_circle_outline : Icons.edit_outlined,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                user == null ? 'Add User' : 'Edit User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name *',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name *',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username *',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedRoleId,
                          decoration: InputDecoration(
                            labelText: 'Role *',
                            prefixIcon: const Icon(Icons.group_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Admin')),
                            DropdownMenuItem(value: 2, child: Text('User')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedRoleId = value ?? 2;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (user == null)
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      obscureText: true,
                    )
                  else
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'New Password (leave empty to keep current)',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      obscureText: true,
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
                          : user?.pictureBase64 != null 
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
                if (firstNameController.text.trim().isEmpty) {
                  SnackbarHelper.showError(context, 'First name is required');
                  return;
                }
                if (lastNameController.text.trim().isEmpty) {
                  SnackbarHelper.showError(context, 'Last name is required');
                  return;
                }
                if (usernameController.text.trim().isEmpty) {
                  SnackbarHelper.showError(context, 'Username is required');
                  return;
                }
                if (emailController.text.trim().isEmpty) {
                  SnackbarHelper.showError(context, 'Email is required');
                  return;
                }
                if (user == null && passwordController.text.trim().isEmpty) {
                  SnackbarHelper.showError(context, 'Password is required for new users');
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
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'phoneNumber': phoneController.text.trim().isEmpty
              ? null
              : phoneController.text.trim(),
          'roleId': selectedRoleId,
        };

        // Add password if provided
        if (passwordController.text.trim().isNotEmpty) {
          data['password'] = passwordController.text.trim();
        }

        // Add image base64 if selected (backend expects base64 string, not byte[])
        if (selectedImageBase64 != null) {
          data['picture'] = selectedImageBase64;
        }

        if (user == null) {
          await _userService.create(data);
          SnackbarHelper.showSuccess(context, 'User added successfully');
        } else {
          await _userService.update(user.id, data);
          SnackbarHelper.showSuccess(context, 'User updated successfully');
        }
        _loadData();
      } catch (e) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
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
              'Are you sure you want to delete this user?',
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
                  Icon(Icons.person_outline, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty
                          ? user.username ?? 'Unknown User'
                          : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
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
        await _userService.deleteUser(user.id);
        SnackbarHelper.showSuccess(context, 'User deleted successfully');
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
                  'User Management',
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
                      label: const Text('Add User'),
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
                hintText: 'Search users...',
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
                      : _filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No users match your search'
                                        : 'No users available',
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
                                        itemCount: _filteredUsers.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                                        itemBuilder: (context, index) {
                                          final user = _filteredUsers[index];
                                          return _UserListCard(
                                            user: user,
                                            index: index,
                                            onEdit: () => _showAddEditDialog(user: user),
                                            onDelete: () => _deleteUser(user),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: _UsersTableView(
                                        users: _paginatedUsers,
                                        allUsers: _filteredUsers,
                                        currentPage: _currentPage,
                                        itemsPerPage: _itemsPerPage,
                                        totalPages: _totalPages,
                                        onPageChanged: (page) {
                                          setState(() {
                                            _currentPage = page;
                                          });
                                        },
                                        onEdit: (user) => _showAddEditDialog(user: user),
                                        onDelete: (user) => _deleteUser(user),
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

class _UserListCard extends StatelessWidget {
  final UserModel user;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserListCard({
    required this.user,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildUserImage() {
    if (user.pictureBase64 != null && user.pictureBase64!.isNotEmpty) {
      try {
        // Remove data URL prefix if present
        String base64Data = user.pictureBase64!;
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',').last;
        }
        
        final bytes = base64Decode(base64Data);
        if (bytes.isEmpty) {
          return _defaultAvatar();
        }
        
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: ClipOval(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _defaultAvatar();
              },
            ),
          ),
        );
      } catch (e) {
        return _defaultAvatar();
      }
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    var initials = ((user.firstName?.isNotEmpty == true ? user.firstName![0] : '') +
                     (user.lastName?.isNotEmpty == true ? user.lastName![0] : '')).toUpperCase();
    if (initials.isEmpty) {
      initials = (user.username?.isNotEmpty == true ? user.username![0] : 'U').toUpperCase();
    }
    
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.blue.shade100,
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
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
            // User image
            _buildUserImage(),
            const SizedBox(width: 20),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User name
                  Text(
                    '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty
                        ? user.username ?? 'Unknown User'
                        : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Username
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        user.username ?? 'No username',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.email ?? 'No email',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isActive ? Colors.green.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: user.isActive ? Colors.green.shade200 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 14,
                          color: user.isActive ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: user.isActive ? Colors.green.shade700 : Colors.grey.shade700,
                          ),
                        ),
                      ],
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

class _UsersTableView extends StatelessWidget {
  final List<UserModel> users;
  final List<UserModel> allUsers;
  final int currentPage;
  final int itemsPerPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<UserModel> onEdit;
  final ValueChanged<UserModel> onDelete;

  const _UsersTableView({
    required this.users,
    required this.allUsers,
    required this.currentPage,
    required this.itemsPerPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildUserImage(UserModel user) {
    if (user.pictureBase64 != null && user.pictureBase64!.isNotEmpty) {
      try {
        String base64Data = user.pictureBase64!;
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',').last;
        }
        
        final bytes = base64Decode(base64Data);
        if (bytes.isEmpty) {
          return _defaultAvatar(user);
        }
        
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: ClipOval(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _defaultAvatar(user),
            ),
          ),
        );
      } catch (e) {
        return _defaultAvatar(user);
      }
    }
    return _defaultAvatar(user);
  }

  Widget _defaultAvatar(UserModel user) {
    final initials = ((user.firstName?.isNotEmpty == true ? user.firstName![0] : '') +
                      (user.lastName?.isNotEmpty == true ? user.lastName![0] : '')).toUpperCase();
    final displayInitials = initials.isEmpty
        ? ((user.username?.isNotEmpty == true ? user.username![0] : 'U').toUpperCase())
        : initials;
    
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blue.shade100,
      child: Text(
        displayInitials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
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
                        'Username',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Role',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
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
                  rows: users.asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
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
                        DataCell(_buildUserImage(user)),
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty
                                  ? user.username ?? 'Unknown'
                                  : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Text(
                              user.username ?? 'N/A',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(
                              user.email ?? 'N/A',
                              overflow: TextOverflow.ellipsis,
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
                              user.roleName ?? 'User',
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
                              color: user.isActive ? Colors.green.shade50 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: user.isActive ? Colors.green.shade200 : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                                  size: 14,
                                  color: user.isActive ? Colors.green.shade700 : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: user.isActive ? Colors.green.shade700 : Colors.grey.shade700,
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
                              OutlinedButton.icon(
                                onPressed: () => onEdit(user),
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
                                onPressed: () => onDelete(user),
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
                  'Page $currentPage of $totalPages (${allUsers.length} total)',
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
