import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InteractiveHorizontalDateStrip extends StatefulWidget {
  // Callback untuk mengirim tanggal yang dipilih kembali ke halaman utama
  final Function(DateTime) onDateSelected;
  final bool isDarkMode;

  const InteractiveHorizontalDateStrip({
    super.key,
    required this.onDateSelected,
    required this.isDarkMode,
  });

  @override
  State<InteractiveHorizontalDateStrip> createState() => _InteractiveHorizontalDateStripState();
}

class _InteractiveHorizontalDateStripState extends State<InteractiveHorizontalDateStrip> {
  // State internal untuk menyimpan tanggal yang sedang dipilih (Default: Hari ini)
  late DateTime _selectedDate;
  
  // List yang akan menampung deretan tanggal
  final List<DateTime> _dateList = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateDateList();
  }

  // 🔥 Logika Internal: Men-generate 14 hari ke depan secara dinamis
  void _generateDateList() {
    final now = DateTime.now();
    for (int i = 0; i < 15; i++) {
      _dateList.add(now.add(Duration(days: i)));
    }
  }

  // Fungsi helper untuk mengecek apakah dua tanggal jatuh di hari yang sama
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    // Definisi Palet Warna menyesuaikan tema aplikasi
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1E3A8A); // Navy
    final Color inactiveBg = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white; // Card bg
    final Color activeBg = const Color(0xFF10B981); // Mint Green
    final Color shadowColor = Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05);

    return SizedBox(
      height: 85, // Tinggi area widget
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dateList.length,
        itemBuilder: (context, index) {
          final currentDate = _dateList[index];
          final isSelected = _isSameDay(_selectedDate, currentDate);

          // Format tanggal: "Sen" (Hari), "15" (Tanggal)
          final String dayName = DateFormat('E', 'id_ID').format(currentDate); 
          final String dayNumber = DateFormat('d').format(currentDate);

          return GestureDetector(
            onTap: () {
              // 1. Ubah state UI internal widget ini
              setState(() {
                _selectedDate = currentDate;
              });
              // 2. Pancarkan data tanggal ke Parent Component (Emit Event)
              widget.onDateSelected(currentDate);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(
                left: index == 0 ? 20 : 6, // Jarak lebih besar untuk elemen pertama
                right: index == _dateList.length - 1 ? 20 : 6, // Jarak lebih besar untuk elemen terakhir
                top: 4, bottom: 8, // Ruang untuk bayangan (shadow)
              ),
              width: 65,
              decoration: BoxDecoration(
                color: isSelected ? activeBg : inactiveBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : (widget.isDarkMode ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100),
                  width: 1,
                ),
                boxShadow: [
                  if (isSelected) 
                    BoxShadow(color: activeBg.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                  else
                    BoxShadow(color: shadowColor, blurRadius: 6, offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white.withValues(alpha: 0.9) : (widget.isDarkMode ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                  // Indikator titik kecil kalau itu adalah hari ini
                  if (_isSameDay(currentDate, DateTime.now())) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}