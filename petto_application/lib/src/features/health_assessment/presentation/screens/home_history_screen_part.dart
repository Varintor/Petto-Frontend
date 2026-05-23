part of 'home_screen.dart';

extension _HomeHistoryScreenPart on _HomeScreenState {
  Widget _buildHistoryView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SquareIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  _update(() {
                    _activeView = _View.profile;
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Health Records',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: AppTheme.glassCardDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final item in _HomeScreenState._history) ...[
            _HistoryDetailCard(item: item),
            const SizedBox(height: 14),
          ],
          Container(
            decoration: AppTheme.glassCardDecoration(
              color: Colors.white.withValues(alpha: 0.42),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'End of Records',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
