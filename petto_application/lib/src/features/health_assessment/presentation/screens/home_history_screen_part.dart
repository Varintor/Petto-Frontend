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
          const SizedBox(height: 18),
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
                onEdit: () =>
                    _editHealthProfile(context, controller.card!, controller),
              ),
            const SizedBox(height: 20),
            Text(
              'Health timeline',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
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
        child: Text(
          'Health Records',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      const Icon(Icons.badge_rounded, color: AppTheme.primaryColor),
    ],
  );

  Widget _buildDemoHistory(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
    children: [
      _historyHeader(context),
      const SizedBox(height: 18),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit health profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: allergies,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'Separate items with commas',
                ),
              ),
              TextField(
                controller: conditions,
                decoration: const InputDecoration(
                  labelText: 'Chronic conditions',
                  hintText: 'Separate items with commas',
                ),
              ),
              TextField(
                controller: medications,
                decoration: const InputDecoration(
                  labelText: 'Current medications',
                  hintText: 'Separate items with commas',
                ),
              ),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final item in labels.entries)
          FilterChip(
            label: Text(item.value),
            selected: controller.typeFilter.contains(item.key),
            onSelected: (_) {
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
        ActionChip(
          avatar: const Icon(Icons.date_range_rounded, size: 18),
          label: Text(dateLabel),
          onPressed: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              initialDateRange:
                  controller.dateFrom != null && controller.dateTo != null
                  ? DateTimeRange(
                      start: controller.dateFrom!,
                      end: controller.dateTo!,
                    )
                  : null,
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
          TextButton.icon(
            onPressed: () => controller.applyFilters(types: const {}),
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Clear'),
          ),
      ],
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
      return raw.toString();
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(entry.title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final field in detail.fields.entries) ...[
                  Text(
                    label(field.key),
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SelectableText(value(field.value)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PetHealthCard extends StatelessWidget {
  const _PetHealthCard(this.card, {required this.onEdit});
  final HealthCardModel card;
  final VoidCallback onEdit;

  String _value(String? value) =>
      value == null || value.trim().isEmpty ? 'Not set' : value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.primaryColor, Color(0xFF9F565A)],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pets_rounded, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'PETTO HEALTH ID',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Edit health profile',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          card.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '${_value(card.species)} • ${_value(card.breed)}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _HealthCardFact('Gender', _value(card.gender)),
            _HealthCardFact(
              'Weight',
              card.weightKg == null ? 'Not set' : '${card.weightKg} kg',
            ),
            _HealthCardFact('Blood type', _value(card.bloodType)),
          ],
        ),
        const SizedBox(height: 16),
        _HealthCardFact(
          'Allergies',
          card.allergies.isEmpty ? 'None recorded' : card.allergies.join(', '),
        ),
        const SizedBox(height: 8),
        _HealthCardFact(
          'Current medication',
          card.currentMedications.isEmpty
              ? 'None recorded'
              : card.currentMedications.join(', '),
        ),
        const SizedBox(height: 8),
        _HealthCardFact(
          'Chronic conditions',
          card.chronicConditions.isEmpty
              ? 'None recorded'
              : card.chronicConditions.join(', '),
        ),
        if (card.latestAssessment != null ||
            card.latestVaccination != null ||
            card.recentActivity != null) ...[
          const Divider(height: 24, color: Colors.white24),
          if (card.latestAssessment != null)
            _HealthCardFact(
              'Latest assessment',
              '${card.latestAssessment!.riskLevel ?? card.latestAssessment!.status ?? 'Recorded'} • ${card.latestAssessment!.title}',
            ),
          if (card.latestVaccination != null) ...[
            const SizedBox(height: 8),
            _HealthCardFact(
              'Latest vaccination',
              card.latestVaccination!.title,
            ),
          ],
          if (card.recentActivity != null) ...[
            const SizedBox(height: 8),
            _HealthCardFact('Recent activity', card.recentActivity!.title),
          ],
        ],
        if (card.profileUpdatedAt != null) ...[
          const Divider(height: 24, color: Colors.white24),
          Text(
            'Health profile updated '
            '${card.profileUpdatedAt!.day}/${card.profileUpdatedAt!.month}/${card.profileUpdatedAt!.year} '
            '${card.profileUpdatedAt!.hour.toString().padLeft(2, '0')}:'
            '${card.profileUpdatedAt!.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ],
    ),
  );
}

class _HealthCardFact extends StatelessWidget {
  const _HealthCardFact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
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

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Icon(_icon)),
      title: Text(
        entry.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(entry.summary ?? entry.status ?? 'Saved health record'),
      trailing: Text(
        '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year}',
        style: const TextStyle(fontSize: 11, color: AppTheme.mutedText),
      ),
    ),
  );
}

class _HealthHistoryStateCard extends StatelessWidget {
  const _HealthHistoryStateCard({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
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
