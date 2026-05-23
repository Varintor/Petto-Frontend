part of 'home_screen.dart';

extension _HomeCalendarScreenPart on _HomeScreenState {
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthName(_focusedMonth.month),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_focusedMonth.year} Events',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 18),
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
            decoration: AppTheme.glassCardDecoration(),
            padding: const EdgeInsets.all(10),
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
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: selected ? 42 : (isToday ? 38 : 34),
                          height: selected ? 42 : (isToday ? 38 : 34),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFF9E8B)
                                : isToday
                                ? const Color(0xFFFFF3EE)
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
                              width: isToday ? 1.4 : 0,
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
          const SizedBox(height: 24),
          _SectionTitle(
            title: _isTodaySelection()
                ? "Today's Schedule"
                : _formattedSelectedDate(),
            actionLabel: 'Add Event',
            onAction: () => _showPreviewSnackBar('Add Event'),
          ),
          const SizedBox(height: 12),
          if (selectedEvents.isEmpty)
            Container(
              decoration: AppTheme.glassCardDecoration(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No plans for this day',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
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
