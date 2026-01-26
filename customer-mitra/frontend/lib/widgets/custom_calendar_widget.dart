import 'package:flutter/material.dart';

class CustomCalendarWidget extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? selectedDate;
  final bool disablePast;
  final DateTime? minDate;

  const CustomCalendarWidget(
      {Key? key,
      required this.initialDate,
      this.selectedDate,
      this.disablePast = false,
      this.minDate})
      : super(key: key);

  @override
  State<CustomCalendarWidget> createState() => _CustomCalendarWidgetState();
}

class _CustomCalendarWidgetState extends State<CustomCalendarWidget> {
  late DateTime visibleMonth;
  DateTime? selected;

  @override
  void initState() {
    super.initState();
    visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    selected = widget.selectedDate;
  }

  void _prevMonth() {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + 1);
    });
  }

  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final days = <DateTime>[];
    // Start grid on Monday (weekday 1)
    final weekdayOfFirst = first.weekday; // Monday=1
    DateTime start = first.subtract(Duration(days: weekdayOfFirst - 1));
    for (int i = 0; i < 42; i++) {
      days.add(start.add(Duration(days: i)));
    }
    return days;
  }

  String _monthName(int m) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    if (m < 1 || m > 12) return '';
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(visibleMonth);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final minAllowed = widget.minDate != null
        ? DateTime(
            widget.minDate!.year, widget.minDate!.month, widget.minDate!.day)
        : null;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Prev button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left, color: Colors.black87),
                  ),
                ),
                // Month title
                Expanded(
                  child: Center(
                    child: Text(
                      '${_monthName(visibleMonth.month)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                // Next button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _nextMonth,
                    icon:
                        const Icon(Icons.chevron_right, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Sen',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
                Text('Sel',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
                Text('Rab',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
                Text('Kam',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
                Text('Jum',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
                Text('Sab',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
                Text('Min',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            // Dates grid
            GridView.builder(
              shrinkWrap: true,
              itemCount: days.length,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.4,
                crossAxisSpacing: 4,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final d = days[index];
                final isSameMonth = d.month == visibleMonth.month;
                final isSelected = selected != null &&
                    d.year == selected!.year &&
                    d.month == selected!.month &&
                    d.day == selected!.day;
                final isBeforeToday = d.isBefore(todayStart);
                final isBeforeMin =
                    minAllowed != null && d.isBefore(minAllowed);
                final isDisabled = (!isSameMonth && true == false)
                    ? true
                    : ((widget.disablePast && isBeforeToday) || isBeforeMin);

                return GestureDetector(
                  onTap: () {
                    if (!isSameMonth) return;
                    if (isDisabled) return;
                    setState(() {
                      selected = d;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF123EBD)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(isSelected ? 18 : 6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${d.day.toString()}',
                      style: TextStyle(
                        color: isSameMonth
                            ? (isSelected
                                ? Colors.white
                                : (isDisabled
                                    ? Colors.grey.shade400
                                    : Colors.black87))
                            : Colors.grey.shade400,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Bottom selected date bar (tap to confirm)
            const SizedBox(height: 8),
            GestureDetector(
              onTap: (selected == null ||
                      (widget.disablePast && selected!.isBefore(todayStart)))
                  ? null
                  : () => Navigator.of(context).pop(selected),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    selected == null
                        ? 'Pilih tanggal'
                        : '${selected!.day.toString().padLeft(2, '0')} / ${selected!.month.toString().padLeft(2, '0')} / ${selected!.year}',
                    style: TextStyle(
                      color: selected == null
                          ? Colors.grey[500]
                          : (widget.disablePast &&
                                  selected!.isBefore(todayStart)
                              ? Colors.grey[500]
                              : Colors.black87),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
