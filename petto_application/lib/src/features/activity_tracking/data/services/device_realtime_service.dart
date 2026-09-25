import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceRealtimeService {
  DeviceRealtimeService({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;
  RealtimeChannel? _channel;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  Future<void> subscribe({
    required int petId,
    required List<int> deviceIds,
    required Future<void> Function() reconcile,
    void Function(Map<String, dynamic>)? onDevice,
    void Function(Map<String, dynamic>)? onAlert,
    void Function(Map<String, dynamic>)? onTelemetry,
  }) async {
    await close();
    var connectedOnce = false;
    var channel = client.channel('pet-tracking-$petId');
    channel = channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'devices',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'pet_id',
        value: petId,
      ),
      callback: (payload) {
        if (payload.newRecord.isNotEmpty && onDevice != null) {
          onDevice(payload.newRecord);
        } else {
          reconcile();
        }
      },
    );
    for (final id in deviceIds) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'device_alerts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'device_id',
          value: id,
        ),
        callback: (payload) {
          if (payload.newRecord.isNotEmpty && onAlert != null) {
            onAlert(payload.newRecord);
          } else {
            reconcile();
          }
        },
      );
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'device_telemetry_points',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'device_id',
          value: id,
        ),
        callback: (payload) {
          if (payload.newRecord.isNotEmpty && onTelemetry != null) {
            onTelemetry(payload.newRecord);
          }
        },
      );
    }
    _channel = channel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (connectedOnce) reconcile();
        connectedOnce = true;
      }
    });
  }

  Future<void> close() async {
    final old = _channel;
    _channel = null;
    if (old != null) await client.removeChannel(old);
  }
}
