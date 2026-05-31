import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../helpers/prefs_helper.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _acaraList = [];
  String _userName = PrefsHelper.userName;
  String _role = PrefsHelper.userRole;
  bool _isDarkMode = PrefsHelper.isDarkMode;
  bool _isBalanceHidden = PrefsHelper.isBalanceHidden;

  @override
  void initState() {
    super.initState();
    _refreshAcaraList();
  }

  void _refreshAcaraList() async {
    final data = await DatabaseHelper.instance.getSemuaAcara();
    setState(() {
      _acaraList = data;
    });
  }

  String formatRupiah(int number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  void _showDeleteConfirmationDialog(int idAcara, String namaAcara) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Konfirmasi Hapus',
            style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus acara "$namaAcara"? Semua data divisi, tugas, dan pengeluaran di dalamnya akan ikut terhapus permanen.',
            style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await DatabaseHelper.instance.deleteAcara(idAcara);
                _refreshAcaraList();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Acara "$namaAcara" berhasil dihapus'),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
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
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Buat Acara Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 24),
              TextField(
                controller: namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Acara',
                  prefixIcon: const Icon(Icons.event_note),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target Budget',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tanggalController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tanggal Pelaksanaan Acara',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
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
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    String nama = namaController.text.trim();
                    String rawBudget = budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');
                    String tanggal = tanggalController.text.trim();
                    
                    if (nama.isEmpty || rawBudget.isEmpty || tanggal.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Semua kolom harus diisi!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    await DatabaseHelper.instance.insertAcara({
                      'nama_acara': nama,
                      'tanggal_acara': tanggal,
                      'budget_total': int.parse(rawBudget),
                    });

                    _refreshAcaraList();
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Simpan Acara', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F7FC);
    final Color cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _buildCustomHeader(),
              Expanded(
                child: _acaraList.isEmpty 
                    ? Center(child: Text('Belum ada acara. Mari buat acara baru!', style: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.black54)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 100),
                        itemCount: _acaraList.length,
                        itemBuilder: (context, index) {
                          return _buildPremiumEventCard(_acaraList[index], cardColor, textColor);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _role == 'Ketuplak' 
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF10B981),
              onPressed: _showAddAcaraBottomSheet,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Buat Acara', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildCustomHeader() {
    final Color headerColor = _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF1E3A8A);

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, $_userName', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Dashboard $_role', style: const TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(_isBalanceHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white, size: 26),
                onPressed: () async {
                  bool newHidden = !_isBalanceHidden;
                  await PrefsHelper.setBalanceHidden(newHidden);
                  setState(() {
                    _isBalanceHidden = newHidden;
                  });
                },
              ),
              IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white, size: 26),
                onPressed: () async {
                  bool newMode = !_isDarkMode;
                  await PrefsHelper.setDarkMode(newMode);
                  setState(() {
                    _isDarkMode = newMode;
                  });
                },
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  String newRole = _role == 'Ketuplak' ? 'Anggota' : 'Ketuplak';
                  PrefsHelper.setUserRole(newRole);
                  setState(() { _role = newRole; });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Switched to $newRole mode'), duration: const Duration(seconds: 1)));
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: headerColor, size: 30),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPremiumEventCard(Map<String, dynamic> acara, Color cardBg, Color textCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.08), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(
                idAcara: acara['id'],
                namaAcara: acara['nama_acara'],
              ),
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
                  Text(
                    (acara['tanggal_acara'] as String?) ?? (acara['tanggal'] as String?) ?? '', 
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)
                  ),
                  if (_role == 'Ketuplak')
                    InkWell(
                      onTap: () {
                        _showDeleteConfirmationDialog(acara['id'], acara['nama_acara']);
                      },
                      child: const Icon(Icons.delete, color: Colors.redAccent),
                    )
                ],
              ),
              const SizedBox(height: 16),
              Text(acara['nama_acara'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textCol)),
              const SizedBox(height: 10),
              Text(
                _isBalanceHidden ? 'Rp ••••••••' : formatRupiah(acara['budget_total']), 
                style: const TextStyle(fontSize: 18, color: Color(0xFF10B981), fontWeight: FontWeight.w600)
              ),
            ],
          ),
        ),
      ),
    );
  }
}