import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/consultation_models.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../data/services/consultation_realtime_service.dart';

/// Feature 3 state: vet list, the active consultation, and its chat thread.
/// Backend-persisted replacement for the local-only mock chat; the consult
/// screen rewire to this controller is the Progress II UI task.
class ConsultationController extends ChangeNotifier {
  final ConsultationRepository repository;
  final HealthCardSharingRepository? healthCardRepository;
  final ConsultationRealtimeGateway realtimeGateway;

  ConsultationController({
    ConsultationRepository? repository,
    HealthCardSharingRepository? healthCardRepository,
    ConsultationRealtimeGateway? realtimeGateway,
  }) : repository = repository ?? ConsultationRepositoryImpl(),
       healthCardRepository =
           healthCardRepository ??
           (repository == null ? HealthCardSharingRepositoryImpl() : null),
       realtimeGateway =
           realtimeGateway ?? SupabaseConsultationRealtimeGateway();

  List<VetModel> _vets = [];
  List<VeterinaryProviderModel> _providers = [];
  List<VetModel> _providerVets = [];
  List<ConsultationModel> _consultations = [];
  ConsultationModel? _active;
  List<ChatMessageModel> _messages = [];
  List<AppointmentModel> _appointments = [];
  List<SharedAssessmentModel> _sharedAssessments = [];
  List<SharedHealthCardModel> _sharedHealthCards = [];
  bool _sharingHealthCard = false;
  bool _loading = false;
  bool _refreshingMessages = false;
  bool _messagesRefreshPending = false;
  bool _refreshingAppointments = false;
  bool _appointmentsRefreshPending = false;
  bool _refreshingSharedAssessments = false;
  bool _sharedAssessmentsRefreshPending = false;
  bool _refreshingSharedHealthCards = false;
  bool _sharedHealthCardsRefreshPending = false;
  bool _realtimeConnected = false;
  bool _hasRealtimeSubscribed = false;
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
  List<SharedAssessmentModel> get sharedAssessments => _sharedAssessments;
  List<SharedHealthCardModel> get sharedHealthCards => _sharedHealthCards;
  bool get sharingHealthCard => _sharingHealthCard;
  bool get loading => _loading;
  bool get refreshingMessages => _refreshingMessages;
  bool get realtimeConnected => _realtimeConnected;
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
    bool urgent = false,
    String? realtimeAccessToken,
  }) async {
    await realtimeGateway.stop();
    _realtimeConnected = false;
    _hasRealtimeSubscribed = false;
    await _guard(() async {
      _active = await repository.createConsultation(
        petId: petId,
        vetId: vetId,
        providerId: providerId,
        assessmentId: assessmentId,
        subject: urgent ? 'Urgent Help' : null,
        priority: urgent ? 'urgent' : 'normal',
        urgentHelpAcknowledged: urgent,
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
        repository.listSharedAssessments(_active!.id),
        if (healthCardRepository != null)
          healthCardRepository!.listSharedHealthCards(_active!.id),
      ]);
      _messages = results[0] as List<ChatMessageModel>;
      _appointments = results[1] as List<AppointmentModel>;
      _sharedAssessments = results[2] as List<SharedAssessmentModel>;
      _sharedHealthCards = healthCardRepository == null
          ? []
          : results[3] as List<SharedHealthCardModel>;
    });
    await _watchActiveConsultation(realtimeAccessToken);
  }

  Future<void> openConsultation(
    ConsultationModel consultation, {
    String? realtimeAccessToken,
  }) async {
    await realtimeGateway.stop();
    _realtimeConnected = false;
    _hasRealtimeSubscribed = false;
    _active = consultation;
    _messages = [];
    _appointments = [];
    _sharedAssessments = [];
    _sharedHealthCards = [];
    // A read receipt is best-effort and must never delay rendering the thread.
    unawaited(_markReadBestEffort(consultation.id));
    await _guard(() async {
      final results = await Future.wait<Object?>([
        repository.listMessages(consultation.id),
        repository.listAppointments(consultation.id),
        repository.listSharedAssessments(consultation.id),
        if (healthCardRepository != null)
          healthCardRepository!.listSharedHealthCards(consultation.id),
      ]);
      // Ignore a late response if another thread was selected meanwhile.
      if (_active?.id == consultation.id) {
        _messages = results[0] as List<ChatMessageModel>;
        _appointments = results[1] as List<AppointmentModel>;
        _sharedAssessments = results[2] as List<SharedAssessmentModel>;
        _sharedHealthCards = healthCardRepository == null
            ? []
            : results[3] as List<SharedHealthCardModel>;
      }
    });
    await _watchActiveConsultation(realtimeAccessToken);
  }

  Future<void> _watchActiveConsultation(String? accessToken) async {
    final consultation = _active;
    if (consultation == null || accessToken == null || accessToken.isEmpty) {
      _setRealtimeConnected(false);
      return;
    }
    try {
      await realtimeGateway.watch(
        consultationId: consultation.id,
        accessToken: accessToken,
        onMessageChanged: _applyRealtimeMessage,
        onAppointmentsChanged: _refreshAppointmentsFromRealtime,
        onSharedAssessmentsChanged: _refreshSharedAssessmentsFromRealtime,
        onSharedHealthCardsChanged: _refreshSharedHealthCardsFromRealtime,
        onConnectionChanged: _setRealtimeConnected,
      );
    } catch (_) {
      _setRealtimeConnected(false);
    }
  }

  void _setRealtimeConnected(bool connected) {
    final wasConnected = _realtimeConnected;
    if (wasConnected == connected) return;
    _realtimeConnected = connected;
    if (connected) {
      if (_hasRealtimeSubscribed && !wasConnected) {
        // Supabase reconnects its socket automatically. Reconcile once after
        // reconnect so rows created during the outage cannot be missed.
        unawaited(_reconcileConversationFromRealtime());
      }
      _hasRealtimeSubscribed = true;
    }
    notifyListeners();
  }

  /// Applies the row carried by Supabase Realtime before performing a REST
  /// reconciliation. This keeps chat delivery responsive while retaining the
  /// backend as the authoritative source after reconnects or partial events.
  Future<void> _applyRealtimeMessage(Map<String, dynamic> record) async {
    final active = _active;
    if (active == null) return;

    ChatMessageModel message;
    try {
      message = ChatMessageModel.fromJson(record);
    } catch (_) {
      unawaited(_refreshMessagesFromRealtime());
      return;
    }
    if (message.consultationId != active.id || _active?.id != active.id) return;

    final existingIndex = _messages.indexWhere((item) => item.id == message.id);
    final isNewMessage = existingIndex == -1;
    if (isNewMessage) {
      _messages = [..._messages, message]..sort((a, b) => a.id.compareTo(b.id));
    } else {
      _messages = List<ChatMessageModel>.of(_messages)
        ..[existingIndex] = message
        ..sort((a, b) => a.id.compareTo(b.id));
    }
    notifyListeners();

    if (isNewMessage) unawaited(_markReadBestEffort(active.id));
  }

  Future<void> _refreshMessagesFromRealtime() async {
    final active = _active;
    if (active == null) return;
    _messagesRefreshPending = true;
    if (_refreshingMessages) return;
    _refreshingMessages = true;
    try {
      while (_messagesRefreshPending && _active?.id == active.id) {
        _messagesRefreshPending = false;
        final latest = await repository.listMessages(active.id);
        if (_active?.id != active.id) return;
        final knownIds = _messages.map((message) => message.id).toSet();
        final hasNewMessage = latest.any(
          (message) => !knownIds.contains(message.id),
        );
        _messages = latest;
        notifyListeners();
        if (hasNewMessage) await _markReadBestEffort(active.id);
      }
    } catch (_) {
      // Realtime will continue reconnecting. The user can also request an
      // explicit refresh; no periodic REST polling is performed.
    } finally {
      _refreshingMessages = false;
    }
  }

  Future<void> _reconcileConversationFromRealtime() async {
    await Future.wait<void>([
      _refreshMessagesFromRealtime(),
      _refreshAppointmentsFromRealtime(),
      _refreshSharedAssessmentsFromRealtime(),
      _refreshSharedHealthCardsFromRealtime(),
    ]);
  }

  Future<void> _refreshAppointmentsFromRealtime() async {
    final active = _active;
    if (active == null) return;
    _appointmentsRefreshPending = true;
    if (_refreshingAppointments) return;
    _refreshingAppointments = true;
    try {
      while (_appointmentsRefreshPending && _active?.id == active.id) {
        _appointmentsRefreshPending = false;
        final latest = await repository.listAppointments(active.id);
        if (_active?.id != active.id) return;
        _appointments = latest;
        notifyListeners();
      }
    } catch (_) {
      // The next database event, reconnect, or manual refresh will retry.
    } finally {
      _refreshingAppointments = false;
    }
  }

  Future<void> _refreshSharedAssessmentsFromRealtime() async {
    final active = _active;
    if (active == null) return;
    _sharedAssessmentsRefreshPending = true;
    if (_refreshingSharedAssessments) return;
    _refreshingSharedAssessments = true;
    try {
      while (_sharedAssessmentsRefreshPending && _active?.id == active.id) {
        _sharedAssessmentsRefreshPending = false;
        final latest = await repository.listSharedAssessments(active.id);
        if (_active?.id != active.id) return;
        _sharedAssessments = latest;
        notifyListeners();
      }
    } catch (_) {
      // The next database event, reconnect, or manual refresh will retry.
    } finally {
      _refreshingSharedAssessments = false;
    }
  }

  Future<void> _refreshSharedHealthCardsFromRealtime() async {
    final active = _active;
    final repo = healthCardRepository;
    if (active == null || repo == null) return;
    _sharedHealthCardsRefreshPending = true;
    if (_refreshingSharedHealthCards) return;
    _refreshingSharedHealthCards = true;
    try {
      while (_sharedHealthCardsRefreshPending && _active?.id == active.id) {
        _sharedHealthCardsRefreshPending = false;
        final latest = await repo.listSharedHealthCards(active.id);
        if (_active?.id != active.id) return;
        _sharedHealthCards = latest;
        notifyListeners();
      }
    } catch (_) {
      // The next database event, reconnect, or manual refresh will retry.
    } finally {
      _refreshingSharedHealthCards = false;
    }
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
        repository.listSharedAssessments(active.id),
        if (healthCardRepository != null)
          healthCardRepository!.listSharedHealthCards(active.id),
      ]);
      _messages = results[0] as List<ChatMessageModel>;
      _appointments = results[1] as List<AppointmentModel>;
      _sharedAssessments = results[2] as List<SharedAssessmentModel>;
      if (healthCardRepository != null) {
        _sharedHealthCards = results[3] as List<SharedHealthCardModel>;
      }
    });
  }

  Future<bool> shareAssessment(int assessmentId) async {
    final active = _active;
    if (active == null) return false;
    try {
      await repository.shareAssessment(active.id, assessmentId);
      _sharedAssessments = await repository.listSharedAssessments(active.id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.describeError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> revokeAssessment(int assessmentId) async {
    final active = _active;
    if (active == null) return false;
    try {
      await repository.revokeAssessment(active.id, assessmentId);
      _sharedAssessments = _sharedAssessments
          .where((item) => item.assessmentId != assessmentId)
          .toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.describeError(e);
      notifyListeners();
      return false;
    }
  }

  void closeActiveConsultation() {
    unawaited(realtimeGateway.stop());
    _realtimeConnected = false;
    _hasRealtimeSubscribed = false;
    _active = null;
    _messages = [];
    _appointments = [];
    _sharedAssessments = [];
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
      _messages = [..._messages.where((message) => message.id != sent.id), sent]
        ..sort((a, b) => a.id.compareTo(b.id));
      _retryContent = null;
      _retryClientMessageId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _retryContent = text;
      _retryClientMessageId = clientMessageId;
      _error = ApiClient.describeError(e);
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
      _error = ApiClient.describeError(e);
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
      _error = ApiClient.describeError(e);
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
      _error = ApiClient.describeError(e);
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
      _error = ApiClient.describeError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAppointment(
    int appointmentId, {
    required DateTime startsAt,
    DateTime? endsAt,
    String? reason,
  }) async {
    try {
      final updated = await repository.updateAppointment(
        appointmentId,
        startsAt: startsAt,
        endsAt: endsAt,
        reason: reason,
      );
      _replaceAppointment(updated);
      return true;
    } catch (e) {
      _error = ApiClient.describeError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelAppointment(int appointmentId) async {
    try {
      final updated = await repository.cancelAppointment(appointmentId);
      _replaceAppointment(updated);
      return true;
    } catch (e) {
      _error = ApiClient.describeError(e);
      notifyListeners();
      return false;
    }
  }

  void _replaceAppointment(AppointmentModel updated) {
    _appointments = _appointments
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    _error = null;
    notifyListeners();
  }

  void clearForAccount() {
    _vets = [];
    _providers = [];
    _providerVets = [];
    _consultations = [];
    _active = null;
    _messages = [];
    _appointments = [];
    _sharedAssessments = [];
    _loading = false;
    _refreshingMessages = false;
    _messagesRefreshPending = false;
    _refreshingAppointments = false;
    _appointmentsRefreshPending = false;
    _refreshingSharedAssessments = false;
    _sharedAssessmentsRefreshPending = false;
    _refreshingSharedHealthCards = false;
    _sharedHealthCardsRefreshPending = false;
    _realtimeConnected = false;
    _hasRealtimeSubscribed = false;
    unawaited(realtimeGateway.stop());
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
      _error = ApiClient.describeError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(realtimeGateway.stop());
    super.dispose();
  }
}
