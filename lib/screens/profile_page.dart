import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../helpers/prefs_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// READ: Membaca data pengguna dari SharedPreferences
  /// Fungsi ini dijalankan saat halaman dibuka untuk mengambil data profil yang tersimpan
  void _loadUserData() {
    _nameController = TextEditingController(text: PrefsHelper.userName);
    _currentRole = PrefsHelper.userRole;
    _profilePhotoPath = PrefsHelper.userProfilePhoto.isEmpty 
        ? null 
        : PrefsHelper.userProfilePhoto;
  }

  /// UPDATE: Menyimpan perubahan nama ke SharedPreferences
  /// Fungsi ini dipanggil ketika user menekan tombol "Simpan Perubahan"
  Future<void> _saveUserProfile() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Nama tidak boleh kosong!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simpan nama ke SharedPreferences
      await PrefsHelper.setUserName(_nameController.text);

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessSnackBar('Profil berhasil diperbarui!');
        
        // Kembali ke halaman sebelumnya agar perubahan langsung ter-update di home screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal menyimpan profil: $e');
    }
  }

  /// DELETE: Menghapus data profil dan mereset ke state awal
  /// Fungsi ini dipanggil ketika user menekan tombol "Hapus Data Profil"
  Future<void> _deleteUserProfile() async {
    // Tampilkan dialog konfirmasi
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Data Profil?',
          style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Data profil Anda akan dihapus dan dikembalikan ke state awal. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6B6B), // Warna merah soft
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

  /// Helper function untuk melakukan delete
  Future<void> _performDelete() async {
    try {
      // Reset nama ke default
      await PrefsHelper.setUserName('Pengguna');
      // Hapus foto profil
      await PrefsHelper.deleteUserProfilePhoto();

      if (mounted) {
        _showSuccessSnackBar('Data profil berhasil dihapus!');
        
        // Kembali ke halaman sebelumnya
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus profil: $e');
    }
  }

  /// Helper function untuk menampilkan SnackBar sukses
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.greenAccent[700],
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Helper function untuk menampilkan SnackBar error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// PICK IMAGE: Fungsi untuk memilih foto dari galeri
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
        _showSuccessSnackBar('Foto profil berhasil diperbarui dari galeri!');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil foto dari galeri: $e');
    }
  }



  /// DELETE PHOTO: Hapus foto profil yang tersimpan
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

  /// Helper function untuk mendapatkan inisial nama pengguna
  /// Guard: filter kata kosong agar tidak RangeError saat field dikosongkan
  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    // Filter hanya kata-kata yang tidak kosong
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// ============== HEADER SECTION (BLUE GRADIENT) ==============
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(top: 40, bottom: 40, left: 24, right: 24),
              child: Column(
                children: [
                  /// Avatar dengan Foto Profil atau Inisial
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
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
                                colors: [
                                  Colors.amber[300]!,
                                  Colors.orange[400]!,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(_nameController.text),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  /// Nama Pengguna
                  Text(
                    _nameController.text.isEmpty ? 'Pengguna' : _nameController.text,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  /// Badge Status (Role)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Workspace $_currentRole',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// ============== CONTENT SECTION (WHITE BACKGROUND) ==============
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ======== SECTION 1: FOTO PROFIL ========
                  const Text(
                    'Foto Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Card untuk Foto Profil
                  _buildProfilePhotoCard(),
                  const SizedBox(height: 32),

                  /// ======== SECTION 2: INFORMASI PROFIL ========
                  const Text(
                    'Informasi Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Form Card - Nama Pengguna
                  _buildFormCard(
                    title: 'Nama Profil',
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama Anda',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      onChanged: (value) {
                        // Trigger rebuild untuk update avatar inisial
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Form Card - Jabatan/Status (Display Only - tidak dropdown)
                  _buildFormCard(
                    title: 'Jabatan/Status',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.work,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _currentRole,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// Tombol Simpan Perubahan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isLoading ? null : _saveUserProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Tombol Hapus Data Profil
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFEF6B6B),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _deleteUserProfile,
                      child: const Text(
                        'Hapus Data Profil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF6B6B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper Widget: Membangun Card untuk Form Input
  Widget _buildFormCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  /// Helper Widget: Card untuk Foto Profil dengan Fitur Upload/Hapus
  Widget _buildProfilePhotoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Avatar dengan Foto atau Inisial
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 6,
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
                            colors: [Colors.blue[300]!, Colors.blue[600]!],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_nameController.text),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            /// Tombol Aksi Foto Profil
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF3B82F6)),
                label: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// Tombol Hapus Foto (hanya tampil jika ada foto)
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
                  label: const Text(
                    'Hapus Foto',
                    style: TextStyle(color: Color(0xFFEF6B6B), fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!, width: 1),
              ),
              child: const Text(
                '💡 Tips: Gunakan foto profil yang jelas dan profesional untuk pengalaman terbaik.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3B82F6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
