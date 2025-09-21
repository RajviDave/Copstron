import 'dart:io';
import 'package:cp_final/login.dart';
import 'package:cp_final/service/auth.dart';
import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  File? _imageFile;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _formChanged = false;
  int _bookCount = 0;
  int _readerCount = 0;
  double _rating = 0.0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Listen to changes in the name and bio fields
    _nameController.addListener(() {
      _onFormChanged();
    });
    _bioController.addListener(() {
      _onFormChanged();
    });
    
    // Set up listener for book count updates
    _setupBookCountListener();
  }
  
  void _setupBookCountListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final database = DatabaseService(uid: user.uid);
      database.getBookCountStream().listen((count) {
        if (mounted) {
          setState(() {
            _bookCount = count;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _bioController.removeListener(_onFormChanged);
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  Future<void> _onFormChanged() async {
    if (!mounted) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return;
      
      final data = doc.data() as Map<String, dynamic>?;
      final currentName = data?['name'] ?? '';
      final currentBio = data?['bio'] ?? '';
      
      if (mounted) {
        setState(() {
          _formChanged = _nameController.text != currentName ||
                        _bioController.text != currentBio;
        });
      }
    } catch (e) {
      print('Error checking form changes: $e');
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user document
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        setState(() {
          _nameController.text = data?['name'] ?? '';
          _bioController.text = data?['bio'] ?? '';
          _profileImageUrl = data?['profileImage'];
          // We'll get book count from the stream, so no need to set it here
          _readerCount = data?['readerCount'] ?? 0;
          _rating = (data?['rating'] ?? 0.0).toDouble();
        });
      }
      
      // Set up listener for user data changes
      _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>?;
          setState(() {
            _nameController.text = data?['name'] ?? '';
            _bioController.text = data?['bio'] ?? '';
            _profileImageUrl = data?['profileImage'];
            _readerCount = data?['readerCount'] ?? 0;
            _rating = (data?['rating'] ?? 0.0).toDouble();
          });
        }
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? selectedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (selectedImage != null) {
        setState(() {
          _imageFile = File(selectedImage.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_imageFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Upload the file to Firebase Storage
      final fileName = 'profile_${user.uid}${path.extension(_imageFile!.path)}';
      final ref = _storage.ref().child('profile_images/$fileName');
      await ref.putFile(_imageFile!);

      // Get the download URL
      final imageUrl = await ref.getDownloadURL();

      // Update user document with the new image URL
      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = imageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formChanged) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(user.uid);
      
      // Update user document
      batch.update(userRef, {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update author name in all books by this user
      final booksQuery = await _firestore
          .collection('books')
          .where('authorId', isEqualTo: user.uid)
          .get();
          
      for (var doc in booksQuery.docs) {
        batch.update(doc.reference, {
          'authorName': _nameController.text.trim(),
        });
      }
      
      // Commit the batch
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form changed state
        if (mounted) {
          setState(() {
            _formChanged = false;
          });
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email;
    if (email == null || email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email found for this account')),
        );
      }
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password reset email sent. Please check your inbox.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending password reset email: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete user account
        await user.delete();

        // Sign out
        await _auth.signOut();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF59AC77);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- Author Identity Section ---
                    _buildProfileCard(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (_profileImageUrl != null &&
                                                  _profileImageUrl!.isNotEmpty
                                              ? NetworkImage(_profileImageUrl!)
                                              : null)
                                          as ImageProvider?,
                                child:
                                    _imageFile == null &&
                                        _profileImageUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              GestureDetector(
                                onTap: _isLoading ? null : _pickImage,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: primaryColor,
                                  child: _isLoading && _imageFile != null
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildEditableTextField(
                            _nameController,
                            'Your Name',
                            isBold: true,
                          ),
                          const SizedBox(height: 8),
                          _buildEditableTextField(
                            _bioController,
                            'Your Bio',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          if (_formChanged)
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Save Changes'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Quick Stats Section ---
                    _buildProfileCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Books', '$_bookCount'),
                          _buildStatColumn('Readers', '$_readerCount'),
                          _buildStatColumn(
                            'Rating',
                            '${_rating.toStringAsFixed(1)} ★',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Account Management Section ---
                    _buildProfileCard(
                      child: Column(
                        children: [
                          _buildOptionTile(
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            onTap: _changePassword,
                          ),
                          const Divider(),
                          _buildOptionTile(
                            icon: Icons.delete_outline,
                            title: 'Delete Account',
                            onTap: _deleteAccount,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Logout Button ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _handleLogout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildProfileCard({required Widget child}) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }

  Widget _buildEditableTextField(
    TextEditingController controller,
    String label, {
    bool isBold = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isBold ? 22 : 16,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      trailing: isDestructive
          ? null
          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

