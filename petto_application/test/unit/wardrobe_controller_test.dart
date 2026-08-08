import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petto_application/src/features/wardrobe/presentation/controllers/wardrobe_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists unlocks per user and pet', () async {
    final controller = WardrobeController();
    await controller.load(userId: 4, petId: 21);
    expect(controller.isUnlocked('acc_collar'), true);
    expect(await controller.unlock('acc_hat'), true);
    expect(await controller.unlock('acc_hat'), false);

    final sameScope = WardrobeController();
    await sameScope.load(userId: 4, petId: 21);
    expect(sameScope.isUnlocked('acc_hat'), true);

    final otherPet = WardrobeController();
    await otherPet.load(userId: 4, petId: 22);
    expect(otherPet.isUnlocked('acc_hat'), false);
    expect(otherPet.isUnlocked('acc_collar'), true);
  });
}
