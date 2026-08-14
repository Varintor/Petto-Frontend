import 'package:flutter/foundation.dart';

import '../../data/models/consultation_models.dart';
import '../../data/repositories/consultation_repository.dart';

/// Feature 3 state: vet list, the active consultation, and its chat thread.
/// Backend-persisted replacement for the local-only mock chat; the consult
/// screen rewire to this controller is the Progress II UI task.
class ConsultationController extends ChangeNotifier {
  final ConsultationRepository repository;

  ConsultationController({ConsultationRepository? repository})
    : repository = repository ?? ConsultationRepositoryImpl();

  List<VetModel> _vets = [];
  List<ConsultationModel> _consultations = [];
  ConsultationModel? _active;
  List<ChatMessageModel> _messages = [];
  bool _loading = false;
  String? _error;

  List<VetModel> get vets => _vets;
  List<ConsultationModel> get consultations => _consultations;
  ConsultationModel? get active => _active;
  List<ChatMessageModel> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadVets() async {
    await _guard(() async => _vets = await repository.listVets());
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

  /// Opens (or starts) a consultation, optionally forwarding an AI assessment
  /// (UD-06). A forwarded assessment immediately gets an AI briefing posted
  /// into the chat so the vet has context before the first human message.
  Future<void> startConsultation({
    required int petId,
    required int vetId,
    int? assessmentId,
  }) async {
    await _guard(() async {
      _active = await repository.createConsultation(
        petId: petId,
        vetId: vetId,
        assessmentId: assessmentId,
      );
      if (assessmentId != null) {
        await repository.requestAiSummary(_active!.id);
      }
      _messages = await repository.listMessages(_active!.id);
    });
  }

  Future<void> openConsultation(ConsultationModel consultation) async {
    _active = consultation;
    _messages = [];
    await _guard(() async {
      final results = await Future.wait<Object?>([
        repository.listMessages(consultation.id),
        _markReadBestEffort(consultation.id),
      ]);
      // Ignore a late response if another thread was selected meanwhile.
      if (_active?.id == consultation.id) {
        _messages = results[0] as List<ChatMessageModel>;
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
    await _guard(
      () async => _messages = await repository.listMessages(active.id),
    );
  }

  Future<bool> sendMessage(String content) async {
    final active = _active;
    final text = content.trim();
    if (active == null || text.isEmpty) return false;
    try {
      final sent = await repository.sendMessage(active.id, text);
      _messages = [..._messages, sent];
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
    _consultations = [];
    _active = null;
    _messages = [];
    _loading = false;
    _error = null;
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
