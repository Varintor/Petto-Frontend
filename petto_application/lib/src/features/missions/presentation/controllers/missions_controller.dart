import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/mission_model.dart';
import '../../data/repositories/missions_repository.dart';

class MissionsController extends ChangeNotifier {
  final MissionsRepository repository;

  MissionsController({required this.repository});

  /// Pet the current data belongs to. Null until a real pet id arrives —
  /// there is no seed-pet fallback (SRS-F2-018), so loads are skipped and the
  /// UI shows its empty state instead of another account's data.
  int? _petId;

  List<MissionModel> _missions = [];
  DashboardStatsModel _dashboardStats = DashboardStatsModel.empty();
  bool _missionsLoading = false;
  bool _dashboardLoading = false;
  String? _error;

  List<MissionModel> get missions => _missions;
  DashboardStatsModel get dashboardStats => _dashboardStats;
  bool get missionsLoading => _missionsLoading;
  bool get dashboardLoading => _dashboardLoading;
  String? get error => _error;

  int get completedCount => _missions.where((m) => m.isCompleted).count;
  int get totalCount => _missions.length;

  bool isMissionCompleted(int missionId) =>
      _missions.any((m) => m.id == missionId && m.isCompleted);

  Future<void> loadTodayMissions({int? petId}) async {
    final id = petId ?? _petId;
    if (id == null) {
      _missions = [];
      notifyListeners();
      return;
    }
    _petId = id;
    _missionsLoading = true;
    _error = null;
    notifyListeners();
    try {
      _missions = await repository.getTodayMissions(id);
      if (_missions.isEmpty) {
        _missions = await repository.seedTodayMissions(id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _missionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeMission(int missionId) async {
    final idx = _missions.indexWhere((m) => m.id == missionId);
    if (idx == -1 || _missions[idx].isCompleted) return;

    try {
      final updated = await repository.completeMission(missionId);
      _missions[idx] = updated;
      notifyListeners();
      unawaited(loadDashboardStats());
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadDashboardStats({int? petId}) async {
    final id = petId ?? _petId;
    if (id == null) return;
    _petId = id;
    _dashboardLoading = true;
    notifyListeners();
    try {
      _dashboardStats = await repository.getDashboardStats(id);
    } catch (_) {
      // Keep previous stats on failure
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll({int? petId}) async {
    await Future.wait([
      loadTodayMissions(petId: petId),
      loadDashboardStats(petId: petId),
    ]);
  }

  /// Wipe per-account state on logout so the next signed-in user doesn't
  /// transiently see the previous account's missions/dashboard before their
  /// own data finishes loading.
  void clearForAccount() {
    _petId = null;
    _missions = [];
    _dashboardStats = DashboardStatsModel.empty();
    _missionsLoading = false;
    _dashboardLoading = false;
    _error = null;
    notifyListeners();
  }
}

extension _IterableCount<T> on Iterable<T> {
  int get count => length;
}
