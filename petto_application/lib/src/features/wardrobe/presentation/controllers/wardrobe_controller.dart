import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/wardrobe_repository.dart';

class WardrobeController extends ChangeNotifier {
  WardrobeController({
    Set<String> starterIds = const {'acc_collar'},
    WardrobeRepository? repository,
  }) : _starterIds = Set<String>.of(starterIds),
       _unlockedIds = Set<String>.of(starterIds),
       _repository = repository ?? WardrobeRepositoryImpl();

  final Set<String> _starterIds;
  final Set<String> _unlockedIds;
  final WardrobeRepository _repository;
  String? _storageKey;
  int? _petId;
  bool _useBackend = false;
  String? _equippedId;
  int _loadGeneration = 0;

  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);
  String? get equippedId => _equippedId;

  static String storageKey({required int? userId, required int petId}) {
    final owner = userId == null ? 'guest' : 'u$userId';
    return 'petto.wardrobe.unlocked.v2.$owner.p$petId';
  }

  Future<void> load({required int? userId, required int petId}) async {
    final generation = ++_loadGeneration;
    final key = storageKey(userId: userId, petId: petId);
    _storageKey = key;
    _petId = petId;
    _useBackend = userId != null;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(key);
    if (generation != _loadGeneration) return;
    _unlockedIds
      ..clear()
      ..addAll(_starterIds)
      ..addAll(saved ?? const []);
    notifyListeners();

    if (_useBackend) await _refreshFromBackend(generation);
  }

  Future<bool> unlock(String accessoryId) async {
    if (_useBackend) {
      final wasUnlocked = _unlockedIds.contains(accessoryId);
      await _refreshFromBackend(_loadGeneration);
      return !wasUnlocked && _unlockedIds.contains(accessoryId);
    }
    if (!_unlockedIds.add(accessoryId)) return false;
    notifyListeners();
    await _persist();
    return true;
  }

  bool isUnlocked(String accessoryId) => _unlockedIds.contains(accessoryId);

  Future<void> setEquipped(String? accessoryId) async {
    if (!_useBackend) {
      _equippedId = accessoryId;
      notifyListeners();
      return;
    }
    final petId = _requirePetId();
    if (accessoryId == null) {
      await _repository.unequip(petId);
    } else {
      if (!_unlockedIds.contains(accessoryId)) {
        throw StateError('Cannot equip a locked wardrobe item.');
      }
      await _repository.equip(petId, accessoryId);
    }
    _equippedId = accessoryId;
    notifyListeners();
  }

  Future<void> _refreshFromBackend(int generation) async {
    final items = await _repository.listItems(_requirePetId());
    if (generation != _loadGeneration) return;
    _unlockedIds
      ..clear()
      ..addAll(_starterIds)
      ..addAll(items.map((item) => item.accessoryId));
    _equippedId = items
        .where((item) => item.isEquipped)
        .map((item) => item.accessoryId)
        .firstOrNull;
    notifyListeners();
    await _persist();
  }

  int _requirePetId() {
    final petId = _petId;
    if (petId == null) throw StateError('Wardrobe has not been loaded.');
    return petId;
  }

  Future<void> _persist() async {
    final key = _storageKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, _unlockedIds.toList()..sort());
  }
}
