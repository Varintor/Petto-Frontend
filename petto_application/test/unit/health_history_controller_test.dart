import 'package:flutter_test/flutter_test.dart';

import 'package:petto_application/src/features/health_history/health_history.dart';

class _FakeHistoryRepository implements HealthHistoryRepository {
  List<String> savedAllergies = const [];
  Set<String>? requestedTypes;
  DateTime? requestedFrom;
  DateTime? requestedTo;

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
  }) async {
    requestedTypes = types;
    requestedFrom = from;
    requestedTo = to;
    return [
      HistoryEntryModel(
        type: 'assessment',
        refId: 3,
        timestamp: DateTime(2026, 8, 14),
        title: 'AI Health Check',
        status: 'completed',
      ),
    ];
  }

  @override
  Future<HistoryDetailModel> getHistoryDetail(
    int petId,
    HistoryEntryModel entry,
  ) async => HistoryDetailModel(
    type: entry.type,
    refId: entry.refId,
    fields: const {'symptom_description': 'Lethargic', 'status': 'completed'},
  );

  @override
  Future<HealthProfileModel> updateHealthProfile(
    int petId, {
    required List<String> allergies,
    required List<String> chronicConditions,
    required List<String> currentMedications,
    String? notes,
  }) async {
    savedAllergies = allergies;
    return HealthProfileModel(
      petId: petId,
      allergies: allergies,
      chronicConditions: chronicConditions,
      currentMedications: currentMedications,
      notes: notes,
    );
  }
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

  test('saves an owner health profile and refreshes the health card', () async {
    final repository = _FakeHistoryRepository();
    final controller = HealthHistoryController(repository: repository);
    await controller.load(petId: 9);

    final saved = await controller.saveProfile(
      allergies: const ['Pollen'],
      chronicConditions: const ['Atopy'],
      currentMedications: const ['Cetirizine'],
      notes: 'Review monthly',
    );

    expect(saved, isTrue);
    expect(repository.savedAllergies, ['Pollen']);
    expect(controller.savingProfile, isFalse);
    expect(controller.error, isNull);
  });

  test('applies type and date filters to the timeline request', () async {
    final repository = _FakeHistoryRepository();
    final controller = HealthHistoryController(repository: repository);
    await controller.load(petId: 9);
    final from = DateTime(2026, 7, 1);
    final to = DateTime(2026, 7, 31);

    await controller.applyFilters(
      types: const {'assessment', 'vaccination'},
      from: from,
      to: to,
    );

    expect(repository.requestedTypes, {'assessment', 'vaccination'});
    expect(repository.requestedFrom, from);
    expect(repository.requestedTo, to);
    expect(controller.dateFrom, from);
    expect(controller.dateTo, to);
  });

  test('loads complete source details for a timeline entry', () async {
    final controller = HealthHistoryController(
      repository: _FakeHistoryRepository(),
    );
    await controller.load(petId: 9);

    final detail = await controller.getDetail(controller.entries.single);

    expect(detail?.type, 'assessment');
    expect(detail?.fields['symptom_description'], 'Lethargic');
  });
}
