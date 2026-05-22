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
            return Container(
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
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: navy.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.workspaces_filled, color: navy),
                  ),
                  // 🔥 Teks Alokasi Dana sudah dihapus dari sini 🔥
                  title: Text(div['nama_divisi'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                children: tasks.map((task) => CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: mint,
                                  title: Text(
                                    task['nama_task'], 
                                    style: TextStyle(
                                      decoration: task['is_done'] == 1 ? TextDecoration.lineThrough : null,
                                      color: task['is_done'] == 1 ? Colors.grey : Colors.black87,
                                    )
                                  ),
                                  value: task['is_done'] == 1,
                                  onChanged: (bool? value) async {
                                    await DatabaseHelper.instance.updateTaskStatus(task['id'], value! ? 1 : 0);
                                    setState(() {});
                                  },
                                )).toList(),
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
            );
          },
        );
      },
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
    final budgetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Buat Divisi', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nama Divisi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(controller: budgetController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Alokasi Dana', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mint, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              String nama = nameController.text.trim();
              String budget = budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');
              if (nama.isNotEmpty && budget.isNotEmpty) {
                await DatabaseHelper.instance.insertDivisi({
                  'id_acara': widget.idAcara,
                  'nama_divisi': nama,
                  'alokasi_budget': int.parse(budget),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Tugas Baru $namaDivisi', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 18)),
        content: TextField(controller: taskController, decoration: InputDecoration(hintText: 'Misal: Beli Kertas HVS', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
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