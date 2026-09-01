part of 'home_screen.dart';

extension _HomeHistoryScreenPart on _HomeScreenState {
  Widget _buildHistoryView(BuildContext context) {
    final auth = context.read<AuthController>();
    if (auth.isGuest) return _buildDemoHistory(context);

    final controller = context.watch<HealthHistoryController>();
    final petId = _activePet.id;
    if (controller.loadedPetId != petId && !controller.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.load(petId: petId);
      });
    }

    return RefreshIndicator(
      onRefresh: () => controller.load(petId: petId),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
        children: [
          _historyHeader(context),
          const SizedBox(height: 20),
          if (controller.loading && controller.card == null)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.error != null && controller.card == null)
            _HealthHistoryStateCard(
              message: controller.error!,
              onRetry: () => controller.load(petId: petId),
            )
          else ...[
            if (controller.card != null)
              _PetHealthCard(
                controller.card!,
                appearance: _activeAppearance,
                onEdit: () =>
                    _editHealthProfile(context, controller.card!, controller),
              ),
            const SizedBox(height: 26),
            _HealthSectionHeading(
              title: 'Health timeline',
              subtitle: 'A bright little journal for every care moment.',
              icon: Icons.history_rounded,
            ),
            const SizedBox(height: 14),
            _historyFilters(context, controller),
            if (controller.loading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 10),
            if (controller.entries.isEmpty)
              const _HealthHistoryStateCard(
                message: 'No health records have been saved yet.',
              )
            else
              for (final entry in controller.entries)
                _HealthTimelineCard(
                  entry,
                  onTap: () => _showHistoryDetail(context, controller, entry),
                ),
          ],
        ],
      ),
    );
  }

  Widget _historyHeader(BuildContext context) => Row(
    children: [
      _SquareIconButton(
        icon: Icons.arrow_back_rounded,
        onTap: () => _update(() => _activeView = _View.profile),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Records',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 3),
            Text(
              'A clear view of ${_activePet.name}\'s care journey.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.blushSurfaceColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.badge_rounded, color: AppTheme.primaryColor),
      ),
    ],
  );

  Widget _buildDemoHistory(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
    children: [
      _historyHeader(context),
      const SizedBox(height: 20),
      _PetHealthCard(
        HealthCardModel(
          petId: _activePet.id,
          name: _activePet.name,
          species: _activePet.species,
          breed: _activePet.breed,
          gender: _activePet.gender ?? 'Male',
          dateOfBirth: _activePet.dateOfBirth,
          weightKg: _activePet.weightKg ?? 4.5,
          bloodType: _activePet.bloodType ?? 'DEA 1.1',
          allergies: const ['None recorded'],
          currentMedications: const [],
          chronicConditions: const [],
        ),
        appearance: _activeAppearance,
        onEdit: () {},
      ),
      const SizedBox(height: 26),
      const _HealthSectionHeading(
        title: 'Health timeline',
        subtitle: 'A bright little journal for every care moment.',
        icon: Icons.history_rounded,
      ),
      const SizedBox(height: 14),
      for (final item in _HomeScreenState._history) ...[
        _HistoryDetailCard(item: item),
        const SizedBox(height: 14),
      ],
    ],
  );

  Future<void> _editHealthProfile(
    BuildContext context,
    HealthCardModel card,
    HealthHistoryController controller,
  ) async {
    final allergies = TextEditingController(text: card.allergies.join(', '));
    final conditions = TextEditingController(
      text: card.chronicConditions.join(', '),
    );
    final medications = TextEditingController(
      text: card.currentMedications.join(', '),
    );
    final notes = TextEditingController(text: card.notes ?? '');
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _HealthEditDialog(
        allergies: allergies,
        conditions: conditions,
        medications: medications,
        notes: notes,
      ),
    );
    List<String> items(String value) => value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (shouldSave == true && context.mounted) {
      final saved = await controller.saveProfile(
        allergies: items(allergies.text),
        chronicConditions: items(conditions.text),
        currentMedications: items(medications.text),
        notes: notes.text,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? 'Health profile updated.'
                  : 'Could not update health profile.',
            ),
          ),
        );
      }
    }
    allergies.dispose();
    conditions.dispose();
    medications.dispose();
    notes.dispose();
  }

  Widget _historyFilters(
    BuildContext context,
    HealthHistoryController controller,
  ) {
    const labels = {
      'assessment': 'Assessments',
      'activity': 'Activity',
      'vaccination': 'Vaccinations',
      'mission': 'Care',
      'appointment': 'Appointments',
    };
    final hasDateRange =
        controller.dateFrom != null || controller.dateTo != null;
    String shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
    final dateLabel = controller.dateFrom != null && controller.dateTo != null
        ? '${shortDate(controller.dateFrom!)} – ${shortDate(controller.dateTo!)}'
        : 'Date range';
    final pills = <Widget>[
      for (final item in labels.entries)
        _HistoryFilterPill(
          label: item.value,
          icon: switch (item.key) {
            'assessment' => Icons.auto_awesome_rounded,
            'activity' => Icons.directions_walk_rounded,
            'vaccination' => Icons.vaccines_rounded,
            'appointment' => Icons.event_rounded,
            _ => Icons.favorite_rounded,
          },
          selected: controller.typeFilter.contains(item.key),
          accent: switch (item.key) {
            'activity' => const Color(0xFF7E8E62),
            'vaccination' => const Color(0xFFC59A35),
            'mission' => const Color(0xFFB66770),
            'appointment' => const Color(0xFF9F6B56),
            _ => AppTheme.primaryColor,
          },
          onTap: () {
            final updated = Set<String>.from(controller.typeFilter);
            updated.contains(item.key)
                ? updated.remove(item.key)
                : updated.add(item.key);
            controller.applyFilters(
              types: updated,
              from: controller.dateFrom,
              to: controller.dateTo,
            );
          },
        ),
      _HistoryFilterPill(
        label: dateLabel,
        icon: Icons.date_range_rounded,
        selected: hasDateRange,
        accent: AppTheme.primaryColor,
        onTap: () async {
          final range = await showDialog<DateTimeRange?>(
            context: context,
            builder: (_) => _HealthDateRangeDialog(
              initialStart: controller.dateFrom,
              initialEnd: controller.dateTo,
            ),
          );
          if (range == null) return;
          await controller.applyFilters(
            types: controller.typeFilter,
            from: range.start,
            to: range.end,
          );
        },
      ),
      if (controller.typeFilter.isNotEmpty || hasDateRange)
        _HistoryFilterPill(
          label: 'Clear',
          icon: Icons.filter_alt_off_rounded,
          selected: false,
          accent: AppTheme.primaryColor,
          onTap: () => controller.applyFilters(types: const {}),
        ),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => Center(child: pills[index]),
      ),
    );
  }

  Future<void> _showHistoryDetail(
    BuildContext context,
    HealthHistoryController controller,
    HistoryEntryModel entry,
  ) async {
    final detail = await controller.getDetail(entry);
    if (!context.mounted) return;
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load this health record.')),
      );
      return;
    }
    String label(String key) => key
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
    String value(dynamic raw) {
      if (raw == null || raw.toString().trim().isEmpty) return 'Not set';
      final text = raw.toString();
      final parsed = DateTime.tryParse(text);
      if (parsed == null) return text;
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
      final local = parsed.toLocal();
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute';
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _HealthRecordDetailDialog(
        title: entry.title,
        type: entry.type,
        fields: [
          for (final field in detail.fields.entries)
            MapEntry(label(field.key), value(field.value)),
        ],
      ),
    );
  }
}

class _HealthEditDialog extends StatelessWidget {
  const _HealthEditDialog({
    required this.allergies,
    required this.conditions,
    required this.medications,
    required this.notes,
  });

  final TextEditingController allergies;
  final TextEditingController conditions;
  final TextEditingController medications;
  final TextEditingController notes;

  static const _rose = Color(0xFFC45C68);
  static const _gold = Color(0xFFC89A35);
  static const _olive = Color(0xFF7F8F62);
  static const _clay = Color(0xFFA56A56);

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    backgroundColor: Colors.transparent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFEFB), Color(0xFFFFF5ED)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HealthDialogHeader(
                icon: Icons.medical_information_rounded,
                title: 'Edit health profile',
                subtitle: 'Update care notes for the clinic record.',
                accent: _rose,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _HealthEditField(
                      controller: allergies,
                      icon: Icons.favorite_rounded,
                      hint: 'Allergies',
                      accent: _rose,
                      surface: const Color(0xFFFFE9EC),
                    ),
                    const SizedBox(height: 9),
                    _HealthEditField(
                      controller: conditions,
                      icon: Icons.health_and_safety_rounded,
                      hint: 'Chronic conditions',
                      accent: _olive,
                      surface: const Color(0xFFF0F3E2),
                    ),
                    const SizedBox(height: 9),
                    _HealthEditField(
                      controller: medications,
                      icon: Icons.medication_rounded,
                      hint: 'Current medications',
                      accent: _gold,
                      surface: const Color(0xFFFFF3D4),
                    ),
                    const SizedBox(height: 9),
                    _HealthEditField(
                      controller: notes,
                      icon: Icons.notes_rounded,
                      hint: 'Notes',
                      maxLines: 3,
                      accent: _clay,
                      surface: const Color(0xFFF8E8DE),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.16),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HealthDateRangeDialog extends StatefulWidget {
  const _HealthDateRangeDialog({this.initialStart, this.initialEnd});

  final DateTime? initialStart;
  final DateTime? initialEnd;

  @override
  State<_HealthDateRangeDialog> createState() => _HealthDateRangeDialogState();
}

class _HealthDateRangeDialogState extends State<_HealthDateRangeDialog> {
  static final DateTime _firstDate = DateTime(2020);
  static final DateTime _lastDate = DateTime.now().add(
    const Duration(days: 730),
  );

  late DateTime? _start = widget.initialStart;
  late DateTime? _end = widget.initialEnd;
  bool _editingStart = true;

  DateTime get _visibleDate => _editingStart
      ? (_start ?? DateTime.now())
      : (_end ?? _start ?? DateTime.now());

  String _label(DateTime? date) {
    if (date == null) return 'Select';
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _pick(DateTime date) {
    setState(() {
      if (_editingStart) {
        _start = date;
        if (_end != null && _end!.isBefore(date)) _end = null;
        _editingStart = false;
      } else {
        _end = date.isBefore(_start ?? date) ? _start : date;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
    backgroundColor: Colors.transparent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFEFB), Color(0xFFFFF6EE)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.13),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HealthDialogHeader(
              icon: Icons.date_range_rounded,
              title: 'Select range',
              subtitle: 'Filter your pet care journal.',
              accent: const Color(0xFFC89A35),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _RangePickTab(
                    label: 'Start',
                    value: _label(_start),
                    selected: _editingStart,
                    onTap: () => setState(() => _editingStart = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RangePickTab(
                    label: 'End',
                    value: _label(_end),
                    selected: !_editingStart,
                    onTap: () => setState(() => _editingStart = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: const Color(0xFFFFF7F1),
                    onSurface: AppTheme.secondaryText,
                  ),
                ),
                child: CalendarDatePicker(
                  key: ValueKey(_editingStart),
                  initialDate: _visibleDate.isBefore(_firstDate)
                      ? _firstDate
                      : _visibleDate.isAfter(_lastDate)
                      ? _lastDate
                      : _visibleDate,
                  firstDate: _firstDate,
                  lastDate: _lastDate,
                  currentDate: _editingStart ? _start : _end,
                  onDateChanged: _pick,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _start == null || _end == null
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pop(DateTimeRange(start: _start!, end: _end!)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.28,
                      ),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _RangePickTab extends StatelessWidget {
  const _RangePickTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, Color(0xFFC45C68)],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.primaryColor.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (selected ? AppTheme.primaryColor : const Color(0xFFC45C68))
                      .withValues(alpha: selected ? 0.11 : 0.035),
              blurRadius: selected ? 12 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? const Color(0xFFFFE1DC) : AppTheme.mutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : AppTheme.secondaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HealthEditField extends StatelessWidget {
  const _HealthEditField({
    required this.controller,
    required this.icon,
    required this.hint,
    required this.accent,
    required this.surface,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final Color accent;
  final Color surface;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: AppTheme.secondaryText,
      fontWeight: FontWeight.w700,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.mutedText,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 11, right: 7),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
          child: Icon(icon, color: accent, size: 18),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 54),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: maxLines > 1 ? 18 : 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: accent, width: 1.4),
      ),
    ),
  );
}

class _HealthDialogHeader extends StatelessWidget {
  const _HealthDialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = AppTheme.primaryColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.primaryColor, accent],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.14),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFFE1DC),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HealthRecordDetailDialog extends StatelessWidget {
  const _HealthRecordDetailDialog({
    required this.title,
    required this.type,
    required this.fields,
  });

  final String title;
  final String type;
  final List<MapEntry<String, String>> fields;

  IconData get _icon => switch (type) {
    'assessment' => Icons.auto_awesome_rounded,
    'activity' => Icons.directions_walk_rounded,
    'vaccination' => Icons.vaccines_rounded,
    'appointment' => Icons.event_rounded,
    _ => Icons.flag_rounded,
  };

  String get _typeLabel => switch (type) {
    'assessment' => 'AI assessment',
    'activity' => 'Activity record',
    'vaccination' => 'Vaccination',
    'appointment' => 'Appointment',
    'mission' => 'Care mission',
    _ => 'Health record',
  };

  Color get _accent => switch (type) {
    'activity' => const Color(0xFF7F8F62),
    'vaccination' => const Color(0xFFC89A35),
    'mission' => const Color(0xFFC45C68),
    'appointment' => const Color(0xFFA56A56),
    _ => const Color(0xFFC45C68),
  };

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    backgroundColor: Colors.transparent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFEFB), Color(0xFFFFF6EE)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.13),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HealthRecordHero(
                icon: _icon,
                title: title,
                typeLabel: _typeLabel,
                accent: _accent,
              ),
              const SizedBox(height: 14),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 440 ? 2 : 1;
                      final tileWidth =
                          (constraints.maxWidth - (columns == 2 ? 10 : 0)) /
                          columns;
                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var index = 0; index < fields.length; index++)
                              SizedBox(
                                width: tileWidth,
                                child: _HealthRecordFieldTile(
                                  label: fields[index].key,
                                  value: fields[index].value,
                                  index: index,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Saved record',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: _accent,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HealthRecordHero extends StatelessWidget {
  const _HealthRecordHero({
    required this.icon,
    required this.title,
    required this.typeLabel,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String typeLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.primaryColor, accent],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.14),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFFFE7E3),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HealthRecordFieldTile extends StatelessWidget {
  const _HealthRecordFieldTile({
    required this.label,
    required this.value,
    required this.index,
  });

  final String label;
  final String value;
  final int index;

  static const _accents = [
    Color(0xFFC45C68),
    Color(0xFFC89A35),
    Color(0xFF7F8F62),
    Color(0xFFA56A56),
    AppTheme.primaryColor,
  ];

  Color get _accent => _accents[index % _accents.length];
  Color get _surface => _accent.withValues(alpha: 0.12);

  IconData get _icon {
    final normalized = label.toLowerCase();
    if (normalized.contains('start') || normalized.contains('created')) {
      return Icons.play_circle_rounded;
    }
    if (normalized.contains('end') || normalized.contains('updated')) {
      return Icons.schedule_rounded;
    }
    if (normalized.contains('reason')) return Icons.notes_rounded;
    if (normalized.contains('status')) return Icons.verified_rounded;
    if (normalized.contains('provider')) return Icons.local_hospital_rounded;
    return Icons.info_rounded;
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _accent.withValues(alpha: 0.10)),
      boxShadow: [
        BoxShadow(
          color: _accent.withValues(alpha: 0.035),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(_icon, color: _accent, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w700,
                  height: 1.22,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PetHealthCard extends StatelessWidget {
  const _PetHealthCard(
    this.card, {
    required this.appearance,
    required this.onEdit,
  });

  final HealthCardModel card;
  final _PetAppearanceData appearance;
  final VoidCallback onEdit;

  String _value(String? value) =>
      value == null || value.trim().isEmpty ? 'Not set' : value;

  String get _healthId => 'PT-${card.petId.toString().padLeft(5, '0')}';

  String _birthdayLabel(DateTime? date) {
    if (date == null) return 'Not set';
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const designWidth = 680.0;
      const designHeight = designWidth / 1.58;
      final cardWidth = math.min(constraints.maxWidth, designWidth);
      return Center(
        child: SizedBox(
          width: cardWidth,
          child: AspectRatio(
            aspectRatio: 1.58,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: designWidth,
                height: designHeight,
                child: _HealthIdCardCanvas(
                  card: card,
                  appearance: appearance,
                  healthId: _healthId,
                  birthday: _birthdayLabel(card.dateOfBirth),
                  value: _value,
                  onEdit: onEdit,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _HealthIdCardCanvas extends StatelessWidget {
  const _HealthIdCardCanvas({
    required this.card,
    required this.appearance,
    required this.healthId,
    required this.birthday,
    required this.value,
    required this.onEdit,
  });

  final HealthCardModel card;
  final _PetAppearanceData appearance;
  final String healthId;
  final String birthday;
  final String Function(String?) value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFFFFAF5),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: AppTheme.primaryColor.withValues(alpha: 0.22),
        width: 1.6,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.09),
          blurRadius: 24,
          offset: const Offset(0, 11),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(width: 226, color: AppTheme.primaryColor),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 182,
                child: _HealthCardPortrait(card: card, appearance: appearance),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 2),
                  child: _HealthCardInformation(
                    card: card,
                    healthId: healthId,
                    birthday: birthday,
                    value: value,
                    onEdit: onEdit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HealthCardPortrait extends StatelessWidget {
  const _HealthCardPortrait({required this.card, required this.appearance});

  final HealthCardModel card;
  final _PetAppearanceData appearance;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 7),
          const Flexible(
            child: Text(
              'PET HEALTH',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.25,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 13),
      Container(
        width: 180,
        height: 180,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF401619).withValues(alpha: 0.24),
              blurRadius: 17,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: PetAvatarWidget(
          species: appearance.species,
          color: _healthCardColor(appearance.colorHex),
          eyeType: appearance.eyeType,
          mouthType: appearance.mouthType,
          pattern: appearance.pattern,
          equipped: appearance.equipped.toList(growable: false),
          headOnly: true,
        ),
      ),
      const SizedBox(height: 13),
      SizedBox(
        width: double.infinity,
        child: Text(
          card.name,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: 35,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        width: double.infinity,
        child: Text(
          '${card.species ?? 'Pet'}  •  ${card.breed ?? 'Breed not set'}',
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFFF6DAD7),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 13),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'ACTIVE PROFILE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _HealthCardInformation extends StatelessWidget {
  const _HealthCardInformation({
    required this.card,
    required this.healthId,
    required this.birthday,
    required this.value,
    required this.onEdit,
  });

  final HealthCardModel card;
  final String healthId;
  final String birthday;
  final String Function(String?) value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7E9E4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.health_and_safety_rounded,
                    color: AppTheme.primaryColor,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'HEALTH DETAILS',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              healthId,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Material(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onEdit,
              child: const SizedBox(
                width: 45,
                height: 45,
                child: Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 13),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _HealthCardFact(
                        icon: Icons.cake_rounded,
                        label: 'Birthday',
                        value: birthday,
                        accent: const Color(0xFFC95C74),
                        surface: const Color(0xFFFFEEF2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HealthCardFact(
                        icon: Icons.monitor_weight_rounded,
                        label: 'Weight',
                        value: card.weightKg == null
                            ? 'Not set'
                            : '${card.weightKg} kg',
                        accent: const Color(0xFFC49A37),
                        surface: const Color(0xFFFFF5D8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _HealthCardFact(
                        icon: Icons.wc_rounded,
                        label: 'Gender',
                        value: value(card.gender),
                        accent: const Color(0xFF9E5962),
                        surface: const Color(0xFFF8E5E4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HealthCardFact(
                        icon: Icons.bloodtype_rounded,
                        label: 'Blood type',
                        value: value(card.bloodType),
                        accent: AppTheme.primaryColor,
                        surface: const Color(0xFFF1DCDC),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 11),
      _HealthCareRibbon(card: card),
    ],
  );
}

class _HealthCareRibbon extends StatelessWidget {
  const _HealthCareRibbon({required this.card});

  final HealthCardModel card;

  int get _noteCount =>
      card.allergies.length +
      card.currentMedications.length +
      card.chronicConditions.length;

  @override
  Widget build(BuildContext context) => Container(
    height: 72,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.14),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            Icons.medical_information_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CARE STATUS',
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFFFDAD7),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _noteCount == 0
                    ? 'No active health notes'
                    : '$_noteCount health ${_noteCount == 1 ? 'note' : 'notes'} on file',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            _noteCount == 0 ? 'CLEAR' : 'REVIEW',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ),
      ],
    ),
  );
}

Color _healthCardColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16);
  return value == null ? AppTheme.primaryColor : Color(0xFF000000 | value);
}

class _HealthCardFact extends StatelessWidget {
  const _HealthCardFact({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.surface,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color surface;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: accent.withValues(alpha: 0.16)),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.secondaryText,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoryFilterPill extends StatelessWidget {
  const _HistoryFilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(7, 6, 12, 6),
        decoration: BoxDecoration(
          color: selected ? accent : const Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : accent.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: selected ? 0.13 : 0.035),
              blurRadius: selected ? 10 : 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : accent.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : accent,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? Colors.white : AppTheme.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HealthSectionHeading extends StatelessWidget {
  const _HealthSectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 5,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      const SizedBox(width: 11),
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.13),
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _HealthTimelineCard extends StatelessWidget {
  const _HealthTimelineCard(this.entry, {required this.onTap});
  final HistoryEntryModel entry;
  final VoidCallback onTap;

  IconData get _icon => switch (entry.type) {
    'assessment' => Icons.auto_awesome_rounded,
    'activity' => Icons.directions_walk_rounded,
    'vaccination' => Icons.vaccines_rounded,
    'appointment' => Icons.event_rounded,
    _ => Icons.flag_rounded,
  };

  Color get _tint => switch (entry.type) {
    'assessment' => AppTheme.primaryColor,
    'activity' => const Color(0xFF7E8E62),
    'vaccination' => const Color(0xFFC59A35),
    'mission' => const Color(0xFFB66770),
    'appointment' => const Color(0xFF9F6B56),
    _ => AppTheme.primaryColor,
  };

  Color get _softTint => switch (entry.type) {
    'assessment' => const Color(0xFFF3E4E2),
    'activity' => const Color(0xFFF0F2E4),
    'vaccination' => const Color(0xFFFFF3D4),
    'mission' => const Color(0xFFFFE8EA),
    'appointment' => const Color(0xFFF7E8DE),
    _ => const Color(0xFFF3E4E2),
  };

  String get _typeLabel => switch (entry.type) {
    'assessment' => 'AI CHECK',
    'activity' => 'ACTIVITY',
    'vaccination' => 'VACCINE',
    'mission' => 'CARE',
    'appointment' => 'VISIT',
    _ => 'RECORD',
  };

  String? get _statusLabel {
    final raw = entry.riskLevel ?? entry.status;
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim().toUpperCase();
  }

  String get _dayLabel => entry.timestamp.day.toString().padLeft(2, '0');

  String get _dateLabel {
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
    return '$_dayLabel ${months[entry.timestamp.month - 1]}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: _tint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFFCF8),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _tint.withValues(alpha: 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(_icon, color: Colors.white, size: 15),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _tint.withValues(alpha: 0.16),
                      width: 1.15,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 66,
                        decoration: BoxDecoration(
                          color: _tint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _TimelineMetaPill(
                                  label: _typeLabel,
                                  color: _tint,
                                  background: _softTint,
                                  letterSpacing: 0.32,
                                ),
                                _TimelineMetaPill(
                                  label: _dateLabel,
                                  color: AppTheme.secondaryText,
                                  background: const Color(0xFFF8F0EC),
                                ),
                                if (_statusLabel != null)
                                  _TimelineMetaPill(
                                    label: _statusLabel!,
                                    color: _tint,
                                    background: _softTint.withValues(
                                      alpha: 0.72,
                                    ),
                                    letterSpacing: 0.28,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.secondaryText,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    height: 1.08,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              entry.summary ??
                                  entry.status ??
                                  'Saved health record',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.mutedText,
                                    height: 1.22,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 9),
                      Container(
                        width: 33,
                        height: 33,
                        decoration: BoxDecoration(
                          color: _softTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: _tint,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TimelineMetaPill extends StatelessWidget {
  const _TimelineMetaPill({
    required this.label,
    required this.color,
    required this.background,
    this.letterSpacing = 0.18,
  });

  final String label;
  final Color color;
  final Color background;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: letterSpacing,
      ),
    ),
  );
}

class _HealthHistoryStateCard extends StatelessWidget {
  const _HealthHistoryStateCard({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.10)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.blushSurfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    ),
  );
}
