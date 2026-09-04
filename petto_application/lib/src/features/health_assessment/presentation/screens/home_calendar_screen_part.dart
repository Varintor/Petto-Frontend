part of 'home_screen.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _HomeCalendarPreviewDay extends StatelessWidget {
  const _HomeCalendarPreviewDay({
    required this.date,
    required this.selected,
    required this.hasEvent,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasEvent;
  final VoidCallback onTap;

  String get _weekday {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 78,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor
                : const Color(0xFFFFE7E4).withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withValues(alpha: 0.10),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.14),
                      blurRadius: 16,
                      spreadRadius: -10,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weekday,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected
                      ? Colors.white70
                      : AppTheme.secondaryText.withValues(alpha: 0.52),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : AppTheme.secondaryText,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: hasEvent ? 6 : 3,
                height: hasEvent ? 6 : 3,
                decoration: BoxDecoration(
                  color: hasEvent
                      ? (selected ? Colors.white : AppTheme.primaryColor)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScheduleEventLine extends StatelessWidget {
  const _HomeScheduleEventLine({required this.event});

  final CalendarEventData event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: event.color.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(event.icon, color: event.color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.timeLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: event.color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.20),
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeScheduleEmpty extends StatelessWidget {
  const _HomeScheduleEmpty({required this.petName, required this.onTap});

  final String petName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppTheme.primaryColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$petName has no plans yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              textStyle: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            child: const Text('Add plan'),
          ),
        ],
      ),
    );
  }
}

class _CalendarCircleButton extends StatelessWidget {
  const _CalendarCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFB),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.10),
            width: 1.2,
          ),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
    );
  }
}

extension _HomeCalendarScreenPart on _HomeScreenState {
  bool _eventOnDay(CalendarEventData event, int year, int month, int day) {
    return event.date.year == year &&
        event.date.month == month &&
        event.date.day == day;
  }

  Widget _buildHomeCalendarSection(BuildContext context) {
    final monthDays = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final selectedDay = _selectedDate.month == _focusedMonth.month
        ? _selectedDate.day
        : math.min(DateTime.now().day, monthDays);
    final weekStart = math.max(1, selectedDay - 3);
    final startDay = math.min(weekStart, math.max(1, monthDays - 6));
    final days = List<int>.generate(
      math.min(7, monthDays - startDay + 1),
      (index) => startDay + index,
    );
    final selectedEvents = _calendarEvents
        .where((event) => _sameDay(event.date, _selectedDate))
        .toList();
    final now = DateTime.now();
    final upcomingEvents =
        (_calendarEvents.where((event) => !event.date.isBefore(now)).toList()
              ..sort((a, b) => a.date.compareTo(b.date)))
            .take(2)
            .toList();
    final visibleEvents = selectedEvents.isNotEmpty
        ? selectedEvents
        : upcomingEvents;

    void openCalendar() {
      _update(() {
        _activeView = _View.calendar;
        _showNavActionMenu = false;
      });
    }

    return _SoftReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeSectionTitle(
            title: 'Calendar',
            trailing: _monthName(_focusedMonth.month),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFB).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.13),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 22,
                  spreadRadius: -14,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _CalendarCircleButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () {
                        _update(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month - 1,
                          );
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppTheme.secondaryText,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${visibleEvents.length} care plans nearby',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppTheme.mutedText,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _CalendarCircleButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () {
                        _update(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    for (final day in days)
                      Expanded(
                        child: _HomeCalendarPreviewDay(
                          date: DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month,
                            day,
                          ),
                          selected:
                              _selectedDate.year == _focusedMonth.year &&
                              _selectedDate.month == _focusedMonth.month &&
                              _selectedDate.day == day,
                          hasEvent: _calendarEvents.any(
                            (event) => _eventOnDay(
                              event,
                              _focusedMonth.year,
                              _focusedMonth.month,
                              day,
                            ),
                          ),
                          onTap: () {
                            _update(() {
                              _selectedDate = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month,
                                day,
                              );
                            });
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                if (visibleEvents.isEmpty)
                  _HomeScheduleEmpty(
                    petName: _activePet.name,
                    onTap: _showAddCalendarPlanSheet,
                  )
                else
                  for (final event in visibleEvents)
                    _HomeScheduleEventLine(event: event),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: _showAddCalendarPlanSheet,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFE9B8,
                          ).withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              color: Color(0xFFB98422),
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Add',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: const Color(0xFFB98422),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: openCalendar,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context) {
    final monthDays = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final leading = firstDay.weekday % 7;
    final cells = List<int?>.generate(42, (index) {
      final day = index - leading + 1;
      if (day < 1 || day > monthDays) return null;
      return day;
    });

    final selectedEvents = _calendarEvents
        .where((event) => _sameDay(event.date, _selectedDate))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 154),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalendarMonthHeader(
            month: _monthName(_focusedMonth.month),
            year: _focusedMonth.year,
            onPrevious: () {
              _update(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                );
                _selectedDate = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  1,
                );
              });
            },
            onNext: () {
              _update(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                );
                _selectedDate = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  1,
                );
              });
            },
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              _WeekdayLabel('S'),
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.warmSurfaceColor.withValues(alpha: 0.72),
                width: 1.4,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final day = cells[index];
                if (day == null) {
                  return const SizedBox.shrink();
                }
                final now = DateTime.now();
                final selected =
                    _selectedDate.year == _focusedMonth.year &&
                    _selectedDate.month == _focusedMonth.month &&
                    _selectedDate.day == day;
                final isToday =
                    now.year == _focusedMonth.year &&
                    now.month == _focusedMonth.month &&
                    now.day == day;
                final hasEvent = _calendarEvents.any(
                  (event) => _eventOnDay(
                    event,
                    _focusedMonth.year,
                    _focusedMonth.month,
                    day,
                  ),
                );

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _update(() {
                      _selectedDate = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month,
                        day,
                      );
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: selected ? 42 : (isToday ? 38 : 0),
                          height: selected ? 42 : (isToday ? 38 : 0),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primaryColor
                                : isToday
                                ? AppTheme.blushSurfaceColor.withValues(
                                    alpha: 0.64,
                                  )
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : isToday
                                  ? AppTheme.primaryColor.withValues(
                                      alpha: 0.24,
                                    )
                                  : Colors.transparent,
                              width: isToday ? 1.6 : 0,
                            ),
                          ),
                        ),
                        if (isToday)
                          Positioned(
                            top: selected ? 8 : 9,
                            right: selected ? 11 : 9,
                            child: Container(
                              width: selected ? 6 : 7,
                              height: selected ? 6 : 7,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (selected
                                                ? Colors.white
                                                : AppTheme.primaryColor)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Text(
                          '$day',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppTheme.secondaryText,
                                fontWeight: selected || isToday
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                              ),
                        ),
                        if (hasEvent)
                          Positioned(
                            bottom: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isToday && !selected) ...[
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.primaryColor,
                                    shape: BoxShape.circle,
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
          const SizedBox(height: 26),
          _CalendarScheduleHeader(
            title: _isTodaySelection()
                ? "Today's Schedule"
                : _formattedSelectedDate(),
            selectedEvents: selectedEvents.length,
            onAdd: _showAddCalendarPlanSheet,
          ),
          const SizedBox(height: 12),
          if (selectedEvents.isEmpty)
            _NoPlansCard(
              petName: _activePet.name,
              onAdd: _showAddCalendarPlanSheet,
            ),
          for (final event in selectedEvents) ...[
            _CalendarEventCard(
              event: event,
              onDelete: () => _deleteCalendarEvent(event),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddCalendarPlanSheet() async {
    final titleController = TextEditingController();
    var selectedType = 'care';
    var selectedDate = _selectedDate;
    TimeOfDay? selectedTime;

    String timeButtonLabel() {
      final t = selectedTime;
      if (t == null) return 'All day';
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final m = t.minute.toString().padLeft(2, '0');
      final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$h:$m $ampm';
    }

    String dateButtonLabel(DateTime d) {
      const months = [
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
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    final created = await showModalBottomSheet<CalendarEventData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final typeStyle = _calendarPlanStyle(selectedType);
            return AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + bottomInset),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryText.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppTheme.warmSurfaceColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: typeStyle.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                typeStyle.icon,
                                color: typeStyle.color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create care plan',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dateButtonLabel(selectedDate),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.mutedText),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: AppTheme.secondaryText,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: titleController,
                          textInputAction: TextInputAction.done,
                          scrollPadding: EdgeInsets.only(
                            bottom:
                                MediaQuery.viewInsetsOf(context).bottom + 120,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Plan name',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365 * 3),
                                    ),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedDate = picked);
                                  }
                                },
                                icon: const Icon(Icons.calendar_today_rounded),
                                label: Text(dateButtonLabel(selectedDate)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        selectedTime ??
                                        const TimeOfDay(hour: 9, minute: 0),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedTime = picked);
                                  }
                                },
                                icon: const Icon(Icons.access_time_rounded),
                                label: Text(timeButtonLabel()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final type in const [
                              'care',
                              'medication',
                              'vet',
                              'grooming',
                              'walk',
                            ])
                              _CalendarPlanTypeChip(
                                label: _calendarPlanStyle(type).label,
                                icon: _calendarPlanStyle(type).icon,
                                selected: selectedType == type,
                                onTap: () {
                                  setSheetState(() {
                                    selectedType = type;
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: () {
                              final style = _calendarPlanStyle(selectedType);
                              final typedTitle = titleController.text.trim();
                              final startsAt = selectedTime == null
                                  ? null
                                  : DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      selectedTime!.hour,
                                      selectedTime!.minute,
                                    );
                              Navigator.of(context).pop(
                                CalendarEventData(
                                  id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
                                  title: typedTitle.isEmpty
                                      ? style.defaultTitle
                                      : typedTitle,
                                  timeLabel: timeButtonLabel(),
                                  type: selectedType,
                                  completed: false,
                                  date: selectedDate,
                                  startsAt: startsAt,
                                  color: style.color,
                                  icon: style.icon,
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Save plan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    if (created == null || !mounted) return;

    _update(() {
      // Jump the user to the day they just scheduled so the new entry is
      // visible immediately.
      _selectedDate = created.date;
      _focusedMonth = DateTime(created.date.year, created.date.month);
    });
    final saved = await _calendarController.add(created);
    if (saved.startsAt != null) {
      await NotificationService.instance.scheduleEventReminder(
        eventId: saved.id,
        when: saved.startsAt!,
        title: saved.title,
        body: 'Upcoming for ${_pets.isEmpty ? 'your pet' : _activePet.name}',
      );
    }
    if (!mounted) return;
    showTopAlert(
      context,
      saved.startsAt != null
          ? 'Plan saved — reminder set 30 min before.'
          : 'Plan saved.',
      icon: Icons.event_available_rounded,
    );
  }

  Future<void> _deleteCalendarEvent(CalendarEventData event) async {
    await _calendarController.remove(event.id);
    await NotificationService.instance.cancelEventReminder(event.id);
    if (!mounted) return;
    showTopAlert(context, 'Plan removed.', icon: Icons.delete_outline_rounded);
  }

  _CalendarPlanStyle _calendarPlanStyle(String type) {
    switch (type) {
      case 'medication':
        return const _CalendarPlanStyle(
          label: 'Medicine',
          defaultTitle: 'Medication',
          icon: Icons.medication_rounded,
          color: AppTheme.accentColor,
        );
      case 'vet':
        return const _CalendarPlanStyle(
          label: 'Vet',
          defaultTitle: 'Vet visit',
          icon: Icons.medical_services_rounded,
          color: AppTheme.primaryColor,
        );
      case 'grooming':
        return const _CalendarPlanStyle(
          label: 'Groom',
          defaultTitle: 'Grooming',
          icon: Icons.content_cut_rounded,
          color: AppTheme.secondaryColor,
        );
      case 'walk':
        return const _CalendarPlanStyle(
          label: 'Walk',
          defaultTitle: 'Outdoor walk',
          icon: Icons.directions_walk_rounded,
          color: AppTheme.primaryColor,
        );
      default:
        return const _CalendarPlanStyle(
          label: 'Care',
          defaultTitle: 'Care plan',
          icon: Icons.event_available_rounded,
          color: AppTheme.primaryColor,
        );
    }
  }

  bool _isTodaySelection() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String _formattedSelectedDate() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${_selectedDate.day}${_ordinal(_selectedDate.day)} ${months[_selectedDate.month - 1]}';
  }

  String _ordinal(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}
