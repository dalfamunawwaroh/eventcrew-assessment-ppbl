import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../helpers/prefs_helper.dart';
import 'event_detail_screen.dart';
import 'profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Palet Warna Premium
  final Color navyDark = const Color(0xFF0F172A);
  final Color navyPrimary = const Color(0xFF1E3A8A);
  final Color electricBlue = const Color(0xFF2563EB);
  final Color mintGreen = const Color(0xFF10B981);
  final Color softIce = const Color(0xFFEEF2F6);

  List<Map<String, dynamic>> _acaraList = [];
  late final String _userName; 
  String _role = PrefsHelper.userRole;
  bool _isDarkMode = PrefsHelper.isDarkMode;
  bool _isBalanceHidden = PrefsHelper.isBalanceHidden; // Deklarasi variabel SHARED PREFERENCES UNTUK MENYIMPAN STATUS BALANCE HIDDEN
  String? _profilePhotoPath = PrefsHelper.userProfilePhoto.isEmpty ? null : PrefsHelper.userProfilePhoto; // Foto profil pengguna

  int _grandTotalBudget = 0;

  @override
  void initState() {
    super.initState();
    _userName = PrefsHelper.userName;
    _refreshAcaraList();
  }

  void _refreshAcaraList() async {
    final data = await DatabaseHelper.instance.getSemuaAcara();
    
    int totalBudget = 0;
    for (var acara in data) {
      totalBudget += (acara['budget_total'] as int? ?? 0);
    }

    if (mounted) {
      setState(() {
        _acaraList = data;
        _grandTotalBudget = totalBudget; 
      });
    }
  }

  String formatRupiah(int number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  void _showDeleteConfirmationDialog(int idAcara, String namaAcara) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Hapus Acara?',
            style: TextStyle(color: _isDarkMode ? Colors.white : navyPrimary, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          content: Text(
            'Tindakan ini permanen. Semua data divisi, tugas, dan kuitansi di dalam "$namaAcara" akan dihapus bersih.',
            style: TextStyle(color: _isDarkMode ? Colors.blueGrey.shade300 : Colors.grey.shade600, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await DatabaseHelper.instance.deleteAcara(idAcara);
                _refreshAcaraList();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$namaAcara" berhasil dihapus'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddAcaraBottomSheet() {
    final namaController = TextEditingController();
    final budgetController = TextEditingController();
    final tanggalController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) { 
        final Color formBg = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
        final Color textCol = _isDarkMode ? Colors.white : navyDark;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 28,
            left: 28, right: 28, top: 32,
          ),
          decoration: BoxDecoration(
            color: formBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat Acara Baru ✨', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textCol, letterSpacing: -0.5)
              ),
              const SizedBox(height: 24),
              _buildFormTextField(controller: namaController, label: 'Nama Acara/Project', icon: Icons.event_note_rounded),
              const SizedBox(height: 16),
              _buildFormTextField(controller: budgetController, label: 'Target Anggaran (RAB)', icon: Icons.account_balance_wallet_rounded, isNumber: true),
              const SizedBox(height: 16),
              
              TextField(
                controller: tanggalController,
                readOnly: true,
                style: TextStyle(color: textCol, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Tanggal Pelaksanaan',
                  labelStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13),
                  prefixIcon: Icon(Icons.calendar_today_rounded, color: _isDarkMode ? mintGreen : navyPrimary),
                  filled: true,
                  fillColor: _isDarkMode ? navyDark : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: bottomSheetContext,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) {
                    tanggalController.text = picked.toIso8601String().split('T')[0];
                  }
                },
              ),
              const SizedBox(height: 32),
              
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: _isDarkMode ? [mintGreen, const Color(0xFF059669)] : [electricBlue, navyPrimary]),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, 
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    String nama = namaController.text.trim();
                    String rawBudget = budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');
                    String tanggal = tanggalController.text.trim();
                    
                    if (nama.isEmpty || rawBudget.isEmpty || tanggal.isEmpty) {
                      ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                        const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    await DatabaseHelper.instance.insertAcara({
                      'nama_acara': nama,
                      'tanggal_acara': tanggal,
                      'budget_total': int.parse(rawBudget),
                    });

                    // Set otomatis menjadi Ketuplak karena membuat acara
                    await PrefsHelper.setUserRole('Ketuplak');
                    if (mounted) {
                      setState(() {
                        _role = 'Ketuplak';
                      });
                    }

                    _refreshAcaraList();
                    if (bottomSheetContext.mounted) { 
                      Navigator.pop(bottomSheetContext);
                    }
                  },
                  child: const Text('Simpan & Luncurkan', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormTextField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: _isDarkMode ? Colors.white : navyDark, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13),
        prefixIcon: Icon(icon, color: _isDarkMode ? mintGreen : navyPrimary),
        filled: true,
        fillColor: _isDarkMode ? navyDark : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isDarkMode ? navyDark : softIce;
    final Color cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : navyDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(
            child: _acaraList.isEmpty 
                ? Center(child: Text('Belum ada acara aktif. Mari buat baru!', style: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600)))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _acaraList.length,
                    itemBuilder: (context, index) {
                      return _buildPremiumEventCard(_acaraList[index], cardColor, textColor);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: _isDarkMode ? [mintGreen, const Color(0xFF059669)] : [electricBlue, navyPrimary]),
          boxShadow: [
            BoxShadow(color: (_isDarkMode ? mintGreen : electricBlue).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          focusElevation: 0,
          highlightElevation: 0,
          onPressed: _showAddAcaraBottomSheet,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Buat Acara Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    final Color headerColor = _isDarkMode ? const Color(0xFF1E293B) : navyPrimary;

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🔥 FIX OVERFLOW: Nama panjang dibungkus Expanded agar aman dipotong pakai titik-titik (ellipsis)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $_userName 👋', 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text('Workspace $_role', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  _headerIconButton(
                    icon: _isBalanceHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    onTap: () async {
                      bool newHidden = !_isBalanceHidden;
                      await PrefsHelper.setBalanceHidden(newHidden);
                      setState(() => _isBalanceHidden = newHidden);
                    },
                  ),
                  const SizedBox(width: 8),
                  _headerIconButton(
                    icon: _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    onTap: () async {
                      bool newMode = !_isDarkMode;
                      await PrefsHelper.setDarkMode(newMode);
                      setState(() => _isDarkMode = newMode);
                    },
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      ).then((_) {
                        setState(() {
                          _userName = PrefsHelper.userName;
                          _role = PrefsHelper.userRole;
                          final photo = PrefsHelper.userProfilePhoto;
                          _profilePhotoPath = photo.isEmpty ? null : photo;
                        });
                      });
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: _profilePhotoPath != null
                          ? FileImage(File(_profilePhotoPath!)) as ImageProvider
                          : null,
                      child: _profilePhotoPath == null
                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 24)
                          : null,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: _isDarkMode ? [const Color(0xFF334155), const Color(0xFF1E293B)] : [electricBlue, const Color(0xFF1D4ED8)],
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 8))
              ]
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Kelola Anggaran Proyek', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        _isBalanceHidden ? 'Rp ••••••••' : formatRupiah(_grandTotalBudget),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _headerIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildPremiumEventCard(Map<String, dynamic> acara, Color cardBg, Color textCol) {
    String statusProject = (acara['status'] as String?) ?? 'Persiapan';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _isDarkMode ? Colors.blueGrey.shade800 : Colors.white, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.03), blurRadius: 14, offset: const Offset(0, 6))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(idAcara: acara['id'], namaAcara: acara['nama_acara']),
            ),
          ).then((_) => _refreshAcaraList());
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (statusProject == 'Selesai' ? mintGreen : electricBlue).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusProject,
                      style: TextStyle(color: statusProject == 'Selesai' ? mintGreen : electricBlue, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                    onPressed: () => _showDeleteConfirmationDialog(acara['id'], acara['nama_acara']),
                  )
                ],
              ),
              const SizedBox(height: 14),
              Text(
                acara['nama_acara'], 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textCol, letterSpacing: -0.5)
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alokasi RAB', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade300, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        _isBalanceHidden ? 'Rp ••••••••' : formatRupiah(acara['budget_total']), 
                        style: TextStyle(fontSize: 15, color: _isDarkMode ? mintGreen : navyPrimary, fontWeight: FontWeight.w900)
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 14, color: Colors.blueGrey.shade300),
                      const SizedBox(width: 4),
                      Text(
                        (acara['tanggal_acara'] as String?) ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade300, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}