import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/consultation_models.dart';
import '../../data/repositories/consultation_repository.dart';

/// Feature 3 state: vet list, the active consultation, and its chat thread.
/// Backend-persisted replacement for the local-only mock chat; the consult
/// screen rewire to this controller is the Progress II UI task.
class ConsultationController extends ChangeNotifier {
  final ConsultationRepository repository;
  final HealthCardSharingRepository? healthCardRepository;

  ConsultationController({
    ConsultationRepository? repository,
    HealthCardSharingRepository? healthCardRepository,
  }) : repository = repository ?? ConsultationRepositoryImpl(),
       healthCardRepository =
           healthCardRepository ??
           (repository == null ? HealthCardSharingRepositoryImpl() : null);

  List<VetModel> _vets = [];
  List<VeterinaryProviderModel> _providers = [];
  List<VetModel> _providerVets = [];
  List<ConsultationModel> _consultations = [];
  ConsultationModel? _active;
  List<ChatMessageModel> _messages = [];
  List<AppointmentModel> _appointments = [];
  List<SharedHealthCardModel> _sharedHealthCards = [];
  bool _sharingHealthCard = false;
  bool _loading = false;
  bool _refreshingMessages = false;
  String? _error;
  String? _retryContent;
  String? _retryClientMessageId;

  List<VetModel> get vets => _vets;
  List<VeterinaryProviderModel> get providers => _providers;
  List<VetModel> get providerVets => _providerVets;
  List<ConsultationModel> get consultations => _consultations;
  ConsultationModel? get active => _active;
  List<ChatMessageModel> get messages => _messages;
  List<AppointmentModel> get appointments => _appointments;
  List<SharedHealthCardModel> get sharedHealthCards => _sharedHealthCards;
  bool get sharingHealthCard => _sharingHealthCard;
  bool get loading => _loading;
  bool get refreshingMessages => _refreshingMessages;
  String? get error => _error;

  Future<void> loadVets() async {
    await _guard(() async => _vets = await repository.listVets());
  }

  Future<void> loadProviders({double? latitude, double? longitude}) async {
    await _guard(
      () async => _providers = await repository.listProviders(
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  Future<void> loadProviderVets(int providerId) async {
    await _guard(
      () async => _providerVets = await repository.listProviderVets(providerId),
    );
  }

  Future<void> loadConsultations(int petId) async {
    await _guard(
      () async => _consultations = await repository.listPetConsultations(petId),
    );
  }

  Future<void> loadVetConsultations() async {
    await _guard(
      () async => _consultations = await repository.listVetConsultations(),
    );
  }

  Future<void> loadOwnerWorkspace(int petId) async {
    await _guard(() async {
      final results = await Future.wait<Object?>([
        repository.listVets(),
        repository.listPetConsultations(petId),
        repository.listProviders(),
      ]);
      _vets = results[0] as List<VetModel>;
      _consultations = results[1] as List<ConsultationModel>;
      _providers = results[2] as List<VeterinaryProviderModel>;
    });
  }

  /// Opens (or starts) a consultation, optionally forwarding an AI assessment
  /// (UD-06). A forwarded assessment immediately gets an AI briefing posted
  /// into the chat so the vet has context before the first human message.
  Future<void> startConsultation({
    required int petId,
    required int vetId,
    int? providerId,
    int? assessmentId,
  }) async {
    await _guard(() async {
      _active = await repository.createConsultation(
        petId: petId,
        vetId: vetId,
        providerId: providerId,
        assessmentId: assessmentId,
      );
      _consultations = [
        _active!,
        ..._consultations.where((item) => item.id != _active!.id),
      ];
      if (assessmentId != null) {
        try {
          await repository.requestAiSummary(_active!.id);
        } catch (_) {
          // The consultation is already created and the assessment is shared.
          // A failed AI briefing must not strand the owner outside the chat.
        }
      }
      final results = await Future.wait<Object?>([
        repository.listMessages(_active!.id),
        repository.listAppointments(_active!.id),
        if (healthCardRepository != null)
          healthCardRepository!.listSharedHealthCards(_active!.id),
      ]);
      _messages = results[0] as List<ChatMessageModel>;
      _appointments = results[1] as List<AppointmentModel>;
      _sharedHealthCards = healthCardRepository == null
          ? []
          : results[2] as List<SharedHealthCardModel>;
    });
  }

  Future<void> openConsultation(ConsultationModel consultation) async {
    _active = consultation;
    _messages = [];
    _appointments = [];
    _sharedHealthCards = [];
    await _guard(() async {
      final results = await Future.wait<Object?>([
        repository.listMessages(consultation.id),
        repository.listAppointments(consultation.id),
        _markReadBestEffort(consultation.id),
        if (healthCardRepository != null)
          healthCardRepository!.listSharedHealthCards(consultation.id),
      ]);
      // Ignore a late response if another thread was selected meanwhile.
      if (_active?.id == consultation.id) {
        _messages = results[0] as List<ChatMessageModel>;
        _appointments = results[1] as List<AppointmentModel>;
        _sharedHealthCards = healthCardRepository == null
            ? []
            : results[3] as List<SharedHealthCardModel>;
      }
    });
  }

  Future<void> _markReadBestEffort(int consultationId) async {
    try {
      await repository.markMessagesRead(consultationId);
    } catch (_) {
      // Read receipts must not block opening a consultation thread.
    }
  }

  Future<void> refreshMessages() async {
    final active = _active;
    if (active == null) return;
    await _guard(() async {
      final results = await Future.wait<Object?>([
        repository.listMessages(active.id),
        repository.listAppointments(active.id),
        if (healthCardRepository != null)
          healthCardRepository!.listSharedHealthCards(active.id),
      ]);
      _messages = results[0] as List<ChatMessageModel>;
      _appointments = results[1] as List<AppointmentModel>;
      if (healthCardRepository != null) {
        _sharedHealthCards = results[2] as List<SharedHealthCardModel>;
      }
    });
  }

  Future<void> refreshNewMessages() async {
    final active = _active;
    if (active == null || _refreshingMessages) return;
    _refreshingMessages = true;
    try {
      final afterId = _messages.isEmpty ? null : _messages.last.id;
      final results = await Future.wait<Object?>([
        repository.listMessages(active.id, afterId: afterId),
        repository.listAppointments(active.id),
        if (healthCardRepository != null)
          healthCardRepository!.listSharedHealthCards(active.id),
      ]);
      final incoming = results[0] as List<ChatMessageModel>;
      final appointments = results[1] as List<AppointmentModel>;
      if (_active?.id != active.id) return;
      final knownIds = _messages.map((message) => message.id).toSet();
      _messages = [
        ..._messages,
        ...incoming.where((message) => knownIds.add(message.id)),
      ];
      _appointments = appointments;
      if (healthCardRepository != null) {
        _sharedHealthCards = results[2] as List<SharedHealthCardModel>;
      }
      notifyListeners();
      if (incoming.isNotEmpty) await _markReadBestEffort(active.id);
    } catch (_) {
      // Background refresh is best-effort. The explicit refresh action still
      // reports errors through [_guard].
    } finally {
      _refreshingMessages = false;
    }
  }

  Future<bool> shareAssessment(int assessmentId) async {
    final active = _active;
    if (active == null) return false;
    try {
      await repository.shareAssessment(active.id, assessmentId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void closeActiveConsultation() {
    _active = null;
    _messages = [];
    _appointments = [];
    _sharedHealthCards = [];
    _error = null;
    notifyListeners();
  }

  Future<bool> sendMessage(String content) async {
    final active = _active;
    final text = content.trim();
    if (active == null || text.isEmpty) return false;
    final clientMessageId = _retryContent == text
        ? _retryClientMessageId ?? const Uuid().v4()
        : const Uuid().v4();
    try {
      final sent = await repository.sendMessage(
        active.id,
        text,
        clientMessageId: clientMessageId,
      );
      _messages = [..._messages, sent];
      _retryContent = null;
      _retryClientMessageId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _retryContent = text;
      _retryClientMessageId = clientMessageId;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> shareHealthCard() async {
    final active = _active;
    final repo = healthCardRepository;
    if (active == null || repo == null || _sharingHealthCard) return false;
    _sharingHealthCard = true;
    _error = null;
    notifyListeners();
    try {
      final shared = await repo.shareHealthCard(active.id);
      _sharedHealthCards = [
        shared,
        ..._sharedHealthCards.where((item) => item.id != shared.id),
      ];
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _sharingHealthCard = false;
      notifyListeners();
    }
  }

  Future<bool> revokeHealthCard(int sharedCardId) async {
    final active = _active;
    final repo = healthCardRepository;
    if (active == null || repo == null) return false;
    try {
      await repo.revokeHealthCard(active.id, sharedCardId);
      _sharedHealthCards = _sharedHealthCards
          .where((item) => item.id != sharedCardId)
          .toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> proposeAppointment({
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  }) async {
    final active = _active;
    if (active == null) return false;
    try {
      final created = await repository.proposeAppointment(
        active.id,
        startsAt: startsAt,
        endsAt: endsAt,
        reason: reason,
      );
      _appointments = [
        created,
        ..._appointments.where((item) => item.id != created.id),
      ];
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> decideAppointment(int appointmentId, String decision) async {
    if (decision != 'accepted' && decision != 'declined') return false;
    try {
      final updated = await repository.decideAppointment(
        appointmentId,
        decision,
      );
      _appointments = _appointments
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearForAccount() {
    _vets = [];
    _providers = [];
    _providerVets = [];
    _consultations = [];
    _active = null;
    _messages = [];
    _appointments = [];
    _loading = false;
    _refreshingMessages = false;
    _error = null;
    _retryContent = null;
    _retryClientMessageId = null;
    notifyListeners();
  }

  Future<void> _guard(Future<void> Function() body) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await body();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
