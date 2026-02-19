import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// หน้าเลือกวันเกิดแบบ Wheel Picker สไตล์ iOS
/// วัน 1–31, เดือน มกราคม–ธันวาคม, ปี พ.ศ. (เลื่อนลงได้จากปีปัจจุบัน)
class BirthDatePickerScreen extends StatefulWidget {
  final DateTime? initialDate;

  const BirthDatePickerScreen({super.key, this.initialDate});

  @override
  State<BirthDatePickerScreen> createState() => _BirthDatePickerScreenState();
}

class _BirthDatePickerScreenState extends State<BirthDatePickerScreen> {
  static const List<String> _monthNames = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  int get _currentYearCE => DateTime.now().year;
  /// ปี พ.ศ. เริ่มจากปีปัจจุบันลงไป (ประมาณ 90 ปี)
  static int get _minYearBE => 2483; // 1940 CE
  int get _maxYearBE => _currentYearCE + 543;

  int _selectedDay = 1;
  int _selectedMonth = 1;
  int _selectedYearBE = 2543; // 2000 CE

  int _daysInMonth() {
    final yearCE = _selectedYearBE - 543;
    return DateTime(yearCE, _selectedMonth + 1, 0).day;
  }

  void _clampDay() {
    final maxDay = _daysInMonth();
    if (_selectedDay > maxDay) {
      setState(() => _selectedDay = maxDay);
      _dayController.jumpToItem(_selectedDay - 1);
    }
  }

  @override
  void initState() {
    super.initState();
    final init = widget.initialDate ?? DateTime(2000, 1, 1);
    _selectedDay = init.day;
    _selectedMonth = init.month - 1; // 0-based for list
    _selectedYearBE = init.year + 543;

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth);
    _yearController = FixedExtentScrollController(
      initialItem: (_maxYearBE - _selectedYearBE).clamp(0, _maxYearBE - _minYearBE),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  DateTime get _selectedDate {
    final yearCE = _selectedYearBE - 543;
    final maxDay = DateTime(yearCE, _selectedMonth + 1, 0).day;
    final day = _selectedDay > maxDay ? maxDay : _selectedDay;
    return DateTime(yearCE, _selectedMonth + 1, day);
  }

  @override
  Widget build(BuildContext context) {
    final yearCount = _maxYearBE - _minYearBE + 1;
    final yearItems = List.generate(yearCount, (i) => _maxYearBE - i);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF2F2F7),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF628141), fontSize: 17)),
          onPressed: () => Navigator.pop(context),
        ),
        middle: const Text('วันเกิด', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('ตกลง', style: TextStyle(color: Color(0xFF628141), fontSize: 17, fontWeight: FontWeight.w600)),
          onPressed: () => Navigator.pop(context, _selectedDate),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // แสดงวันที่เลือก
            Text(
              '${_selectedDay} ${_monthNames[_selectedMonth]} ${_selectedYearBE}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            // Wheel Picker
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _dayController,
                      itemExtent: 44,
                      diameterRatio: 1.4,
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.003,
                      onSelectedItemChanged: (i) {
                        setState(() => _selectedDay = i + 1);
                        _clampDay();
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 31,
                        builder: (context, index) {
                          final day = index + 1;
                          return Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: _selectedDay == day ? Colors.black : Colors.black38,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Container(width: 1, color: Colors.black12),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _monthController,
                      itemExtent: 44,
                      diameterRatio: 1.4,
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.003,
                      onSelectedItemChanged: (i) {
                        setState(() => _selectedMonth = i);
                        _clampDay();
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 12,
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              _monthNames[index],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: _selectedMonth == index ? Colors.black : Colors.black38,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Container(width: 1, color: Colors.black12),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _yearController,
                      itemExtent: 44,
                      diameterRatio: 1.4,
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.003,
                      onSelectedItemChanged: (i) {
                        setState(() => _selectedYearBE = yearItems[i]);
                        _clampDay();
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: yearItems.length,
                        builder: (context, index) {
                          final y = yearItems[index];
                          return Center(
                            child: Text(
                              '$y',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: _selectedYearBE == y ? Colors.black : Colors.black38,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
