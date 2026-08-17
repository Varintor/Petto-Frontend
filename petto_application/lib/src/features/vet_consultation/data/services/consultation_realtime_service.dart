import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ConsultationRealtimeGateway {
  Future<void> watch({
    required int consultationId,
    required String accessToken,
    required Future<void> Function(Map<String, dynamic> record)
    onMessageChanged,
    required void Function(bool connected) onConnectionChanged,
  });

  Future<void> stop();
}

/// Delivers the Postgres Changes row immediately for a responsive chat UI.
/// REST remains the authoritative reconciliation path, so reconnects,
/// incomplete payloads, and duplicate events remain safe.
class SupabaseConsultationRealtimeGateway
    implements ConsultationRealtimeGateway {
  SupabaseConsultationRealtimeGateway({SupabaseClient? client})
    : _client = client;

  final SupabaseClient? _client;
  RealtimeChannel? _channel;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  @override
  Future<void> watch({
    required int consultationId,
    required String accessToken,
    required Future<void> Function(Map<String, dynamic> record)
    onMessageChanged,
    required void Function(bool connected) onConnectionChanged,
  }) async {
    await stop();
    if (accessToken.isEmpty) {
      onConnectionChanged(false);
      return;
    }

    await _supabase.realtime.setAuth(accessToken);
    final channel = _supabase
        .channel('consultation-$consultationId-messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'consultation_id',
            value: consultationId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty) {
              unawaited(onMessageChanged(record));
            }
          },
        );
    _channel = channel;
    channel.subscribe((status, _) {
      if (_channel != channel) return;
      onConnectionChanged(status == RealtimeSubscribeStatus.subscribed);
    });
  }

  @override
  Future<void> stop() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) await _supabase.removeChannel(channel);
  }
}
