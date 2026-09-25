import 'package:flutter/foundation.dart';

import '../../data/models/health_history_models.dart';
import '../../data/models/public_pet_card_model.dart';
import '../../data/repositories/health_history_repository.dart';

class HealthHistoryController extends ChangeNotifier {
  final HealthHistoryRepository repository;

  HealthHistoryController({HealthHistoryRepository? repository})
    : repository = repository ?? HealthHistoryRepositoryImpl();

  int? _petId;
  List<HistoryEntryModel> _entries = [];
  HealthCardModel? _card;
  PublicPetCardModel? _publicCard;
  String? _publicCardToken;
  Set<String> _typeFilter = {};
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _loading = false;
  bool _savingProfile = false;
  bool _savingPublicCard = false;
  String? _error;

  List<HistoryEntryModel> get entries => _entries;
  HealthCardModel? get card => _card;
  PublicPetCardModel? get publicCard => _publicCard;
  String? get publicCardToken => _publicCardToken;
  int? get loadedPetId => _petId;
  Set<String> get typeFilter => _typeFilter;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  bool get loading => _loading;
  bool get savingProfile => _savingProfile;
  bool get savingPublicCard => _savingPublicCard;
  String? get error => _error;

  Future<void> load({int? petId, Set<String>? types}) async {
    final id = petId ?? _petId;
    if (id == null) {
      _entries = [];
      notifyListeners();
      return;
    }
    if (_petId != id) {
      _publicCardToken = null;
    }
    _petId = id;
    if (types != null) _typeFilter = types;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>([
        repository.getHistory(
          id,
          types: _typeFilter,
          from: _dateFrom,
          to: _dateTo,
        ),
        repository.getHealthCard(id),
        _getPublicCardSafely(id),
      ]);
      if (_petId != id) return;
      _entries = results[0] as List<HistoryEntryModel>;
      _card = results[1] as HealthCardModel;
      _publicCard = results[2] as PublicPetCardModel?;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters({
    required Set<String> types,
    DateTime? from,
    DateTime? to,
  }) async {
    _typeFilter = Set<String>.from(types);
    _dateFrom = from;
    _dateTo = to;
    final id = _petId;
    if (id == null) {
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await repository.getHistory(
        id,
        types: _typeFilter,
        from: _dateFrom,
        to: _dateTo,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<HistoryDetailModel?> getDetail(HistoryEntryModel entry) async {
    final id = _petId;
    if (id == null) return null;
    try {
      return await repository.getHistoryDetail(id, entry);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveProfile({
    required List<String> allergies,
    required List<String> chronicConditions,
    required List<String> currentMedications,
    String? notes,
  }) async {
    final id = _petId;
    if (id == null || _savingProfile) return false;
    _savingProfile = true;
    _error = null;
    notifyListeners();
    try {
      await repository.updateHealthProfile(
        id,
        allergies: allergies,
        chronicConditions: chronicConditions,
        currentMedications: currentMedications,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      );
      _card = await repository.getHealthCard(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _savingProfile = false;
      notifyListeners();
    }
  }

  Future<PublicPetCardModel?> _getPublicCardSafely(int petId) async {
    try {
      return await repository.getPublicCard(petId);
    } catch (_) {
      // Public QR/NFC sharing is optional and must never make the owner's
      // private Health Card or timeline unavailable.
      return null;
    }
  }

  Future<bool> savePublicCard({
    required Set<String> visibleFields,
    String? contactMethod,
    String? emergencyNotes,
  }) async {
    final id = _petId;
    if (id == null || _savingPublicCard || visibleFields.isEmpty) return false;
    _savingPublicCard = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await repository.savePublicCard(
        id,
        visibleFields: visibleFields,
        contactMethod: _clean(contactMethod),
        emergencyNotes: _clean(emergencyNotes),
      );
      _publicCard = saved;
      _publicCardToken = saved.token ?? _publicCardToken;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _savingPublicCard = false;
      notifyListeners();
    }
  }

  Future<bool> rotatePublicCard() async {
    final id = _petId;
    if (id == null || _savingPublicCard) return false;
    _savingPublicCard = true;
    _error = null;
    notifyListeners();
    try {
      final rotated = await repository.rotatePublicCard(id);
      _publicCard = rotated;
      _publicCardToken = rotated.token;
      return rotated.token != null;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _savingPublicCard = false;
      notifyListeners();
    }
  }

  Future<bool> revokePublicCard() async {
    final id = _petId;
    if (id == null || _savingPublicCard) return false;
    _savingPublicCard = true;
    _error = null;
    notifyListeners();
    try {
      _publicCard = await repository.revokePublicCard(id);
      _publicCardToken = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _savingPublicCard = false;
      notifyListeners();
    }
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void clearForAccount() {
    _petId = null;
    _entries = [];
    _card = null;
    _publicCard = null;
    _publicCardToken = null;
    _typeFilter = {};
    _dateFrom = null;
    _dateTo = null;
    _loading = false;
    _savingProfile = false;
    _savingPublicCard = false;
    _error = null;
    notifyListeners();
  }
}
