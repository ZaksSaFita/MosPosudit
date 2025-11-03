import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mosposudit_shared/services/user_service.dart';
import '../core/constants.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  
  const EditProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _resetEmailController = TextEditingController();
  
  Uint8List? _pictureBytes;
  Uint8List? _originalPictureBytes;
  File? _selectedFile;
  bool isLoading = false;
  String? error;
  int? userId;
  
  late TabController _tabController;
  
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  
  bool _isEmailVerifying = false;
  String? _emailVerificationCode;
  final _emailVerificationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final user = jsonDecode(userJson);
      setState(() {
        userId = user['id'];
        _firstNameController.text = user['firstName'] ?? '';
        _lastNameController.text = user['lastName'] ?? '';
        _usernameController.text = user['username'] ?? '';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phoneNumber'] ?? '';

        if (user['picture'] != null) {
          _pictureBytes = base64Decode(user['picture']);
          _originalPictureBytes = _pictureBytes;
        } else {
          _pictureBytes = null;
          _originalPictureBytes = null;
        }
      });
    }
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    
    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.single.path;
      
      if (filePath != null) {
        try {
          final file = File(filePath);
          final bytes = await file.readAsBytes();
          
          setState(() {
            _pictureBytes = bytes;
            _selectedFile = file;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Slika izabrana. Kliknite "Spremi izmjene" da sačuvate.'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška pri čitanju slike: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> uploadImage() async {
    if (userId == null || _selectedFile == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/User/$userId/upload-picture'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final userResp = jsonDecode(respStr);
        
        final userJson = prefs.getString('user');
        if (userJson != null) {
          final user = jsonDecode(userJson);
          user['picture'] = base64Encode(_pictureBytes!);
          await prefs.setString('user', jsonEncode(user));
        }
      } else {
        throw Exception('Greška pri uploadu slike: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Greška pri uploadu slike: $e');
    }
  }

  Future<void> deleteImage() async {
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/User/$userId/picture'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Greška pri brisanju slike: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Greška pri brisanju slike: $e');
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate() || userId == null) return;
    setState(() { isLoading = true; error = null; });
    try {
      final userService = UserService();
      final success = await userService.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
      );
      
      if (success) {
        if (_selectedFile != null) {
          await uploadImage();
        } else if (_pictureBytes == null && _originalPictureBytes != null) {
          await deleteImage();
        }
        

        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil uspješno ažuriran!'), backgroundColor: Colors.green),
          );
          widget.onProfileUpdated?.call();
          Navigator.of(context).pop();
        }
      } else {
        setState(() { error = 'Greška pri ažuriranju profila.'; });
      }
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Future<void> changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lozinke se ne poklapaju!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { isLoading = true; error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl/User/$userId/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
          'confirmPassword': _confirmPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lozinka uspješno promijenjena!'), backgroundColor: Colors.green),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        String userMessage = 'Greška pri promjeni lozinke.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData['errors'] != null) {
            final errors = errorData['errors'];
            if (errors is Map && errors['NewPassword'] != null) {
              userMessage = 'Nova lozinka nije dovoljno jaka. Mora imati najmanje 8 karaktera, veliko i malo slovo, broj i specijalni znak.';
            } else if (errors is Map && errors.values.isNotEmpty) {
              userMessage = errors.values.first is List && errors.values.first.isNotEmpty
                ? errors.values.first[0].toString()
                : userMessage;
            }
          } else if (errorData['title'] != null) {
            userMessage = errorData['title'].toString();
          }
        } catch (_) {}
        setState(() { error = userMessage; });
      }
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Future<void> resetPassword() async {
    if (_resetEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unesite email adresu!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { isLoading = true; error = null; });
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/User/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _resetEmailController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ako email postoji u sistemu, dobićete link za resetovanje lozinke.'),
            backgroundColor: Colors.green,
          ),
        );
        _resetEmailController.clear();
      } else {
        setState(() { error = 'Greška pri slanju email-a.'; });
      }
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resetEmailController.dispose();
    _emailVerificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uredi profil'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Osnovni podaci'),
            Tab(icon: Icon(Icons.lock), text: 'Promjena lozinke'),
            Tab(icon: Icon(Icons.email), text: 'Reset lozinke'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildChangePasswordTab(),
          _buildResetPasswordTab(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _pictureBytes != null
                        ? MemoryImage(_pictureBytes!)
                        : const NetworkImage('https://randomuser.me/api/portraits/lego/1.jpg'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, size: 22, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ime *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Unesite ime' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Prezime *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Unesite prezime' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Korisničko ime *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_circle),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Unesite korisničko ime' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Unesite email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Unesite validan email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Broj telefona',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            

            const SizedBox(height: 32),
            
            if (error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            
            if (error != null) const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () async {
                      await loadUser();
                      setState(() {
                        _selectedFile = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Izmjene poništene.')),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Poništi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : saveProfile,
                    icon: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(isLoading ? 'Spremanje...' : 'Spremi izmjene'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Promjena lozinke',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Za promjenu lozinke potrebno je unijeti trenutnu lozinku i zatim novu lozinku dva puta.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _currentPasswordController,
            decoration: InputDecoration(
              labelText: 'Trenutna lozinka *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_showCurrentPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
              ),
            ),
            obscureText: !_showCurrentPassword,
            validator: (value) => value == null || value.isEmpty ? 'Unesite trenutnu lozinku' : null,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              labelText: 'Nova lozinka *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_showNewPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
              ),
            ),
            obscureText: !_showNewPassword,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Unesite novu lozinku';
              if (value.length < 8) return 'Lozinka mora imati najmanje 8 karaktera';
              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(value)) {
                return 'Lozinka mora sadržati veliko slovo, malo slovo, broj i specijalni karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Potvrdi novu lozinku *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
            ),
            obscureText: !_showConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Potvrdite novu lozinku';
              if (value != _newPasswordController.text) return 'Lozinke se ne poklapaju';
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          if (error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
            ),
          
          if (error != null) const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : changePassword,
              icon: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_reset),
              label: Text(isLoading ? 'Promjena...' : 'Promijeni lozinku'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Reset lozinke',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ako ste zaboravili lozinku, unesite svoju email adresu i dobićete link za resetovanje.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _resetEmailController,
            decoration: const InputDecoration(
              labelText: 'Email adresa *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'example@email.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Unesite email adresu';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Unesite validan email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          if (error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
            ),
          
          if (error != null) const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : resetPassword,
              icon: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(isLoading ? 'Slanje...' : 'Pošalji reset link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Napomena',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Reset link će biti poslan na vašu email adresu\n'
                  '• Link je validan 24 sata\n'
                  '• Ako ne vidite email, provjerite spam folder\n'
                  '• Za dodatnu pomoć kontaktirajte administratora',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 