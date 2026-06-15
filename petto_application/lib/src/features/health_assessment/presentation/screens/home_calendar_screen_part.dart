part of 'home_screen.dart';

extension _HomeCalendarScreenPart on _HomeScreenState {
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
    final selectedEvents = _HomeScreenState._calendarEvents
        .where((event) => event.day == _selectedDate.day)
        .toList();
    final upcomingEvents =
        (_HomeScreenState._calendarEvents
                .where((event) => event.day >= selectedDay)
                .toList()
              ..sort((a, b) => a.day.compareTo(b.day)))
            .take(2)
            .toList();
    final visibleEvents = selectedEvents.isNotEmpty
        ? selectedEvents
        : upcomingEvents;

    return _SoftReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Calendar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  _update(() {
                    _activeView = _View.calendar;
                    _showActionMenu = false;
                    _showNavActionMenu = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _monthName(_focusedMonth.month),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: AppTheme.glassCardDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(28),
              borderColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _SquareIconButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () {
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
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.secondaryText,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            visibleEvents.isEmpty
                                ? 'No upcoming care plans'
                                : '${visibleEvents.length} care plan${visibleEvents.length == 1 ? '' : 's'} nearby',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.mutedText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SquareIconButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () {
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
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (final day in days)
                      Expanded(
                        child: _HomeCalendarDayChip(
                          date: DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month,
                            day,
                          ),
                          selected:
                              _selectedDate.year == _focusedMonth.year &&
                              _selectedDate.month == _focusedMonth.month &&
                              _selectedDate.day == day,
                          hasEvent: _HomeScreenState._calendarEvents.any(
                            (event) => event.day == day,
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
                const SizedBox(height: 14),
                if (visibleEvents.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.creamSurfaceColor.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: AppTheme.primaryColor,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'A calm day for ${_activePet.name}.',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppTheme.secondaryText),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final event in visibleEvents) ...[
                    _HomeCalendarEventTile(event: event),
                    if (event != visibleEvents.last) const SizedBox(height: 10),
                  ],
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

    final selectedEvents = _HomeScreenState._calendarEvents
        .where(
          (event) =>
              event.day == _selectedDate.day &&
              _selectedDate.month == _focusedMonth.month &&
              _selectedDate.year == _focusedMonth.year,
        )
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
                final hasEvent = _HomeScreenState._calendarEvents.any(
                  (event) => event.day == day,
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
            onAdd: () => _showPreviewSnackBar('Add Event'),
          ),
          const SizedBox(height: 12),
          if (selectedEvents.isEmpty)
            _NoPlansCard(
              petName: _activePet.name,
              onAdd: () => _showPreviewSnackBar('Add Event'),
            ),
          for (final event in selectedEvents) ...[
            _CalendarEventCard(event: event),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
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
