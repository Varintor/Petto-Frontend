import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WardrobeController extends ChangeNotifier {
  WardrobeController({Set<String> starterIds = const {'acc_collar'}})
    : _starterIds = Set<String>.of(starterIds),
      _unlockedIds = Set<String>.of(starterIds);

  final Set<String> _starterIds;
  final Set<String> _unlockedIds;
  String? _storageKey;
  int _loadGeneration = 0;

  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);

  static String storageKey({required int? userId, required int petId}) {
    final owner = userId == null ? 'guest' : 'u$userId';
    return 'petto.wardrobe.unlocked.v2.$owner.p$petId';
  }

  Future<void> load({required int? userId, required int petId}) async {
    final generation = ++_loadGeneration;
    final key = storageKey(userId: userId, petId: petId);
    _storageKey = key;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(key);
    if (generation != _loadGeneration) return;
    _unlockedIds
      ..clear()
      ..addAll(_starterIds)
      ..addAll(saved ?? const []);
    notifyListeners();
  }

  Future<bool> unlock(String accessoryId) async {
    if (!_unlockedIds.add(accessoryId)) return false;
    notifyListeners();
    await _persist();
    return true;
  }

  bool isUnlocked(String accessoryId) => _unlockedIds.contains(accessoryId);

  Future<void> _persist() async {
    final key = _storageKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, _unlockedIds.toList()..sort());
  }
}
