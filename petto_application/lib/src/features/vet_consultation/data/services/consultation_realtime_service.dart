import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ConsultationRealtimeGateway {
  Future<void> watch({
    required int consultationId,
    required String accessToken,
    required Future<void> Function() onMessageChanged,
    required void Function(bool connected) onConnectionChanged,
  });

  Future<void> stop();
}

/// Supabase Postgres Changes is notification-only here. REST remains the
/// authoritative read/write path, so reconnects and duplicate events are safe.
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
    required Future<void> Function() onMessageChanged,
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
          callback: (_) => onMessageChanged(),
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
