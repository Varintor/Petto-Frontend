import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/location_service.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/activity_repository.dart';
import '../../domain/tracking_source.dart';

/// A single GPS sample reduced to the lat/lng we need for the route trace.
@immutable
class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

enum WalkState {
  idle, // not started yet
  tracking, // GPS streaming, timer running
  paused, // user paused
  finished, // stopped, awaiting save/discard
  saving, // POSTing to backend
  saved, // persisted
  error,
}

/// Drives Mode A (phone) walk tracking - the "Nike Run"-style live session.
///
/// Owns the elapsed timer, accumulated distance, current speed and the route
/// points. Persists only aggregate data (Phase 0 privacy policy) via
/// [ActivityRepository].
class ActivityTrackingController extends ChangeNotifier {
  final ActivityRepository repository;

  /// Hardware feeding this session. Defaults to the phone's GPS (Mode A);
  /// a paired BLE collar swaps in a [BleCollarTrackingSource] (Mode B) without
  /// touching the walk state machine (SRS-F4-035/036).
  final TrackingSource trackingSource;

  ActivityTrackingController({
    required this.repository,
    TrackingSource? trackingSource,
  }) : trackingSource = trackingSource ?? PhoneGpsTrackingSource();

  // ---- session state ----
  WalkState _state = WalkState.idle;
  Duration _elapsed = Duration.zero;
  double _distanceMeters = 0;
  double _currentSpeedMps = 0;
  final List<GeoPoint> _points = [];
  String? _error;

  Timer? _timer;
  StreamSubscription<TrackingSample>? _sub;
  TrackingSample? _last;

  // ---- summary/dashboard stats ----
  ActivityStatsModel _stats = ActivityStatsModel.empty();
  bool _statsLoading = false;

  /// Pet the stats belong to. Null until a real pet id arrives — no seed-pet
  /// fallback (SRS-F2-018); loads are skipped until the caller supplies one.
  int? _petId;

  // ---- getters ----
  WalkState get state => _state;
  Duration get elapsed => _elapsed;
  double get distanceMeters => _distanceMeters;
  double get currentSpeedKmh => _currentSpeedMps * 3.6;
  List<GeoPoint> get points => List.unmodifiable(_points);

  /// Latest known location, for centering the live map. Null until the first fix.
  GeoPoint? get currentPoint => _points.isEmpty ? null : _points.last;
  String? get error => _error;
  ActivityStatsModel get stats => _stats;
  bool get statsLoading => _statsLoading;

  bool get isActive =>
      _state == WalkState.tracking || _state == WalkState.paused;

  /// Average pace/speed of the current session (km/h).
  double get averageSpeedKmh {
    final hours = _elapsed.inSeconds / 3600.0;
    if (hours <= 0) return 0;
    return (_distanceMeters / 1000.0) / hours;
  }

  String get elapsedText {
    final s = _elapsed.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${two(h)}:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  String get distanceKmText => (_distanceMeters / 1000.0).toStringAsFixed(2);

  /// Walk vs run inferred from average speed (>= 6 km/h => running).
  String get inferredActivityType =>
      averageSpeedKmh >= 6 ? 'running' : 'walking';

  /// Mission rule (mirrors the "Walk for 15 mins" mission in the UI).
  bool get missionCompleted => _elapsed.inMinutes >= 15;

  // ---- lifecycle ----

  Future<void> start() async {
    _error = null;
    final notReady = await trackingSource.prepare();
    if (notReady != null) {
      _state = WalkState.error;
      _error = notReady;
      notifyListeners();
      return;
    }

    // Reset counters for a fresh session.
    _elapsed = Duration.zero;
    _distanceMeters = 0;
    _currentSpeedMps = 0;
    _points.clear();
    _last = null;

    _state = WalkState.tracking;
    notifyListeners();

    // Center the map immediately on the current location instead of waiting for
    // the stream's first movement-based update (so it shows the moment you start).
    final initial = await trackingSource.current();
    if (_state == WalkState.tracking && initial != null) {
      _last = initial;
      _points.add(GeoPoint(initial.lat, initial.lng));
      notifyListeners();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == WalkState.tracking) {
        _elapsed += const Duration(seconds: 1);
        notifyListeners();
      }
    });
    _sub = trackingSource.samples().listen(
      _onSample,
      onError: (Object e) {
        _error = 'GPS error: $e';
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void _onSample(TrackingSample sample) {
    if (_state != WalkState.tracking) return;

    _currentSpeedMps = sample.speedMps;

    if (_last != null) {
      final d = LocationService.distanceBetween(
        _last!.lat,
        _last!.lng,
        sample.lat,
        sample.lng,
      );
      // Ignore implausible jumps (GPS glitches) and noise while standing still.
      if (d.isFinite && d > 1 && d < 200) {
        _distanceMeters += d;
      }
    }

    _last = sample;
    _points.add(GeoPoint(sample.lat, sample.lng));
    notifyListeners();
  }

  void pause() {
    if (_state == WalkState.tracking) {
      _state = WalkState.paused;
      notifyListeners();
    }
  }

  void resume() {
    if (_state == WalkState.paused) {
      _state = WalkState.tracking;
      notifyListeners();
    }
  }

  /// Stop streaming/timer and move to the review (summary) state.
  void finish() {
    _timer?.cancel();
    _timer = null;
    _sub?.cancel();
    _sub = null;
    _state = WalkState.finished;
    notifyListeners();
  }

  /// Persist the finished walk as an aggregate activity.
  Future<bool> save({int? petId}) async {
    final id = petId ?? _petId;
    if (id == null) {
      // Guest session / no pet yet — nothing to attach the walk to.
      _state = WalkState.error;
      _error = 'Sign in and add a pet before saving a walk.';
      notifyListeners();
      return false;
    }
    _state = WalkState.saving;
    _error = null;
    notifyListeners();
    try {
      await repository.createActivity(
        petId: id,
        activityType: inferredActivityType,
        durationMinutes: _elapsed.inSeconds / 60.0,
        distanceMeters: _distanceMeters,
        isMissionCompleted: missionCompleted,
        source: trackingSource.sourceType,
      );
      _state = WalkState.saved;
      notifyListeners();
      // Refresh dashboard stats in the background.
      unawaited(loadStats(petId: petId));
      return true;
    } catch (e) {
      _state = WalkState.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadStats({int? petId}) async {
    final id = petId ?? _petId;
    if (id == null) return;
    _petId = id;
    _statsLoading = true;
    notifyListeners();
    try {
      _stats = await repository.getStats(id);
    } catch (_) {
      // Keep the previous/empty stats on failure; not fatal for the UI.
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  /// Clear the session so the user can start a new walk.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _sub?.cancel();
    _sub = null;
    _state = WalkState.idle;
    _elapsed = Duration.zero;
    _distanceMeters = 0;
    _currentSpeedMps = 0;
    _points.clear();
    _last = null;
    _error = null;
    notifyListeners();
  }

  /// Drop every per-account piece of state — the active walk AND the cached
  /// dashboard stats — so the next user that signs in doesn't see the
  /// previous account's totals while their own data is still loading.
  void clearForAccount() {
    reset();
    _petId = null;
    _stats = ActivityStatsModel.empty();
    _statsLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
