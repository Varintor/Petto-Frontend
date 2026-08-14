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
            if (controller.card != null) _PetHealthCard(controller.card!),
            const SizedBox(height: 20),
            Text(
              'Health timeline',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (controller.entries.isEmpty)
              const _HealthHistoryStateCard(
                message: 'No health records have been saved yet.',
              )
            else
              for (final entry in controller.entries)
                _HealthTimelineCard(entry),
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
}

class _PetHealthCard extends StatelessWidget {
  const _PetHealthCard(this.card);
  final HealthCardModel card;

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
        const Row(
          children: [
            Icon(Icons.pets_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'PETTO HEALTH CARD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
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
  const _HealthTimelineCard(this.entry);
  final HistoryEntryModel entry;

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
