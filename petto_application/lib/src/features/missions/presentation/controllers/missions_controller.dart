import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../data/models/mission_model.dart';
import '../../data/repositories/missions_repository.dart';

class MissionsController extends ChangeNotifier {
  final MissionsRepository repository;

  MissionsController({required this.repository});

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
    _missionsLoading = true;
    _error = null;
    notifyListeners();
    try {
      _missions =
          await repository.getTodayMissions(petId ?? AppConfig.defaultPetId);
      if (_missions.isEmpty) {
        _missions = await repository
            .seedTodayMissions(petId ?? AppConfig.defaultPetId);
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
    _dashboardLoading = true;
    notifyListeners();
    try {
      _dashboardStats = await repository
          .getDashboardStats(petId ?? AppConfig.defaultPetId);
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
