import 'package:flutter/material.dart';

class DivisionDetailScreen extends StatelessWidget {
  final int idDivisi;
  final String namaDivisi;

  const DivisionDetailScreen({super.key, required this.idDivisi, required this.namaDivisi});

  @override
  Widget build(BuildContext context) {
    final Color navy = const Color(0xFF1E3A8A);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: navy),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Divisi $namaDivisi',
            style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section Anggota Tim ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Anggota Tim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            ),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _TeamCard(name: 'Sunghoon', role: 'Koor'),
                  _TeamCard(name: 'Esa', role: 'Anggota'),
                  _TeamCard(name: 'Jake', role: 'Anggota'),
                  _TeamCard(name: 'Ni-ki', role: 'Anggota'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Custom Modern TabBar ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [
                  Tab(text: 'Daftar Tugas'),
                  Tab(text: 'Catatan RAB'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Isi Konten Tab ---
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPlaceholder('Belum ada tugas untuk divisi ini.', Icons.assignment_outlined),
                  _buildPlaceholder('Belum ada pengeluaran dicatat.', Icons.receipt_long_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// Desain Avatar Kartu yang Elegan
class _TeamCard extends StatelessWidget {
  final String name;
  final String role;
  const _TeamCard({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: role == 'Koor' ? const Color(0xFF1E3A8A) : Colors.grey.shade200,
            child: Text(name[0], style: TextStyle(color: role == 'Koor' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(role, style: TextStyle(fontSize: 11, color: role == 'Koor' ? const Color(0xFF10B981) : Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}