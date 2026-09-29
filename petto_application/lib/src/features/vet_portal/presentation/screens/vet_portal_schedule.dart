part of 'vet_portal_screen.dart';

class _VetScheduleResult {
  const _VetScheduleResult({required this.startsAt, required this.reason});

  final DateTime startsAt;
  final String reason;
}

class _VetScheduleDialog extends StatefulWidget {
  const _VetScheduleDialog({
    required this.initialDateTime,
    required this.initialReason,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final DateTime initialDateTime;
  final String initialReason;
  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  State<_VetScheduleDialog> createState() => _VetScheduleDialogState();
}

class _VetScheduleDialogState extends State<_VetScheduleDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late final TextEditingController _reasonController;

  static const _timeSlots = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 30),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 30),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime);
    _reasonController = TextEditingController(text: widget.initialReason);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  DateTime get _startsAt => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  List<TimeOfDay> get _availableSlots {
    final exists = _timeSlots.any(
      (slot) =>
          slot.hour == _selectedTime.hour &&
          slot.minute == _selectedTime.minute,
    );
    if (exists) return _timeSlots;
    final slots = [..._timeSlots, _selectedTime];
    slots.sort(
      (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
    );
    return slots;
  }

  void _submit() {
    Navigator.of(context).pop(
      _VetScheduleResult(
        startsAt: _startsAt,
        reason: _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(
      10,
      (index) => DateTime(now.year, now.month, now.day + index + 1),
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _VetUi.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.14),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                fontFamily: AppTheme.displayFontFamily,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                color: AppTheme.mutedText,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _VetUi.blush.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.09),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _weekdayLabel(_selectedDate),
                                style: TextStyle(
                                  color: AppTheme.mutedText,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_monthLabel(_selectedDate.month)} ${_selectedDate.day}',
                                style: const TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: AppTheme.displayFontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _timeLabel(_selectedTime),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select date',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 9),
                      itemBuilder: (context, index) {
                        final date = dates[index];
                        final selected = _sameDay(date, _selectedDate);
                        return _ScheduleDateChip(
                          date: date,
                          selected: selected,
                          onTap: () => setState(() => _selectedDate = date),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Available time',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (final slot in _availableSlots)
                        _ScheduleTimeChip(
                          time: slot,
                          selected:
                              slot.hour == _selectedTime.hour &&
                              slot.minute == _selectedTime.minute,
                          onTap: () => setState(() => _selectedTime = slot),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    minLines: 2,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    scrollPadding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom + 120,
                    ),
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Short note for the owner',
                      hintStyle: TextStyle(
                        color: AppTheme.mutedText.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w700,
                      ),
                      prefixIcon: const Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.72),
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: _VetUi.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: _VetUi.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: _VetUi.border),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check_rounded, size: 19),
                          label: Text(widget.actionLabel),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _weekdayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }

  static String _monthLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month - 1];
  }

  static String _timeLabel(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ScheduleDateChip extends StatelessWidget {
  const _ScheduleDateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 66,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(
                alpha: selected ? 0.14 : 0.04,
              ),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _VetScheduleDialogState._weekdayLabel(date),
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.secondaryText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTimeChip extends StatelessWidget {
  const _ScheduleTimeChip({
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final TimeOfDay time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _VetUi.blush : _VetUi.cream,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.36)
                : const Color(0xFFEAD7BD),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: selected ? AppTheme.primaryColor : const Color(0xFFD3A33B),
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              _VetScheduleDialogState._timeLabel(time),
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
