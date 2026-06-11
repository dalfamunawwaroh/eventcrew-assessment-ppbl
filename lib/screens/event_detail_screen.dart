import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../helpers/prefs_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _namaAcaraReal = widget.namaAcara;
    _loadDataAcara();
    _checkKetuplakStatus();
  }

  // Cek apakah user yang login saat ini adalah pembuat acara ini
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

  // DIALOG TAMBAH MEMBER EVENT
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
            const Text('Masukkan username anggota yang ingin diundang ke proyek kepanitiaan ini.', style: TextStyle(fontSize: 13)),
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
                Navigator.pop(dialogCtx);
                
                await DatabaseHelper.instance.insertDivisi({
                  'id_acara': widget.idAcara,
                  'nama_divisi': 'Anggota: $invitedUser', 
                  'alokasi_budget': 0,
                  'status': 'Belum Aktif'
                });
                
                if (mounted) setState(() {}); 

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Berhasil menambahkan @$invitedUser ke dalam tim!'),
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

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F7FC);
    final Color cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color titleColor = _isDarkMode ? Colors.white : const Color(0xFF1E3A8A);

    return DefaultTabController(
      length: 3, // 🔥 FIX: Mengubah dari 2 tab menjadi 3 tab
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: titleColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _namaAcaraReal,
                style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
              ),
              if (_tanggalAcara.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('📅 ', style: TextStyle(fontSize: 12, color: titleColor)),
                    Text(
                      'Pelaksanaan: ${formatTanggal(_tanggalAcara)}',
                      style: TextStyle(color: _isDarkMode ? Colors.white70 : navy, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              height: 54,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4), // Mencegah teks kepanjangan
                indicator: BoxDecoration(
                  color: _isDarkMode ? mint : navy,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelColor: _isDarkMode ? Colors.white60 : Colors.blueGrey.shade600,
                // 🔥 FIX: 3 MENU TAB BAR
                tabs: const [
                  Tab(text: 'Tugas/Divisi'),
                  Tab(text: 'RAB Acara'),
                  Tab(text: 'Tim'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDivisiTab(),
                  _buildRABTab(),
                  _buildMemberTab(), // 🔥 FIX: Konten Tab Member dipanggil di sini
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _isKetuplak 
            ? FloatingActionButton.extended(
                backgroundColor: mint,
                elevation: 4,
                onPressed: _showAddDivisiDialog, 
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Buat Divisi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
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
  // TAB 1: DIVISI & TUGAS 
  // =================================================================
  Widget _buildDivisiTab() {
    final Color bgCard = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color txtColor = _isDarkMode ? Colors.white : Colors.black87;
    final Color titleTxtColor = _isDarkMode ? Colors.white : navy;
    final Color innerContainerColor = _isDarkMode ? const Color(0xFF2A2A2A) : Colors.blueGrey.shade50;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getDivisiByAcara(widget.idAcara),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Filter: Hanya tampilkan divisi murni, sembunyikan anggota dari tab ini agar tidak rancu
        final divisiList = snapshot.data!.where((d) => !d['nama_divisi'].toString().startsWith('Anggota:') && !d['nama_divisi'].toString().startsWith('Inti (Ketuplak:')).toList();

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
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
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
                    decoration: BoxDecoration(
                      color: _statusColor((div['status'] as String?) ?? 'Belum Aktif').withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.workspaces_filled, color: _statusColor((div['status'] as String?) ?? 'Belum Aktif')),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          div['nama_divisi'],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleTxtColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isKetuplak)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
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
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              backgroundColor: _statusColor(s).withValues(alpha: 0.12),
                              label: Text(s, style: TextStyle(color: _statusColor(s), fontSize: 11, fontWeight: FontWeight.w600)),
                              side: BorderSide.none,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: total == 0 ? 0 : (done / total),
                                      backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(mint),
                                    ),
                                  ),
                                ),
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
                      decoration: BoxDecoration(
                        color: innerContainerColor,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('Daftar Tugas:', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey)),
                          ),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: DatabaseHelper.instance.getTasksByDivisi(div['id']),
                            builder: (context, taskSnapshot) {
                              if (!taskSnapshot.hasData) return const SizedBox.shrink();
                              final tasks = taskSnapshot.data!;
                              if (tasks.isEmpty) return const Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text('Belum ada tugas.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));

                              return Column(
                                children: tasks.map((task) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Checkbox(
                                      activeColor: mint,
                                      value: task['is_done'] == 1, 
                                      onChanged: (bool? value) async {
                                        await DatabaseHelper.instance.updateTaskStatus(task['id'], value! ? 1 : 0);
                                        setState(() {}); 
                                      },
                                    ),
                                    title: Text(
                                      task['nama_task'],
                                      style: TextStyle(
                                        decoration: task['is_done'] == 1 ? TextDecoration.lineThrough : null, 
                                        color: task['is_done'] == 1 ? Colors.grey : txtColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: task['deadline'] != null && (task['deadline'] as String).isNotEmpty
                                        ? Text('Deadline: ${task['deadline']}', style: TextStyle(fontSize: 11, color: _isDarkMode ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w500))
                                        : null,
                                    trailing: _isKetuplak ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), 
                                          onPressed: () => _showEditTaskDialog(task), 
                                        ),
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
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                                                    onPressed: () => Navigator.pop(dialogCtx, true),
                                                    child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await DatabaseHelper.instance.deleteTask(task['id']); 
                                              setState(() {}); 
                                            }
                                          },
                                        ),
                                      ],
                                    ) : null,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          if (_isKetuplak)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showEditDivisiDialog(div),
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 16),
                                  label: const Text('Edit Divisi', style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showAddTaskDialog(div['id'], div['nama_divisi']),
                                  icon: Icon(Icons.add_task, color: _isDarkMode ? mint : navy, size: 18),
                                  label: Text('Tambah Tugas', style: TextStyle(color: _isDarkMode ? mint : navy, fontWeight: FontWeight.bold)),
                                ),
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
    );
  }

  // =================================================================
  // TAB 2: RAB ACARA
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
        
        // Di tab RAB, sembunyikan anggota yang tidak dikasih budget
        final divisiList = snapshot.data!.where((d) => !d['nama_divisi'].toString().startsWith('Anggota:') && !d['nama_divisi'].toString().startsWith('Inti (Ketuplak:')).toList();
        
        if (divisiList.isEmpty) return _buildPlaceholder('Belum ada divisi/RAB.', Icons.account_balance_wallet_outlined);
        
        int totalDialokasikan = 0;
        for (var div in divisiList) {
          totalDialokasikan += (div['alokasi_budget'] as int);
        }
        int sisaBelumDialokasikan = _budgetAcara - totalDialokasikan;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, 
                  end: Alignment.bottomRight, 
                  colors: _isDarkMode ? [const Color(0xFF374151), const Color(0xFF1F2937)] : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: navy.withValues(alpha: _isDarkMode ? 0.1 : 0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Budget Utama Acara', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(_isBalanceHidden ? 'Rp ••••••••' : formatRupiah(_budgetAcara), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Dialokasikan', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(_isBalanceHidden ? 'Rp ••••••••' : formatRupiah(totalDialokasikan), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Sisa Dana', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(
                                  _isBalanceHidden ? 'Rp ••••••••' : formatRupiah(sisaBelumDialokasikan), 
                                  style: TextStyle(color: sisaBelumDialokasikan < 0 ? Colors.redAccent.shade100 : Colors.greenAccent.shade200, fontSize: 14, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Rincian Dana per Divisi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: titleTxtColor)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const BouncingScrollPhysics(),
                itemCount: divisiList.length,
                itemBuilder: (context, index) {
                  final div = divisiList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.02), blurRadius: 8)],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        collapsedIconColor: _isDarkMode ? Colors.white60 : Colors.grey,
                        iconColor: _isDarkMode ? mint : navy,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: mint.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.monetization_on_rounded, color: mint),
                        ),
                        title: Text(div['nama_divisi'], style: TextStyle(fontWeight: FontWeight.bold, color: txtColor)),
                        subtitle: FutureBuilder<int>(
                          future: DatabaseHelper.instance.getTotalPengeluaranByDivisi(div['id']),
                          builder: (context, totalSnapshot) {
                            int totalTerpakai = totalSnapshot.data ?? 0;
                            return Text(_isBalanceHidden ? 'Terpakai: Rp ••••••••' : 'Terpakai: ${formatRupiah(totalTerpakai)}', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white60 : Colors.blueGrey.shade600, fontWeight: FontWeight.w600));
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  alokasi == 0 ? 'Alokasi' : 'Sisa Alokasi', 
                                  style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  alokasi == 0 ? 'Tak Dibatasi' : (_isBalanceHidden ? 'Rp ••••••••' : formatRupiah(sisa)),
                                  style: TextStyle(
                                    color: alokasi == 0 
                                        ? Colors.blueGrey 
                                        : (isOverBudget ? Colors.red.shade600 : (_isDarkMode ? mint : navy)), 
                                    fontWeight: FontWeight.w900, 
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: innerContainerColor,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('Riwayat Pengeluaran:', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey)),
                                ),
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
                                            title: Text('[${p['tanggal']}] ${p['nama_barang']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: txtColor)),
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
                                                          context: context,
                                                          builder: (dialogCtx) => AlertDialog(
                                                            title: const Text('Hapus Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
                                                            content: Text('Hapus pengeluaran "${p['nama_barang']}"?'),
                                                            actions: [
                                                              TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Batal')),
                                                              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400), onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
                                                            ],
                                                          ),
                                                        );
                                                        if (confirm == true) {
                                                          await DatabaseHelper.instance.deletePengeluaran(p['id']);
                                                          if (mounted) setState(() {});
                                                        }
                                                      }
                                                    },
                                                    itemBuilder: (context) => const [
                                                      PopupMenuItem(value: 'edit', child: Text('Edit Data')),
                                                      PopupMenuItem(value: 'delete', child: Text('Void (Hapus)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                                    ],
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
                                    child: TextButton.icon(
                                      onPressed: () => _showAddPengeluaranDialog(div['id'], div['nama_divisi']),
                                      icon: Icon(Icons.add_shopping_cart, color: mint, size: 18),
                                      label: Text('Tambah Pengeluaran', style: TextStyle(color: mint, fontWeight: FontWeight.bold)),
                                    ),
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
      },
    );
  }

  // =================================================================
  // TAB 3: MEMBER / ANGGOTA TIM (FITUR BARU)
  // =================================================================
  Widget _buildMemberTab() {
    final Color bgCard = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color txtColor = _isDarkMode ? Colors.white : Colors.black87;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getDivisiByAcara(widget.idAcara),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Ambil semua data di tabel divisi, karena di sistem ini member/tim disimpan di tabel yang sama
        final divisiList = snapshot.data!;

        return Column(
          children: [
            if (_isKetuplak)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mint.withValues(alpha: 0.15),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _showAddMemberDialog,
                  icon: Icon(Icons.person_add_alt_1_rounded, color: mint),
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
                      
                      // Identifikasi tipe row berdasarkan pola string penyimpanan
                      bool isKetuplak = rawName.contains('Ketuplak:');
                      bool isAnggota = rawName.startsWith('Anggota:');
                      
                      String displayName = rawName;
                      String roleName = 'Divisi Operasional';
                      IconData icon = Icons.workspaces_rounded;
                      Color iconColor = Colors.blueGrey;

                      if (isKetuplak) {
                        displayName = rawName.replaceAll('Inti (Ketuplak: ', '').replaceAll(')', '');
                        roleName = 'Ketua Pelaksana';
                        icon = Icons.star_rounded;
                        iconColor = Colors.orangeAccent;
                      } else if (isAnggota) {
                        displayName = rawName.replaceAll('Anggota: ', '');
                        roleName = 'Anggota Tim';
                        icon = Icons.person_rounded;
                        iconColor = _isDarkMode ? mint : navy;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.02), blurRadius: 8)],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: iconColor.withValues(alpha: 0.15),
                            child: Icon(icon, color: iconColor),
                          ),
                          title: Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, color: txtColor)),
                          subtitle: Text(roleName, style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white60 : Colors.blueGrey.shade400)),
                          // Logika: Ketuplak bisa menghapus anggota lain & divisi, tapi tidak bisa menghapus status Ketuplak miliknya sendiri
                          trailing: (_isKetuplak && !isKetuplak) 
                            ? IconButton(
                                icon: Icon(isAnggota ? Icons.person_remove_rounded : Icons.delete_outline, color: Colors.red.shade400, size: 20),
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
  // DIALOG-DIALOG CRUD
  // =================================================================
  void _showEditAcaraDialog() {
    final namaController = TextEditingController(text: _namaAcaraReal);
    final budgetController = TextEditingController(text: _budgetAcara.toString());
    final tanggalController = TextEditingController(text: _tanggalAcara);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Info Acara', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaController, decoration: InputDecoration(labelText: 'Nama Acara', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(controller: budgetController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Total Budget Acara', prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(
              controller: tanggalController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Tanggal', suffixIcon: const Icon(Icons.calendar_month), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Divisi', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nama Divisi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(
              controller: alokasiController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Alokasi Dana', prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
                if (!sukses) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(backgroundColor: Colors.red.shade600, content: const Text('Gagal! Total alokasi divisi melebihi Budget Utama Acara.')));
                  return;
                }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Tugas', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: taskController, decoration: InputDecoration(labelText: 'Nama Tugas', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: deadlineController, readOnly: true, decoration: InputDecoration(hintText: 'Deadline', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Buat Divisi', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nama Divisi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(
              controller: alokasiController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Alokasi Dana', prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
                final sukses = await DatabaseHelper.instance.insertDivisiWithValidasi({
                  'id_acara': widget.idAcara, 'nama_divisi': nama, 'alokasi_budget': alokasi,
                });
                if (!dialogContext.mounted) return;
                if (!sukses) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(backgroundColor: Colors.red.shade600, content: const Text('Gagal! Total alokasi divisi melebihi Budget Utama Acara.')));
                  return;
                }
                Navigator.pop(dialogContext);
                if (mounted) {
                  setState(() {});
                  _checkKetuplakStatus(); 
                }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Tugas Baru $namaDivisi', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: taskController, decoration: InputDecoration(hintText: 'Misal: Beli Kertas HVS', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: deadlineController, readOnly: true, decoration: InputDecoration(hintText: 'Pilih deadline', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
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
                await DatabaseHelper.instance.insertTask({
                  'id_divisi': idDivisi, 'nama_task': taskController.text.trim(), 'is_done': 0, 'status': 'Belum Selesai', 'deadline': deadlineController.text.isEmpty ? null : deadlineController.text,
                });
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

  void _showAddPengeluaranDialog(int idDivisi, String namaDivisi) {
    final tanggalController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final namaBarangController = TextEditingController();
    final jumlahController = TextEditingController(text: '1');
    final nominalController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Pengeluaran $namaDivisi', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tanggalController, readOnly: true,
                decoration: InputDecoration(labelText: 'Tanggal', suffixIcon: const Icon(Icons.calendar_month), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onTap: () async {
                  final picked = await showDatePicker(context: dialogContext, initialDate: DateTime.now(), firstDate: DateTime(DateTime.now().year - 5), lastDate: DateTime(DateTime.now().year + 5));
                  if (picked != null) tanggalController.text = picked.toIso8601String().split('T')[0];
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: namaBarangController, decoration: InputDecoration(labelText: 'Nama Barang', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(flex: 1, child: TextField(controller: jumlahController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: TextField(controller: nominalController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Harga Satuan', prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ],
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
                  divisiId: idDivisi, tanggal: tanggalController.text, namaBarang: namaBarangController.text.trim(), jumlah: jumlah, nominal: nominal,
                );
                if (!dialogContext.mounted) return;
                if (!berhasil) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(backgroundColor: Colors.red.shade600, content: const Text('Gagal! Pengeluaran ini melebihi batas alokasi dana divisi.')));
                  return;
                }
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

  void _showUpdatePengeluaranDialog(Map<String, dynamic> pengeluaran, String namaDivisi) {
    final tanggalController = TextEditingController(text: pengeluaran['tanggal']);
    final namaBarangController = TextEditingController(text: pengeluaran['nama_barang']);
    final jumlahController = TextEditingController(text: pengeluaran['jumlah'].toString());
    final nominalController = TextEditingController(text: pengeluaran['nominal'].toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Pengeluaran', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tanggalController, readOnly: true,
                decoration: InputDecoration(labelText: 'Tanggal', suffixIcon: const Icon(Icons.calendar_month), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onTap: () async {
                  DateTime init = DateTime.now();
                  try { init = DateTime.parse(tanggalController.text); } catch (_) {}
                  final picked = await showDatePicker(context: dialogContext, initialDate: init, firstDate: DateTime(DateTime.now().year - 5), lastDate: DateTime(DateTime.now().year + 5));
                  if (picked != null) tanggalController.text = picked.toIso8601String().split('T')[0];
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: namaBarangController, decoration: InputDecoration(labelText: 'Nama Barang', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(flex: 1, child: TextField(controller: jumlahController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: TextField(controller: nominalController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Harga Satuan', prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ],
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
                  id: pengeluaran['id'], divisiId: pengeluaran['divisi_id'], tanggal: tanggalController.text, namaBarang: namaBarangController.text.trim(), jumlah: jumlah, nominal: nominal,
                );
                if (!dialogContext.mounted) return;
                if (!berhasil) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(backgroundColor: Colors.red.shade600, content: const Text('Gagal! Pengeluaran ini melebihi batas alokasi dana divisi.')));
                  return;
                }
                Navigator.pop(dialogContext);
                if (mounted) setState(() {});
              }
            },
            child: const Text('Perbarui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}