import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InteractiveHorizontalDateStrip extends StatefulWidget {
  // 🔥 UPDATE: Menggunakan tipe DateTime? (Bisa null untuk mewakili opsi "Semua")
  final Function(DateTime?) onDateSelected;
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
  // 🔥 UPDATE: Default saat aplikasi dibuka adalah null (menampilkan semua tugas)
  DateTime? _selectedDate;
  
  final List<DateTime> _dateList = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = null; 
    _generateDateList();
  }

  void _generateDateList() {
    final now = DateTime.now();
    for (int i = 0; i < 15; i++) {
      _dateList.add(now.add(Duration(days: i)));
    }
  }

  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1E3A8A);
    final Color inactiveBg = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color activeBg = const Color(0xFF10B981); 
    final Color shadowColor = Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05);

    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dateList.length + 1, // 🔥 UPDATE: Ditambah 1 slot untuk tombol "Semua"
        itemBuilder: (context, index) {
          
          // 🔥 RENDER TOMBOL "SEMUA" DI PALING KIRI
          if (index == 0) {
            final isSelected = _selectedDate == null;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedDate = null);
                widget.onDateSelected(null); // Kirim sinyal null
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(left: 20, right: 6, top: 4, bottom: 8),
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
                    Icon(Icons.all_inclusive_rounded, color: isSelected ? Colors.white : (widget.isDarkMode ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500), size: 20),
                    const SizedBox(height: 4),
                    Text(
                      'Semua',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : textColor),
                    ),
                  ],
                ),
              ),
            );
          }

          // 🔥 RENDER DAFTAR TANGGAL (Index dikurangi 1 karena slot 0 sudah dipakai)
          final currentDate = _dateList[index - 1];
          final isSelected = _isSameDay(_selectedDate, currentDate);
          final String dayName = DateFormat('E', 'id_ID').format(currentDate); 
          final String dayNumber = DateFormat('d').format(currentDate);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = currentDate);
              widget.onDateSelected(currentDate); // Kirim tanggal ke parent
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(
                left: 6, 
                right: index == _dateList.length ? 20 : 6, 
                top: 4, bottom: 8,
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
                  Text(dayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white.withValues(alpha: 0.9) : (widget.isDarkMode ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500))),
                  const SizedBox(height: 4),
                  Text(dayNumber, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : textColor)),
                  if (_isSameDay(currentDate, DateTime.now())) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(color: isSelected ? Colors.white : const Color(0xFF2563EB), shape: BoxShape.circle),
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