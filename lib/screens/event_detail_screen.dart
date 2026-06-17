import 'dart:io'; 
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // 🔥 Tambahan Image Picker
import 'package:file_picker/file_picker.dart';   // 🔥 Tambahan File Picker
import 'package:open_file/open_file.dart';       // 🔥 Tambahan Open File untuk baca PDF
import 'package:confetti/confetti.dart'; 
import '../helpers/database_helper.dart';
import '../helpers/prefs_helper.dart';
import '../widgets/interactive_date_strip.dart'; 


class EventDetailScreen extends StatefulWidget {
  final int idAcara;
  final String namaAcara;

  const EventDetailScreen({super.key, required this.idAcara, required this.namaAcara});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final Color navy = const Color(0xFF1E3A8A);
  final Color mint = const Color(0xFF10B981);
  
  String _status = 'Persiapan';
  String _tanggalAcara = '';
  String _namaAcaraReal = '';
  int _budgetAcara = 0;

  // 🔥 VARIABEL LOGIKA: Event-Based Role
  bool _isKetuplak = false; 

  // SINKRONISASI VALUE SHAREDPREFERENCES
  final bool _isBalanceHidden = PrefsHelper.isBalanceHidden;
  final bool _isDarkMode = PrefsHelper.isDarkMode;

  // 🔥 STATE MILIKMU: Animasi & Filter Tanggal
  late ConfettiController _confettiController;
  DateTime? _selectedFilterDate; 

  @override
  void initState() {
    super.initState();
    _namaAcaraReal = widget.namaAcara;
    _loadDataAcara();
    _checkKetuplakStatus();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkKetuplakStatus() async {
    final divs = await DatabaseHelper.instance.getDivisiByAcara(widget.idAcara);
    final currentUser = PrefsHelper.userName;
    bool ketuplakFound = false;
    
    for (var d in divs) {
      if (d['nama_divisi'].toString().startsWith('Inti (Ketuplak:') && d['nama_divisi'].toString().contains(currentUser)) {
        ketuplakFound = true;
        break;
      }
    }
    if (mounted) setState(() => _isKetuplak = ketuplakFound);
  }

  Future<void> _loadDataAcara() async {
    final acara = await DatabaseHelper.instance.getAcaraById(widget.idAcara);
    if (acara != null && mounted) {
      setState(() {
        _namaAcaraReal = acara['nama_acara'];
        _status = (acara['status'] as String?) ?? 'Persiapan';
        _tanggalAcara = (acara['tanggal_acara'] as String?) ?? (acara['tanggal'] as String?) ?? '';
        _budgetAcara = acara['budget_total'] as int;
      });
    }
  }

  String formatTanggal(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String formatRupiah(int number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Sedang Bertugas': return Colors.lightBlue.shade600;
      case 'Selesai': return Colors.green.shade600;
      case 'Belum Aktif': default: return Colors.grey.shade600;
    }
  }

  void _confirmDeleteDivisi(Map<String, dynamic> div) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Data', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "${div['nama_divisi']}"? Semua data terkait di dalamnya akan ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () async {
              await DatabaseHelper.instance.deleteDivisi(div['id']); 
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext); 
              if (mounted) {
                setState(() {}); 
                _checkKetuplakStatus(); 
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final usernameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: mint),
            const SizedBox(width: 8),
            const Text('Undang Anggota', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan username anggota yang ingin diundang ke proyek ini.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username Member',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              String invitedUser = usernameController.text.trim();
              if (invitedUser.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                String? invitedFullName = prefs.getString('simulasi_nama_$invitedUser');

                if (!mounted) return;

                if (invitedFullName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal! Username tersebut belum terdaftar di aplikasi.'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    )
                  );
                  return; 
                }

                if (invitedFullName == PrefsHelper.userName) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda tidak bisa mengundang diri sendiri!'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
                  return;
                }

                Navigator.pop(dialogCtx);
                
                await DatabaseHelper.instance.insertDivisi({
                  'id_acara': widget.idAcara,
                  'nama_divisi': 'Anggota (Pending): $invitedFullName', 
                  'alokasi_budget': 0,
                  'status': 'Belum Aktif'
                });
                
                if (mounted) setState(() {}); 

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Berhasil mengirim undangan ke $invitedFullName (@$invitedUser)!'),
                    backgroundColor: mint,
                    behavior: SnackBarBehavior.floating,
                  )
                );
              }
            },
            child: const Text('Undang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 🔥 FITUR DARI TEMANMU: MELIHAT BUKTI NOTA
  void _showBuktiDialog(String path) {
    final bool isPdf = path.toLowerCase().endsWith('.pdf');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.image, color: isPdf ? Colors.redAccent : mint),
            const SizedBox(width: 8),
            const Text('Bukti Nota', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E3A8A))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPdf)
              Column(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text('Bukti berupa dokumen PDF.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mint,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      await OpenFile.open(path);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
                    label: const Text('Buka Dokumen PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Text('Path:\n$path', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Gagal memuat gambar. File mungkin sudah dipindah atau dihapus.', textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F7FC);
    final Color cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color titleColor = _isDarkMode ? Colors.white : const Color(0xFF1E3A8A);

    // 🔥 FITUR DARI KAMU: STACK DENGAN CONFETTI WIDGET
    return Stack(
      children: [
        DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent, elevation: 0,
              leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: titleColor), onPressed: () => Navigator.pop(context)),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_namaAcaraReal, style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
                  if (_tanggalAcara.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📅 ', style: TextStyle(fontSize: 12, color: titleColor)),
                        Text('Pelaksanaan: ${formatTanggal(_tanggalAcara)}', style: TextStyle(color: _isDarkMode ? Colors.white70 : navy, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: mint.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: Text(_status, style: TextStyle(color: mint, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ),
                ),
                if (_isKetuplak)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: titleColor),
                    onSelected: (value) async {
                      if (value == 'edit_acara') {
                        _showEditAcaraDialog();
                      } else if (value == 'add_member') {
                        _showAddMemberDialog();
                      } else {
                        await DatabaseHelper.instance.updateAcaraStatus(widget.idAcara, value);
                        if (mounted) setState(() => _status = value);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit_acara', child: Text('✏️ Edit Info Acara')),
                      PopupMenuItem(value: 'add_member', child: Text('👤 Tambah Anggota Tim')), 
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'Persiapan', child: Text('Status: Persiapan')),
                      PopupMenuItem(value: 'Aktif', child: Text('Status: Aktif')),
                      PopupMenuItem(value: 'Selesai', child: Text('Status: Selesai')),
                    ],
                  ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), height: 54,
                  decoration: BoxDecoration(
                    color: cardColor, borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent, labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    indicator: BoxDecoration(color: _isDarkMode ? mint : navy, borderRadius: BorderRadius.circular(25)),
                    labelColor: Colors.white, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelColor: _isDarkMode ? Colors.white60 : Colors.blueGrey.shade600,
                    tabs: const [Tab(text: 'Tugas/Divisi'), Tab(text: 'RAB Acara'), Tab(text: 'Tim')],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildDivisiTab(),
                      _buildRABTab(),
                      _buildMemberTab(), 
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: _isKetuplak 
                ? FloatingActionButton.extended(
                    backgroundColor: mint, elevation: 4, onPressed: _showAddDivisiDialog, 
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Buat Divisi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                : null,
          ),
        ),

        // 🔥 LOGIKA CONFETTI TERPASANG SEMPURNA
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, 
            maxBlastForce: 5,       
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,  
            gravity: 0.1,           
            colors: const [
              Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 16, color: _isDarkMode ? Colors.white60 : Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // =================================================================
  // TAB 1: DIVISI & TUGAS (GABUNGAN FILTER TANGGAL & SWIPE-TO-ACTION)
  // =================================================================
  Widget _buildDivisiTab() {
    final Color bgCard = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color txtColor = _isDarkMode ? Colors.white : Colors.black87;
    final Color titleTxtColor = _isDarkMode ? Colors.white : navy;
    final Color innerContainerColor = _isDarkMode ? const Color(0xFF2A2A2A) : Colors.blueGrey.shade50;

    return Column(
      children: [
        // 🔥 FITUR DARI KAMU: WIDGET DATE STRIP DENGAN LOGIKA FILTER 🔥
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: InteractiveHorizontalDateStrip(
            isDarkMode: _isDarkMode,
            onDateSelected: (DateTime? selectedDate) {
              setState(() {
                _selectedFilterDate = selectedDate; 
              });
            },
          ),
        ),

        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseHelper.instance.getDivisiByAcara(widget.idAcara),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final divisiList = snapshot.data!.where((d) => 
                !d['nama_divisi'].toString().startsWith('Anggota:') && 
                !d['nama_divisi'].toString().startsWith('Anggota (Pending):') && 
                !d['nama_divisi'].toString().startsWith('Inti (Ketuplak:')
              ).toList();

              if (divisiList.isEmpty) return _buildPlaceholder('Belum ada divisi yang dibentuk.', Icons.groups_outlined);

              return ListView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                physics: const BouncingScrollPhysics(),
                itemCount: divisiList.length,
                itemBuilder: (context, index) {
                  final div = divisiList[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: bgCard, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: PageStorageKey('divisi_${div['id']}'),
                        collapsedIconColor: _isDarkMode ? Colors.white60 : Colors.grey,
                        iconColor: _isDarkMode ? mint : navy,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _statusColor((div['status'] as String?) ?? 'Belum Aktif').withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: Icon(Icons.workspaces_filled, color: _statusColor((div['status'] as String?) ?? 'Belum Aktif')),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(div['nama_divisi'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleTxtColor), overflow: TextOverflow.ellipsis)),
                            if (_isKetuplak)
                              IconButton(
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                onPressed: () => _confirmDeleteDivisi(div),
                              ),
                          ],
                        ),
                        subtitle: FutureBuilder<Map<String, int>>(
                          future: DatabaseHelper.instance.getTaskProgressByDivisi(div['id']),
                          builder: (context, progressSnapshot) {
                            final progress = progressSnapshot.data ?? {'total': 0, 'done': 0};
                            final total = progress['total']!;   
                            final done = progress['done']!;     
                            final percent = total == 0 ? 0 : ((done / total) * 100).round();  
                            final s = (div['status'] as String?) ?? 'Belum Aktif';

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Chip(
                                    visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    backgroundColor: _statusColor(s).withValues(alpha: 0.12),
                                    label: Text(s, style: TextStyle(color: _statusColor(s), fontSize: 11, fontWeight: FontWeight.w600)),
                                    side: BorderSide.none,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: total == 0 ? 0 : (done / total), backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300, valueColor: AlwaysStoppedAnimation<Color>(mint)))),
                                      const SizedBox(width: 10),
                                      Text('$percent%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: titleTxtColor)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('$done dari $total tugas selesai', style: TextStyle(fontSize: 11, color: _isDarkMode ? Colors.white60 : Colors.blueGrey.shade500, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            );
                          },
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            width: double.infinity,
                            decoration: BoxDecoration(color: innerContainerColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Daftar Tugas:', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey))),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: DatabaseHelper.instance.getTasksByDivisi(div['id']),
                                  builder: (context, taskSnapshot) {
                                    if (!taskSnapshot.hasData) return const SizedBox.shrink();
                                    
                                    // 🔥 FITUR DARI KAMU: LOGIKA FILTER TANGGAL 🔥
                                    List<Map<String, dynamic>> allTasks = taskSnapshot.data!;
                                    List<Map<String, dynamic>> filteredTasks = allTasks;

                                    if (_selectedFilterDate != null) {
                                      String filterStr = DateFormat('yyyy-MM-dd').format(_selectedFilterDate!);
                                      filteredTasks = allTasks.where((t) {
                                        if (t['deadline'] == null || t['deadline'].toString().isEmpty) return false;
                                        return t['deadline'] == filterStr;
                                      }).toList();
                                    }

                                    if (filteredTasks.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0), 
                                        child: Text(
                                          _selectedFilterDate == null ? 'Belum ada tugas.' : 'Tidak ada tugas berdeadline di tanggal ini.', 
                                          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
                                        )
                                      );
                                    }

                                    return Column(
                                      children: filteredTasks.map((task) {
                                        // 🔥 FITUR DARI TEMANMU: IMPLEMENTASI CUSTOM WIDGET SWIPE-TO-ACTION 🔥
                                        return SwipeToCompleteTaskWrapper(
                                          cardColor: innerContainerColor,
                                          onSwipeRight: () async {
                                            int isDone = task['is_done'] == 1 ? 0 : 1;
                                            await DatabaseHelper.instance.updateTaskStatus(task['id'], isDone);
                                            
                                            // 🔥 Pemicu Confetti milikmu digabung ke fungsi Swipe milik temanmu
                                            if (isDone == 1) {
                                              final progress = await DatabaseHelper.instance.getTaskProgressByDivisi(div['id']);
                                              if (progress['total']! > 0 && progress['done'] == progress['total']) {
                                                _confettiController.play(); 
                                              }
                                            }
                                            setState(() {}); 
                                          },
                                          onSwipeLeft: () async {
                                            if (!_isKetuplak) return false; // Hanya ketuplak yang bisa hapus
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (dialogCtx) => AlertDialog(
                                                title: const Text('Hapus Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
                                                content: Text('Hapus tugas "${task['nama_task']}"?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Batal')),
                                                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400), onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) { 
                                              await DatabaseHelper.instance.deleteTask(task['id']); 
                                              setState(() {}); 
                                              return true;
                                            }
                                            return false;
                                          },
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Checkbox(
                                              activeColor: mint, value: task['is_done'] == 1, 
                                              onChanged: (bool? value) async {
                                                int isDone = value! ? 1 : 0;
                                                await DatabaseHelper.instance.updateTaskStatus(task['id'], isDone);
                                                
                                                // Pemicu Confetti dari kotak checkbox
                                                if (isDone == 1) {
                                                  final progress = await DatabaseHelper.instance.getTaskProgressByDivisi(div['id']);
                                                  if (progress['total']! > 0 && progress['done'] == progress['total']) {
                                                    _confettiController.play(); 
                                                  }
                                                }
                                                setState(() {}); 
                                              },
                                            ),
                                            title: Text(task['nama_task'], style: TextStyle(decoration: task['is_done'] == 1 ? TextDecoration.lineThrough : null, color: task['is_done'] == 1 ? Colors.grey : txtColor, fontWeight: FontWeight.w600)),
                                            subtitle: task['deadline'] != null && (task['deadline'] as String).isNotEmpty
                                                ? Text('Deadline: ${task['deadline']}', style: TextStyle(fontSize: 11, color: _isDarkMode ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w500))
                                                : null,
                                            trailing: _isKetuplak ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), onPressed: () => _showEditTaskDialog(task)),
                                                IconButton(
                                                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                                  onPressed: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (dialogCtx) => AlertDialog(
                                                        title: const Text('Hapus Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
                                                        content: Text('Hapus tugas "${task['nama_task']}"?'),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Batal')),
                                                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400), onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) { await DatabaseHelper.instance.deleteTask(task['id']); setState(() {}); }
                                                  },
                                                ),
                                              ],
                                            ) : null,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                                if (_isKetuplak)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(onPressed: () => _showEditDivisiDialog(div), icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 16), label: const Text('Edit Divisi', style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold))),
                                      TextButton.icon(onPressed: () => _showAddTaskDialog(div['id'], div['nama_divisi']), icon: Icon(Icons.add_task, color: _isDarkMode ? mint : navy, size: 18), label: Text('Tambah Tugas', style: TextStyle(color: _isDarkMode ? mint : navy, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // =================================================================
  // TAB 2: RAB ACARA (GABUNGAN DONUT CHART, GROUPED BAR, DAN BUKTI NOTA)
  // =================================================================
  Widget _buildRABTab() {
    final Color bgCard = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color txtColor = _isDarkMode ? Colors.white : Colors.black87;
    final Color titleTxtColor = _isDarkMode ? Colors.white : const Color(0xFF1E3A8A);
    final Color innerContainerColor = _isDarkMode ? const Color(0xFF2A2A2A) : Colors.blueGrey.shade50;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getDivisiByAcara(widget.idAcara),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Ambil daftar divisi aktif (selain role fungsional tim)
        final divisiList = snapshot.data!.where((d) => 
          !d['nama_divisi'].toString().startsWith('Anggota:') && 
          !d['nama_divisi'].toString().startsWith('Anggota (Pending):') && 
          !d['nama_divisi'].toString().startsWith('Inti (Ketuplak:')
        ).toList();
        
        // 🔥 FITUR DARI KAMU: Pengecekan divisiList.isEmpty dipindahkan ke bawah agar Kartu Utama tetap ter-render
        // 🔥 FITUR DARI KAMU: Penggunaan Future.wait agar donat chart tidak nyangkut 0%
        return FutureBuilder<List<int>>(
          future: Future.wait(divisiList.map((div) => DatabaseHelper.instance.getTotalPengeluaranByDivisi(div['id']))),
          builder: (context, grandTotalSnapshot) {
            
            int totalPengeluaranNyata = 0;
            if (grandTotalSnapshot.hasData) {
              for (int pengeluaranDivisi in grandTotalSnapshot.data!) {
                totalPengeluaranNyata += pengeluaranDivisi;
              }
            }
            
            int totalAlokasi = 0;
            for (var div in divisiList) {
              totalAlokasi += (div['alokasi_budget'] as int);
            }
            int sisaBelumDialokasikan = _budgetAcara - totalAlokasi;

            return Column(
              children: [
                // 🟢 KARTU UTAMA RAB
                Container(
                  margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _isDarkMode ? [const Color(0xFF374151), const Color(0xFF1F2937)] : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]),
                    borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: navy.withValues(alpha: _isDarkMode ? 0.1 : 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10), 
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), 
                              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24)
                            ),
                            const SizedBox(height: 16),
                            const Text('Budget Utama Acara', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(_isBalanceHidden ? 'Rp ••••••••' : formatRupiah(_budgetAcara), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Dialokasikan', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text(_isBalanceHidden ? 'Rp ••••••••' : formatRupiah(totalAlokasi), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sisa Dana Acara', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text(
                                      _isBalanceHidden ? 'Rp ••••••••' : formatRupiah(sisaBelumDialokasikan), 
                                      style: TextStyle(color: sisaBelumDialokasikan < 0 ? Colors.redAccent.shade100 : Colors.greenAccent.shade200, fontSize: 13, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      BudgetDonutChart(
                        totalBudget: _budgetAcara,
                        terpakai: totalPengeluaranNyata, 
                        isDarkMode: _isDarkMode,
                      ),
                    ],
                  ),
                ),
                
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Text('Rincian Dana per Divisi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: titleTxtColor)))),
                
                // 🔥 FITUR DARI TEMANMU: IMPLEMENTASI CUSTOM DRAWING GroupedBarChartWidget
                if (divisiList.isNotEmpty)
                  GroupedBarChartWidget(divisiList: divisiList, isDarkMode: _isDarkMode),

                // 🎨 Jika divisi kosong, render placeholder. Jika ada, render list divisi.
                Expanded(
                  child: divisiList.isEmpty
                      ? _buildPlaceholder('Belum ada divisi/RAB yang dibuat.', Icons.account_balance_wallet_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          physics: const BouncingScrollPhysics(),
                          itemCount: divisiList.length,
                          itemBuilder: (context, index) {
                            final div = divisiList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.02), blurRadius: 8)]),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  collapsedIconColor: _isDarkMode ? Colors.white60 : Colors.grey, iconColor: _isDarkMode ? mint : navy,
                                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: mint.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.monetization_on_rounded, color: mint)),
                                  title: Text(div['nama_divisi'], style: TextStyle(fontWeight: FontWeight.bold, color: txtColor)),
                                  subtitle: FutureBuilder<int>(
                                    future: DatabaseHelper.instance.getTotalPengeluaranByDivisi(div['id']),
                                    builder: (context, totalSnapshot) {
                                      int totalTerpakaiDivisi = totalSnapshot.data ?? 0;
                                      return Text(_isBalanceHidden ? 'Terpakai: Rp ••••••••' : 'Terpakai: ${formatRupiah(totalTerpakaiDivisi)}', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white60 : Colors.blueGrey.shade600, fontWeight: FontWeight.w600));
                                    }
                                  ),
                                  trailing: FutureBuilder<int>(
                                    future: DatabaseHelper.instance.getTotalPengeluaranByDivisi(div['id']),
                                    builder: (context, sisaSnapshot) {
                                      final alokasi = (div['alokasi_budget'] as num).toInt();
                                      final terpakai = sisaSnapshot.data ?? 0;
                                      final sisa = alokasi - terpakai;
                                      final isOverBudget = alokasi > 0 && sisa < 0;
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(alokasi == 0 ? 'Alokasi' : 'Sisa Alokasi', style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                          Text(alokasi == 0 ? 'Tak Dibatasi' : (_isBalanceHidden ? 'Rp ••••••••' : formatRupiah(sisa)), style: TextStyle(color: alokasi == 0 ? Colors.blueGrey : (isOverBudget ? Colors.red.shade600 : (_isDarkMode ? mint : navy)), fontWeight: FontWeight.w900, fontSize: 13)),
                                        ],
                                      );
                                    },
                                  ),
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16), width: double.infinity,
                                      decoration: BoxDecoration(color: innerContainerColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Divider(),
                                          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Riwayat Pengeluaran:', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey))),
                                          FutureBuilder<List<Map<String, dynamic>>>(
                                            future: DatabaseHelper.instance.getPengeluaranByDivisi(div['id']),
                                            builder: (context, pengeluaranSnapshot) {
                                              if (!pengeluaranSnapshot.hasData) return const SizedBox.shrink();
                                              final pengeluaranList = pengeluaranSnapshot.data!;
                                              if (pengeluaranList.isEmpty) return const Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text('Belum ada pengeluaran.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));

                                              return Column(
                                                children: pengeluaranList.map((p) {
                                                  final int jumlah = p['jumlah'] as int;
                                                  final int nominal = (p['nominal'] as num).toInt();
                                                  final int total = jumlah * nominal; 

                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 8),
                                                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: _isDarkMode ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100)),
                                                    child: ListTile(
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                      title: Row(
                                                        children: [
                                                          Expanded(child: Text('[${p['tanggal']}] ${p['nama_barang']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: txtColor))),
                                                          // 🔥 FITUR DARI TEMANMU: TOMBOL LIHAT BUKTI NOTA
                                                          if (p['bukti_nota'] != null && p['bukti_nota'].toString().isNotEmpty) 
                                                            GestureDetector(
                                                              onTap: () => _showBuktiDialog(p['bukti_nota']),
                                                              child: Container(
                                                                margin: const EdgeInsets.only(left: 8.0),
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: mint.withValues(alpha: 0.15),
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(color: mint.withValues(alpha: 0.5)),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Icon(Icons.image_search_rounded, size: 14, color: mint),
                                                                    const SizedBox(width: 4),
                                                                    Text('Lihat Bukti', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: mint)),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      subtitle: Text(_isBalanceHidden ? '1 x Rp ••••••••' : '$jumlah x ${formatRupiah(nominal)}', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white60 : Colors.blueGrey.shade600, fontWeight: FontWeight.w600)),
                                                      trailing: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(_isBalanceHidden ? 'Rp ••••••••' : formatRupiah(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.redAccent)),
                                                          if (_isKetuplak)
                                                            PopupMenuButton<String>(
                                                              icon: const Icon(Icons.more_vert, size: 20),
                                                              onSelected: (value) async {
                                                                if (value == 'edit') {
                                                                  _showUpdatePengeluaranDialog(p, div['nama_divisi']);
                                                                } else if (value == 'delete') {
                                                                  final confirm = await showDialog<bool>(
                                                                    context: context, builder: (dialogCtx) => AlertDialog(
                                                                      title: const Text('Hapus Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                      content: Text('Hapus pengeluaran "${p['nama_barang']}"?'),
                                                                      actions: [
                                                                        TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Batal')),
                                                                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400), onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
                                                                      ],
                                                                    ),
                                                                  );
                                                                  if (confirm == true) { await DatabaseHelper.instance.deletePengeluaran(p['id']); if (mounted) setState(() {}); }
                                                                }
                                                              },
                                                              itemBuilder: (context) => const [PopupMenuItem(value: 'edit', child: Text('Edit Data')), PopupMenuItem(value: 'delete', child: Text('Void (Hapus)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))],
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                          if (_isKetuplak)
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton.icon(onPressed: () => _showAddPengeluaranDialog(div['id'], div['nama_divisi']), icon: Icon(Icons.add_shopping_cart, color: mint, size: 18), label: Text('Tambah Pengeluaran', style: TextStyle(color: mint, fontWeight: FontWeight.bold))),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // =================================================================
  // TAB 3: MEMBER / ANGGOTA TIM (DENGAN FOTO PROFIL / AVATAR)
  // =================================================================
  Widget _buildMemberTab() {
    final Color bgCard = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color txtColor = _isDarkMode ? Colors.white : Colors.black87;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getDivisiByAcara(widget.idAcara),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final divisiList = snapshot.data!.where((d) => 
          d['nama_divisi'].toString().startsWith('Anggota:') || 
          d['nama_divisi'].toString().startsWith('Anggota (Pending):') || 
          d['nama_divisi'].toString().startsWith('Inti (Ketuplak:')
        ).toList();

        return Column(
          children: [
            if (_isKetuplak)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mint.withValues(alpha: 0.15), elevation: 0, minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _showAddMemberDialog, icon: Icon(Icons.person_add_alt_1_rounded, color: mint),
                  label: Text('Undang Anggota Baru', style: TextStyle(color: mint, fontWeight: FontWeight.bold)),
                ),
              ),
            Expanded(
              child: divisiList.isEmpty 
                ? _buildPlaceholder('Belum ada anggota tim.', Icons.group_off_rounded)
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100, top: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: divisiList.length,
                    itemBuilder: (context, index) {
                      final div = divisiList[index];
                      String rawName = div['nama_divisi'];
                      
                      bool isKetuplak = rawName.contains('Ketuplak:');
                      bool isAnggota = rawName.startsWith('Anggota:');
                      bool isPending = rawName.startsWith('Anggota (Pending):'); 
                      
                      String displayName = rawName;
                      String roleName = 'Divisi Operasional';
                      Color iconColor = Colors.blueGrey;

                      if (isKetuplak) {
                        displayName = rawName.replaceAll('Inti (Ketuplak: ', '').replaceAll(')', '');
                        roleName = 'Ketua Pelaksana'; iconColor = Colors.orangeAccent;
                      } else if (isPending) {
                        displayName = rawName.replaceAll('Anggota (Pending): ', '');
                        roleName = 'Menunggu Konfirmasi...'; iconColor = Colors.orange;
                      } else if (isAnggota) {
                        displayName = rawName.replaceAll('Anggota: ', '');
                        roleName = 'Anggota Tim'; iconColor = _isDarkMode ? mint : navy;
                      }

                      // 🔥 LOGIKA DARI KAMU: RENDER FOTO PROFIL ATAU INISIAL NAMA
                      bool isCurrentUser = displayName == PrefsHelper.userName;
                      String? photoPath = isCurrentUser ? PrefsHelper.userProfilePhoto : null;
                      
                      Widget avatarWidget;
                      if (photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync()) {
                        // Jika foto ada (akun kamu)
                        avatarWidget = CircleAvatar(
                          radius: 22,
                          backgroundImage: FileImage(File(photoPath)),
                          backgroundColor: iconColor.withValues(alpha: 0.15),
                        );
                      } else {
                        // Jika tidak ada foto, buat inisial nama
                        String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
                        avatarWidget = CircleAvatar(
                          radius: 22,
                          backgroundColor: iconColor.withValues(alpha: 0.15),
                          child: Text(
                            initial, 
                            style: TextStyle(color: iconColor, fontWeight: FontWeight.w900, fontSize: 16)
                          ),
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.02), blurRadius: 8)]),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: avatarWidget, 
                          title: Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, color: txtColor)),
                          subtitle: Text(roleName, style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white60 : Colors.blueGrey.shade400)),
                          trailing: (_isKetuplak && !isKetuplak) 
                            ? IconButton(
                                icon: Icon((isAnggota || isPending) ? Icons.person_remove_rounded : Icons.delete_outline, color: Colors.red.shade400, size: 20),
                                onPressed: () => _confirmDeleteDivisi(div),
                              ) 
                            : (isKetuplak ? const Icon(Icons.verified_user_rounded, color: Colors.blue) : null),
                        ),
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }

  // =================================================================
  // DIALOG-DIALOG CRUD (DENGAN FILE PICKER & DARK MODE)
  // =================================================================
  void _showEditAcaraDialog() {
    final namaController = TextEditingController(text: _namaAcaraReal);
    final budgetController = TextEditingController(text: _budgetAcara.toString());
    final tanggalController = TextEditingController(text: _tanggalAcara);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Info Acara', style: TextStyle(fontWeight: FontWeight.w900, color: _isDarkMode ? mint : const Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController, 
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: 'Nama Acara', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetController, keyboardType: TextInputType.number, 
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: 'Total Budget Acara', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tanggalController, readOnly: true,
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: 'Tanggal', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), suffixIcon: const Icon(Icons.calendar_month), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onTap: () async {
                DateTime init = DateTime.now();
                try { init = DateTime.parse(tanggalController.text); } catch (_) {}
                final picked = await showDatePicker(context: dialogContext, initialDate: init, firstDate: DateTime(DateTime.now().year - 5), lastDate: DateTime(DateTime.now().year + 5));
                if (picked != null) tanggalController.text = picked.toIso8601String().split('T')[0];
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              String nama = namaController.text.trim();
              int budget = int.tryParse(budgetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              if (nama.isNotEmpty && budget > 0) {
                await DatabaseHelper.instance.updateAcara(widget.idAcara, {'nama_acara': nama, 'budget_total': budget, 'tanggal_acara': tanggalController.text});
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _loadDataAcara(); 
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditDivisiDialog(Map<String, dynamic> div) {
    final nameController = TextEditingController(text: div['nama_divisi']);
    final alokasiController = TextEditingController(text: div['alokasi_budget'].toString());
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Divisi', style: TextStyle(fontWeight: FontWeight.w900, color: _isDarkMode ? mint : const Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController, 
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: 'Nama Divisi', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alokasiController, keyboardType: TextInputType.number, 
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: 'Alokasi Dana', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              String nama = nameController.text.trim();
              int alokasi = int.tryParse(alokasiController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              if (nama.isNotEmpty) {
                final sukses = await DatabaseHelper.instance.updateDivisiWithValidasi(div['id'], widget.idAcara, nama, alokasi);
                if (!dialogContext.mounted) return;
                if (!sukses) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(backgroundColor: Colors.red.shade600, content: const Text('Gagal! Total alokasi divisi melebihi Budget.'))); return; }
                Navigator.pop(dialogContext);
                if (mounted) setState(() {});
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Map<String, dynamic> task) {
    final taskController = TextEditingController(text: task['nama_task']);
    final deadlineController = TextEditingController(text: task['deadline'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Tugas', style: TextStyle(fontWeight: FontWeight.w900, color: _isDarkMode ? mint : const Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: taskController, 
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: 'Nama Tugas', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: deadlineController, readOnly: true, 
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(hintText: 'Deadline', hintStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
                  )
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.calendar_month, color: _isDarkMode ? mint : navy),
                  onPressed: () async {
                    DateTime init = DateTime.now();
                    try { init = DateTime.parse(deadlineController.text); } catch (_) {}
                    final dd = await showDatePicker(context: dialogContext, initialDate: init, firstDate: DateTime(DateTime.now().year - 2), lastDate: DateTime(DateTime.now().year + 5));
                    if (dd != null) deadlineController.text = dd.toIso8601String().split('T')[0];
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (taskController.text.trim().isNotEmpty) {
                await DatabaseHelper.instance.updateTaskDetail(task['id'], taskController.text.trim(), deadlineController.text.isEmpty ? null : deadlineController.text);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (mounted) setState(() {});
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddDivisiDialog() {
    final nameController = TextEditingController();
    final alokasiController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Buat Divisi', style: TextStyle(fontWeight: FontWeight.w900, color: _isDarkMode ? mint : const Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController, 
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: 'Nama Divisi', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alokasiController, keyboardType: TextInputType.number, 
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: 'Alokasi Dana', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              String nama = nameController.text.trim();
              int alokasi = int.tryParse(alokasiController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              if (nama.isNotEmpty) {
                final sukses = await DatabaseHelper.instance.insertDivisiWithValidasi({'id_acara': widget.idAcara, 'nama_divisi': nama, 'alokasi_budget': alokasi});
                if (!dialogContext.mounted) return;
                if (!sukses) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(backgroundColor: Colors.red.shade600, content: const Text('Gagal! Total alokasi divisi melebihi Budget Utama Acara.'))); return; }
                Navigator.pop(dialogContext);
                if (mounted) { setState(() {}); _checkKetuplakStatus(); }
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(int idDivisi, String namaDivisi) {
    final taskController = TextEditingController(); 
    final deadlineController = TextEditingController(); 
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Tugas Baru $namaDivisi', style: TextStyle(fontWeight: FontWeight.w900, color: _isDarkMode ? mint : const Color(0xFF1E3A8A), fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: taskController, 
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(hintText: 'Misal: Beli Kertas HVS', hintStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: deadlineController, readOnly: true, 
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(hintText: 'Pilih deadline', hintStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
                  )
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.calendar_month, color: _isDarkMode ? mint : navy),
                  onPressed: () async {
                    final dd = await showDatePicker(context: dialogContext, initialDate: DateTime.now(), firstDate: DateTime(DateTime.now().year - 2), lastDate: DateTime(DateTime.now().year + 5));
                    if (dd != null) deadlineController.text = dd.toIso8601String().split('T')[0];
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (taskController.text.trim().isNotEmpty) {
                await DatabaseHelper.instance.insertTask({'id_divisi': idDivisi, 'nama_task': taskController.text.trim(), 'is_done': 0, 'status': 'Belum Selesai', 'deadline': deadlineController.text.isEmpty ? null : deadlineController.text});
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (mounted) setState(() {});
              }
            },
            child: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 🔥 FITUR DARI TEMANMU: TAMBAH PENGELUARAN DENGAN UPLOAD BUKTI (FILE PICKER)
  void _showAddPengeluaranDialog(int idDivisi, String namaDivisi) {
    final tanggalController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final namaBarangController = TextEditingController();
    final jumlahController = TextEditingController(text: '1');
    final nominalController = TextEditingController();
    
    String? selectedFilePath;
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Pengeluaran $namaDivisi', style: TextStyle(fontWeight: FontWeight.w900, color: _isDarkMode ? mint : const Color(0xFF1E3A8A), fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tanggalController, readOnly: true,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(labelText: 'Tanggal', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), suffixIcon: const Icon(Icons.calendar_month), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      onTap: () async {
                        final picked = await showDatePicker(context: dialogContext, initialDate: DateTime.now(), firstDate: DateTime(DateTime.now().year - 5), lastDate: DateTime(DateTime.now().year + 5));
                        if (picked != null) tanggalController.text = picked.toIso8601String().split('T')[0];
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: namaBarangController, 
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(labelText: 'Nama Barang', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(flex: 1, child: TextField(controller: jumlahController, keyboardType: TextInputType.number, style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: 'Jumlah', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: TextField(controller: nominalController, keyboardType: TextInputType.number, style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: 'Harga Satuan', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey.shade200),
                        borderRadius: BorderRadius.circular(12),
                        color: _isDarkMode ? Colors.black12 : Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bukti Kuitansi/Nota (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                tooltip: 'Ambil Foto',
                                icon: Icon(Icons.camera_alt_rounded, color: mint),
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                                  if (image != null) {
                                    setDialogState(() {
                                      selectedFilePath = image.path;
                                      selectedFileName = image.name;
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Dari Galeri',
                                icon: const Icon(Icons.photo_library_rounded, color: Colors.blueAccent),
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    setDialogState(() {
                                      selectedFilePath = image.path;
                                      selectedFileName = image.name;
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Unggah Berkas',
                                icon: const Icon(Icons.attach_file_rounded, color: Colors.orangeAccent),
                                onPressed: () async {
                                 FilePickerResult? result = await FilePicker.pickFiles(
                                   type: FileType.custom,
                                   allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                                 );
                                  if (result != null && result.files.single.path != null) {
                                    setDialogState(() {
                                      selectedFilePath = result.files.single.path;
                                      selectedFileName = result.files.single.name;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          if (selectedFileName != null) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Expanded(child: Text(selectedFileName!, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _isDarkMode ? Colors.white70 : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                GestureDetector(
                                  onTap: () => setDialogState(() { selectedFilePath = null; selectedFileName = null; }),
                                  child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                                )
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (namaBarangController.text.trim().isNotEmpty && nominalController.text.isNotEmpty && jumlahController.text.isNotEmpty) {
                      int jumlah = int.tryParse(jumlahController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
                      int nominal = int.tryParse(nominalController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                      final berhasil = await DatabaseHelper.instance.insertPengeluaranWithValidasi(
                        divisiId: idDivisi, 
                        tanggal: tanggalController.text, 
                        namaBarang: namaBarangController.text.trim(), 
                        jumlah: jumlah, 
                        nominal: nominal,
                        buktiNota: selectedFilePath,
                      );
                      if (!dialogContext.mounted) return;
                      if (!berhasil) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(backgroundColor: Colors.red.shade600, content: const Text('Gagal! Pengeluaran ini melebihi batas alokasi dana.'))); return; }
                      Navigator.pop(dialogContext);
                      if (mounted) setState(() {});
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔥 FITUR DARI TEMANMU: UPDATE PENGELUARAN DENGAN UPLOAD BUKTI (FILE PICKER)
  void _showUpdatePengeluaranDialog(Map<String, dynamic> pengeluaran, String namaDivisi) {
    final tanggalController = TextEditingController(text: pengeluaran['tanggal']);
    final namaBarangController = TextEditingController(text: pengeluaran['nama_barang']);
    final jumlahController = TextEditingController(text: pengeluaran['jumlah'].toString());
    final nominalController = TextEditingController(text: pengeluaran['nominal'].toString());
    
    String? selectedFilePath = pengeluaran['bukti_nota'];
    String? selectedFileName = selectedFilePath?.split('/').last;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Edit Pengeluaran', style: TextStyle(fontWeight: FontWeight.w900, color: _isDarkMode ? mint : const Color(0xFF1E3A8A), fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tanggalController, readOnly: true,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(labelText: 'Tanggal', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), suffixIcon: const Icon(Icons.calendar_month), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      onTap: () async {
                        DateTime init = DateTime.now();
                        try { init = DateTime.parse(tanggalController.text); } catch (_) {}
                        final picked = await showDatePicker(context: dialogContext, initialDate: init, firstDate: DateTime(DateTime.now().year - 5), lastDate: DateTime(DateTime.now().year + 5));
                        if (picked != null) tanggalController.text = picked.toIso8601String().split('T')[0];
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: namaBarangController, 
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(labelText: 'Nama Barang', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(flex: 1, child: TextField(controller: jumlahController, keyboardType: TextInputType.number, style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: 'Jumlah', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: TextField(controller: nominalController, keyboardType: TextInputType.number, style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: 'Harga Satuan', labelStyle: TextStyle(color: _isDarkMode ? Colors.white60 : Colors.blueGrey), prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey.shade200),
                        borderRadius: BorderRadius.circular(12),
                        color: _isDarkMode ? Colors.black12 : Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bukti Kuitansi/Nota (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                tooltip: 'Ambil Foto',
                                icon: Icon(Icons.camera_alt_rounded, color: mint),
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                                  if (image != null) {
                                    setDialogState(() {
                                      selectedFilePath = image.path;
                                      selectedFileName = image.name;
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Dari Galeri',
                                icon: const Icon(Icons.photo_library_rounded, color: Colors.blueAccent),
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    setDialogState(() {
                                      selectedFilePath = image.path;
                                      selectedFileName = image.name;
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Unggah Berkas',
                                icon: const Icon(Icons.attach_file_rounded, color: Colors.orangeAccent),
                                onPressed: () async {
                                 FilePickerResult? result = await FilePicker.pickFiles(
                                   type: FileType.custom,
                                   allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                                 );
                                  if (result != null && result.files.single.path != null) {
                                    setDialogState(() {
                                      selectedFilePath = result.files.single.path;
                                      selectedFileName = result.files.single.name;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          if (selectedFileName != null) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Expanded(child: Text(selectedFileName!, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _isDarkMode ? Colors.white70 : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                GestureDetector(
                                  onTap: () => setDialogState(() { selectedFilePath = null; selectedFileName = null; }),
                                  child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                                )
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (namaBarangController.text.trim().isNotEmpty && nominalController.text.isNotEmpty && jumlahController.text.isNotEmpty) {
                      int jumlah = int.tryParse(jumlahController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
                      int nominal = int.tryParse(nominalController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                      final berhasil = await DatabaseHelper.instance.updatePengeluaranWithValidasi(
                        id: pengeluaran['id'], 
                        divisiId: pengeluaran['divisi_id'], 
                        tanggal: tanggalController.text, 
                        namaBarang: namaBarangController.text.trim(), 
                        jumlah: jumlah, 
                        nominal: nominal,
                        buktiNota: selectedFilePath,
                      );
                      if (!dialogContext.mounted) return;
                      if (!berhasil) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(backgroundColor: Colors.red.shade600, content: const Text('Gagal! Pengeluaran ini melebihi batas alokasi dana.'))); return; }
                      Navigator.pop(dialogContext);
                      if (mounted) setState(() {});
                    }
                  },
                  child: const Text('Perbarui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
// =====================================================================
// 🔥 CUSTOM WIDGET 1: SwipeToCompleteTaskWrapper (Murni GestureDetector)
// =====================================================================
class SwipeToCompleteTaskWrapper extends StatefulWidget {
  final Widget child;
  final Future<bool> Function() onSwipeLeft; // Return true jika berhasil dihapus
  final VoidCallback onSwipeRight;
  final Color cardColor;

  const SwipeToCompleteTaskWrapper({
    super.key,
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.cardColor,
  });

  @override
  State<SwipeToCompleteTaskWrapper> createState() => _SwipeToCompleteTaskWrapperState();
}

class _SwipeToCompleteTaskWrapperState extends State<SwipeToCompleteTaskWrapper> {
  double _dx = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dx += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) async {
        if (_dx > 80) {
          // Geser ke Kanan -> Selesai
          widget.onSwipeRight();
          setState(() => _dx = 0);
        } else if (_dx < -80) {
          // Geser ke Kiri -> Hapus
          bool confirm = await widget.onSwipeLeft();
          if (!confirm) {
            setState(() => _dx = 0);
          }
        } else {
          // Reset jika geseran tanggung
          setState(() => _dx = 0);
        }
      },
      child: Stack(
        children: [
          // Background Color saat digeser
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: Colors.green.shade400,
                    child: const Icon(Icons.check_circle, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.shade400,
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Child Widget (ListTile) yang bergeser
          Transform.translate(
            offset: Offset(_dx, 0),
            child: Container(
              color: widget.cardColor, // Warna solid agar background tertutup
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// 🔥 CUSTOM DRAWING 2: GroupedBarChartWidget & CustomPainter
// =====================================================================
class GroupedBarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> divisiList;
  final bool isDarkMode;

  const GroupedBarChartWidget({super.key, required this.divisiList, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    // Ambil total pengeluaran setiap divisi
    return FutureBuilder<List<int>>(
      future: Future.wait(divisiList.map((d) => DatabaseHelper.instance.getTotalPengeluaranByDivisi(d['id']))),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
        
        List<Map<String, dynamic>> chartData = [];
        for (int i = 0; i < divisiList.length; i++) {
          chartData.add({
            'name': divisiList[i]['nama_divisi'],
            'allocated': divisiList[i]['alokasi_budget'],
            'spent': snapshot.data![i],
          });
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Komparasi Alokasi vs Realisasi', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.blueGrey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                height: 180, 
                width: double.infinity,
                child: CustomPaint(
                  painter: GroupedBarChartPainter(
                    data: chartData,
                    allocColor: const Color(0xFF1E3A8A), 
                    spentColor: const Color(0xFFF97316), 
                    isDarkMode: isDarkMode,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  const Text('Alokasi', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(width: 16),
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  const Text('Terpakai', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

class GroupedBarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color allocColor;
  final Color spentColor;
  final bool isDarkMode;

  GroupedBarChartPainter({required this.data, required this.allocColor, required this.spentColor, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double textSpace = 30.0;
    final double chartHeight = size.height - textSpace;

    // Cari nilai maksimum untuk skala
    double maxVal = 0;
    for (var d in data) {
      if (d['allocated'] > maxVal) maxVal = d['allocated'].toDouble();
      if (d['spent'] > maxVal) maxVal = d['spent'].toDouble();
    }
    if (maxVal == 0) maxVal = 1; 

    final paintAlloc = Paint()..color = allocColor..style = PaintingStyle.fill;
    final paintSpent = Paint()..color = spentColor..style = PaintingStyle.fill;
    final paintAxis = Paint()..color = isDarkMode ? Colors.white30 : Colors.black26..strokeWidth = 1.5;

    // Garis X
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), paintAxis);

    double slotWidth = size.width / data.length;
    double barWidth = slotWidth * 0.35; 
    double spacing = slotWidth * 0.1;   

    for (int i = 0; i < data.length; i++) {
      double centerX = (i * slotWidth) + (slotWidth / 2);
      
      double allocHeight = (data[i]['allocated'] / maxVal) * chartHeight;
      double spentHeight = (data[i]['spent'] / maxVal) * chartHeight;

      // Balok Kiri (Alokasi)
      double allocX = centerX - barWidth - (spacing / 2);
      RRect allocRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(allocX, chartHeight - allocHeight, barWidth, allocHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(allocRRect, paintAlloc);

      // Balok Kanan (Realisasi)
      double spentX = centerX + (spacing / 2);
      RRect spentRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(spentX, chartHeight - spentHeight, barWidth, spentHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(spentRRect, paintSpent);

      // Label Divisi di Sumbu X
      String labelName = data[i]['name'].toString();
      if (labelName.length > 8) {
        labelName = '${labelName.substring(0, 6)}..';
      }

      final textSpan = TextSpan(
        text: labelName,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.blueGrey.shade800,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(minWidth: 0, maxWidth: slotWidth);
      
      double textX = centerX - (textPainter.width / 2);
      double textY = chartHeight + 8;
      
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =====================================================================
// 🔥 CUSTOM DRAWING 3: BudgetDonutChart (Dari Kamu)
// =====================================================================
class BudgetDonutChart extends StatelessWidget {
  final int totalBudget;
  final int terpakai;
  final bool isDarkMode;

  const BudgetDonutChart({
    super.key,
    required this.totalBudget,
    required this.terpakai,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = totalBudget <= 0 ? 0 : (terpakai / totalBudget).clamp(0.0, 1.0);
    
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(110, 110),
            painter: _DonutChartPainter(
              percentage: percentage,
              isDarkMode: isDarkMode,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const Text(
                'Terpakai',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double percentage;
  final bool isDarkMode;

  _DonutChartPainter({required this.percentage, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width / 2, size.height / 2) - 10; 

    final Paint bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);

    final Paint progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF34D399)], 
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    const double startAngle = -pi / 2;
    final double sweepAngle = 2 * pi * percentage;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false, 
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.isDarkMode != isDarkMode;
  }
}