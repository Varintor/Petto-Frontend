import 'package:flutter_test/flutter_test.dart';

import 'package:petto_application/src/features/health_history/health_history.dart';

class _FakeHistoryRepository implements HealthHistoryRepository {
  @override
  Future<HealthCardModel> getHealthCard(int petId) async => HealthCardModel(
    petId: petId,
    name: 'Milo',
    species: 'Cat',
    allergies: const ['Chicken'],
  );

  @override
  Future<List<HistoryEntryModel>> getHistory(
    int petId, {
    Set<String>? types,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async => [
    HistoryEntryModel(
      type: 'assessment',
      refId: 3,
      timestamp: DateTime(2026, 8, 14),
      title: 'AI Health Check',
      status: 'completed',
    ),
  ];
}

void main() {
  test('loads a pet health card and unified timeline together', () async {
    final controller = HealthHistoryController(
      repository: _FakeHistoryRepository(),
    );

    await controller.load(petId: 9);

    expect(controller.loadedPetId, 9);
    expect(controller.card?.name, 'Milo');
    expect(controller.card?.allergies, ['Chicken']);
    expect(controller.entries.single.type, 'assessment');
    expect(controller.error, isNull);
  });
}
