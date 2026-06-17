import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../helpers/prefs_helper.dart';
import '../helpers/database_helper.dart';
import 'landing_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late String _currentRole;
  bool _isLoading = false;
  String? _profilePhotoPath;
  final ImagePicker _imagePicker = ImagePicker();
  
  late bool _isDarkMode; 

  @override
  void initState() {
    super.initState();
    _isDarkMode = PrefsHelper.isDarkMode; 
    _loadUserData();
    _loadUserRoleFromDatabase();
  }

  void _loadUserData() {
    _nameController = TextEditingController(text: PrefsHelper.userName);
    _currentRole = PrefsHelper.userRole;
    _profilePhotoPath = PrefsHelper.userProfilePhoto.isEmpty 
        ? null 
        : PrefsHelper.userProfilePhoto;
  }

  Future<void> _loadUserRoleFromDatabase() async {
    final username = PrefsHelper.userName;
    final hasCreatedEvent = await DatabaseHelper.instance.checkUserHasCreatedEvent(username);
    if (hasCreatedEvent) {
      await PrefsHelper.setUserRole('Ketuplak');
      if (mounted) {
        setState(() {
          _currentRole = 'Ketuplak';
        });
      }
    } else {
      if (PrefsHelper.userRole == 'Ketuplak') {
        await PrefsHelper.setUserRole('Anggota');
        if (mounted) {
          setState(() {
            _currentRole = 'Anggota';
          });
        }
      }
    }
  }

  Future<void> _saveUserProfile() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Nama tidak boleh kosong!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newName = _nameController.text;
      await PrefsHelper.setUserName(newName);

      final hasCreatedEvent = await DatabaseHelper.instance.checkUserHasCreatedEvent(newName);
      if (hasCreatedEvent) {
        await PrefsHelper.setUserRole('Ketuplak');
        _currentRole = 'Ketuplak';
      } else {
        await PrefsHelper.setUserRole('Anggota');
        _currentRole = 'Anggota';
      }
      
      await PrefsHelper.setUserName(_nameController.text);

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessSnackBar('Profil berhasil diperbarui!');
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal menyimpan profil: $e');
    }
  }

  Future<void> _deleteUserProfile() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Data Profil?',
          style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Data profil Anda akan dikembalikan ke state awal. Data acara tetap aman.',
          style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performDelete();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    try {
      await PrefsHelper.setUserName('Pengguna');
      await PrefsHelper.setUserRole('Anggota');
      await PrefsHelper.deleteUserProfilePhoto();

      if (mounted) {
        _showSuccessSnackBar('Data profil berhasil direset!');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus profil: $e');
    }
  }

  Future<void> _performLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar Aplikasi?',
          style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Anda akan keluar dari sesi saat ini. Apakah Anda yakin?',
          style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext); 
              
              await PrefsHelper.setCurrentUsername('');
              await PrefsHelper.setUserName('Pengguna');
              await PrefsHelper.setUserRole('Anggota');
              await PrefsHelper.deleteUserProfilePhoto();
              
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10B981), 
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await PrefsHelper.setUserProfilePhoto(pickedFile.path);
        setState(() {
          _profilePhotoPath = pickedFile.path;
        });
        _showSuccessSnackBar('Foto profil berhasil diperbarui!');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil foto dari galeri: $e');
    }
  }

  Future<void> _deleteProfilePhoto() async {
    try {
      await PrefsHelper.deleteUserProfilePhoto();
      setState(() {
        _profilePhotoPath = null;
      });
      _showSuccessSnackBar('Foto profil berhasil dihapus!');
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus foto profil: $e');
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final words = trimmed.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color scaffoldBg = _isDarkMode ? const Color(0xFF121212) : Colors.grey[50]!;
    final Color titleColor = _isDarkMode ? const Color(0xFF10B981) : const Color(0xFF1E3A8A);
    final Color iconColor = _isDarkMode ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        
        // Logika database saat user tekan tombol back HP
        final newName = _nameController.text;
        await PrefsHelper.setUserName(newName);
        final hasCreatedEvent = await DatabaseHelper.instance.checkUserHasCreatedEvent(newName);
        if (hasCreatedEvent) {
          await PrefsHelper.setUserRole('Ketuplak');
        } else {
          await PrefsHelper.setUserRole('Anggota');
        }
        
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SingleChildScrollView(
          child: Column(
            children: [
              /// ============== HEADER SECTION ==============
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _isDarkMode 
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
                      : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)], 
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () async {
                          // Logika database saat user tekan tombol back di UI
                          final newName = _nameController.text;
                          await PrefsHelper.setUserName(newName);
                          
                          final hasCreatedEvent = await DatabaseHelper.instance.checkUserHasCreatedEvent(newName);
                          if (hasCreatedEvent) {
                            await PrefsHelper.setUserRole('Ketuplak');
                          } else {
                            await PrefsHelper.setUserRole('Anggota');
                          }
                          
                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _profilePhotoPath != null && _profilePhotoPath!.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: FileImage(File(_profilePhotoPath!)),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Colors.amber[300]!, Colors.orange[400]!],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getInitials(_nameController.text),
                                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nameController.text.isEmpty ? 'Pengguna' : _nameController.text,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Workspace $_currentRole',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// ============== CONTENT SECTION ==============
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foto Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
                    const SizedBox(height: 16),
                    _buildProfilePhotoCard(),
                    const SizedBox(height: 32),

                    Text('Informasi Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
                    const SizedBox(height: 16),
                    _buildFormCard(
                      title: 'Nama Profil',
                      child: TextField(
                        controller: _nameController,
                        style: TextStyle(fontSize: 16, color: _isDarkMode ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama Anda',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.person, color: iconColor),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFormCard(
                      title: 'Jabatan/Status',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.work, color: iconColor),
                            const SizedBox(width: 12),
                            Text(
                              _currentRole,
                              style: TextStyle(fontSize: 16, color: _isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: _isLoading ? null : _saveUserProfile,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24, width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF6B6B), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _deleteUserProfile,
                        child: const Text('Hapus Data Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEF6B6B))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _performLogout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({required String title, required Widget child}) {
    final Color cardBg = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoCard() {
    final Color cardBg = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color iconColor = _isDarkMode ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    
    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), spreadRadius: 2, blurRadius: 6)],
                ),
                child: _profilePhotoPath != null && _profilePhotoPath!.isNotEmpty
                    ? CircleAvatar(backgroundImage: FileImage(File(_profilePhotoPath!)))
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: _isDarkMode 
                              ? [const Color(0xFF10B981), const Color(0xFF059669)] 
                              : [Colors.blue[300]!, Colors.blue[600]!],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_nameController.text),
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: iconColor, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _pickImageFromGallery,
                icon: Icon(Icons.add_photo_alternate, color: iconColor),
                label: Text('Pilih dari Galeri', style: TextStyle(color: iconColor, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            if (_profilePhotoPath != null && _profilePhotoPath!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF6B6B), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _deleteProfilePhoto,
                  icon: const Icon(Icons.delete, color: Color(0xFFEF6B6B)),
                  label: const Text('Hapus Foto', style: TextStyle(color: Color(0xFFEF6B6B), fontWeight: FontWeight.w600)),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDarkMode ? iconColor.withValues(alpha: 0.1) : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isDarkMode ? iconColor.withValues(alpha: 0.3) : Colors.blue[100]!, width: 1),
              ),
              child: Text(
                '💡 Tips: Gunakan foto profil yang jelas dan profesional untuk pengalaman terbaik.',
                style: TextStyle(fontSize: 12, color: iconColor, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}