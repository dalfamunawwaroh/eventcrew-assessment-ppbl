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
  final String _role = PrefsHelper.userRole;
  String _status = 'Persiapan';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final acara = await DatabaseHelper.instance.getAcaraById(widget.idAcara);
    if (acara != null && mounted) {
      setState(() {
        _status = (acara['status'] as String?) ?? 'Persiapan';
      });
    }
  }

  String formatRupiah(int number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E3A8A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.namaAcara,
            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(child: Text(_status, style: TextStyle(color: navy, fontWeight: FontWeight.bold))),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.edit_calendar, color: navy),
              onSelected: (value) async {
                await DatabaseHelper.instance.updateAcaraStatus(widget.idAcara, value);
                if (mounted) setState(() => _status = value);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'Persiapan', child: Text('Persiapan')),
                PopupMenuItem(value: 'Sedang Berjalan', child: Text('Sedang Berjalan')),
                PopupMenuItem(value: 'Selesai', child: Text('Selesai')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // --- Custom Modern TabBar ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [
                  Tab(text: 'Divisi & Tugas'),
                  Tab(text: 'RAB Acara'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // --- Isi Konten Tab ---
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDivisiTab(), // Tab 1: Divisi (Tanpa Dana)
                  _buildRABTab(),    // Tab 2: RAB Acara (Dashboard Dana)
                ],
              ),
            ),
          ],
        ),
        // Tombol Tambah Divisi
        floatingActionButton: _role == 'Ketuplak' 
            ? FloatingActionButton.extended(
                backgroundColor: mint,
                elevation: 4,
                onPressed: _showAddDivisiDialog,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Divisi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // =================================================================
  // TAB 1: DIVISI & TUGAS (Murni Operasional)
  // =================================================================
  Widget _buildDivisiTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getDivisiByAcara(widget.idAcara),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final divisiList = snapshot.data!;

        if (divisiList.isEmpty) return _buildPlaceholder('Belum ada divisi yang dibentuk.', Icons.groups_outlined);

        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
          physics: const BouncingScrollPhysics(),
          itemCount: divisiList.length,
          itemBuilder: (context, index) {
            final div = divisiList[index];

            return GestureDetector(
              onLongPress: () => _showUpdateDivisiStatusDialog(div),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    collapsedIconColor: Colors.grey,
                    iconColor: navy,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _showUpdateDivisiStatusDialog(div),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _statusColor((div['status'] as String?) ?? 'Belum Aktif').withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.workspaces_filled, color: _statusColor((div['status'] as String?) ?? 'Belum Aktif')),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            div['nama_divisi'],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _statusColor((div['status'] as String?) ?? 'Belum Aktif')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status chip (tappable)
                        Builder(builder: (context) {
                          final s = (div['status'] as String?) ?? 'Belum Aktif';
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showUpdateDivisiStatusDialog(div),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  backgroundColor: _statusColor(s).withOpacity(0.12),
                                  label: Text(s, style: TextStyle(color: _statusColor(s), fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                if (_role == 'Ketuplak')
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                    tooltip: 'Hapus Divisi',
                                    onPressed: () => _confirmDeleteDivisi(div),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('Daftar Tugas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),

                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: DatabaseHelper.instance.getTasksByDivisi(div['id']),
                              builder: (context, taskSnapshot) {
                                if (!taskSnapshot.hasData) return const SizedBox.shrink();
                                final tasks = taskSnapshot.data!;
                                if (tasks.isEmpty) return const Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text('Belum ada tugas.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));

                                  return Column(
                                    children: tasks.map((task) {
                                      return CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        activeColor: mint,
                                        title: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task['nama_task'],
                                              style: TextStyle(
                                                decoration: task['is_done'] == 1 ? TextDecoration.lineThrough : null,
                                                color: task['is_done'] == 1 ? Colors.grey : Colors.black87,
                                              ),
                                            ),
                                            if (task['deadline'] != null && (task['deadline'] as String).isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text('Deadline: ${task['deadline']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              ),
                                          ],
                                        ),
                                        value: task['is_done'] == 1,
                                        secondary: IconButton(
                                          icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Hapus Tugas'),
                                                content: Text('Hapus tugas "${task['nama_task']}"?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await DatabaseHelper.instance.deleteTask(task['id']);
                                              if (mounted) setState(() {});
                                            }
                                          },
                                        ),
                                        onChanged: (bool? value) async {
                                          await DatabaseHelper.instance.updateTaskStatus(task['id'], value! ? 1 : 0);
                                          setState(() {});
                                        },
                                      );
                                    }).toList(),
                                  );
                              },
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _showAddTaskDialog(div['id'], div['nama_divisi']),
                                icon: Icon(Icons.add_task, color: navy, size: 18),
                                label: Text('Tambah Tugas', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDivisi(Map<String, dynamic> div) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Divisi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus divisi "${div['nama_divisi']}"? Semua tugas dan pengeluaran terkait juga akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () async {
              await DatabaseHelper.instance.deleteDivisi(div['id']);
              if (mounted) setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Sedang Bertugas':
        return Colors.lightBlue.shade600;
      case 'Selesai':
        return Colors.green.shade600;
      case 'Belum Aktif':
      default:
        return Colors.grey.shade600;
    }
  }

  void _showUpdateDivisiStatusDialog(Map<String, dynamic> div) {
    String current = (div['status'] as String?) ?? 'Belum Aktif';
    String selected = current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Ubah Status Divisi: ${div['nama_divisi']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setInner) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(value: 'Belum Aktif', groupValue: selected, title: const Text('Belum Aktif'), onChanged: (v) => setInner(() => selected = v!)),
              RadioListTile<String>(value: 'Sedang Bertugas', groupValue: selected, title: const Text('Sedang Bertugas'), onChanged: (v) => setInner(() => selected = v!)),
              RadioListTile<String>(value: 'Selesai', groupValue: selected, title: const Text('Selesai'), onChanged: (v) => setInner(() => selected = v!)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mint),
            onPressed: () async {
              if (selected != current) {
                await DatabaseHelper.instance.updateDivisiStatus(div['id'], selected);
                if (mounted) setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // TAB 2: RAB ACARA (Dashboard Finansial)
  // =================================================================
  Widget _buildRABTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getDivisiByAcara(widget.idAcara),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final divisiList = snapshot.data!;
        
        if (divisiList.isEmpty) return _buildPlaceholder('Belum ada divisi & dana.', Icons.account_balance_wallet_outlined);

        // Kalkulasi Total Alokasi Semua Divisi
        int totalAlokasi = 0;
        for (var div in divisiList) {
          totalAlokasi += (div['alokasi_budget'] as int);
        }

        return Column(
          children: [
            // Card Banner Total Keuangan
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: navy.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Alokasi Keseluruhan', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(formatRupiah(totalAlokasi), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Rincian Dana per Divisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              ),
            ),

            // List Breakdown Dana per Divisi
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: mint.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.monetization_on_rounded, color: mint),
                      ),
                      title: Text(div['nama_divisi'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Terkapakai: Rp 0', style: TextStyle(fontSize: 12)), // Ini nanti dilanjutin Esa
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Alokasi', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(formatRupiah(div['alokasi_budget']), style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      onTap: () {
                        // Nanti Esa bisa tambahin fitur buat klik masuk nambah pengeluaran di sini
                      },
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
  // DIALOG BOXES
  // =================================================================
  void _showAddDivisiDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Buat Divisi', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nama Divisi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              String nama = nameController.text.trim();
              if (nama.isNotEmpty) {
                await DatabaseHelper.instance.insertDivisi({
                  'id_acara': widget.idAcara,
                  'nama_divisi': nama,
                  'alokasi_budget': 0,
                });
                if (mounted) Navigator.pop(context);
                setState(() {});
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
    DateTime? pickedDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Tugas Baru $namaDivisi', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: taskController, decoration: InputDecoration(hintText: 'Misal: Beli Kertas HVS', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: deadlineController, readOnly: true, decoration: InputDecoration(hintText: 'Pilih deadline (opsional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final now = DateTime.now();
                    final dd = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 2), lastDate: DateTime(now.year + 5));
                    if (dd != null) {
                      pickedDate = dd;
                      deadlineController.text = dd.toIso8601String().split('T')[0];
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (taskController.text.trim().isNotEmpty) {
                await DatabaseHelper.instance.insertTask({
                  'id_divisi': idDivisi,
                  'nama_task': taskController.text.trim(),
                  'is_done': 0,
                  'status': 'Belum Selesai',
                  'deadline': deadlineController.text.isEmpty ? null : deadlineController.text,
                });
                if (mounted) Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}