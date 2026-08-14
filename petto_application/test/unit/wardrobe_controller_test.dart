import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petto_application/src/features/wardrobe/data/wardrobe_repository.dart';
import 'package:petto_application/src/features/wardrobe/presentation/controllers/wardrobe_controller.dart';

class _FakeWardrobeRepository implements WardrobeRepository {
  _FakeWardrobeRepository(this.items);

  final List<WardrobeItemData> items;
  int? listedPetId;
  String? equippedAccessoryId;
  int? unequippedPetId;

  @override
  Future<List<WardrobeItemData>> listItems(int petId) async {
    listedPetId = petId;
    return List.of(items);
  }

  @override
  Future<void> equip(int petId, String accessoryId) async {
    equippedAccessoryId = accessoryId;
  }

  @override
  Future<void> unequip(int petId) async {
    unequippedPetId = petId;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists unlocks per user and pet', () async {
    final controller = WardrobeController();
    await controller.load(userId: null, petId: 21);
    expect(controller.isUnlocked('acc_collar'), true);
    expect(await controller.unlock('acc_hat'), true);
    expect(await controller.unlock('acc_hat'), false);

    final sameScope = WardrobeController();
    await sameScope.load(userId: null, petId: 21);
    expect(sameScope.isUnlocked('acc_hat'), true);

    final otherPet = WardrobeController();
    await otherPet.load(userId: null, petId: 22);
    expect(otherPet.isUnlocked('acc_hat'), false);
    expect(otherPet.isUnlocked('acc_collar'), true);
  });

  test('authenticated wardrobe uses backend unlocks and equipment', () async {
    final repository = _FakeWardrobeRepository([
      const WardrobeItemData(accessoryId: 'acc_hat', isEquipped: true),
    ]);
    final controller = WardrobeController(repository: repository);

    await controller.load(userId: 4, petId: 21);
    expect(repository.listedPetId, 21);
    expect(controller.isUnlocked('acc_hat'), true);
    expect(controller.equippedId, 'acc_hat');

    await controller.setEquipped('acc_hat');
    expect(repository.equippedAccessoryId, 'acc_hat');

    await controller.setEquipped(null);
    expect(repository.unequippedPetId, 21);
    expect(controller.equippedId, isNull);
  });
}
