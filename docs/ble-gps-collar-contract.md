# Petto BLE/GPS collar prototype contract

This contract lets the mobile app, simulator, and future collar firmware evolve
independently. Update the UUIDs and packet parser only after hardware selection.

## Transport

- BLE GATT service UUID: `f0a00001-0451-4000-b000-000000000001`
- Telemetry characteristic UUID: `f0a00002-0451-4000-b000-000000000001`
- Characteristic properties: notify required; read optional.
- Encoding: one UTF-8 JSON object per notification.
- Recommended interval while moving: 2-5 seconds.
- Recommended interval while stationary: 15-60 seconds.

## Packet

```json
{
  "lat": 18.796143,
  "lng": 98.979263,
  "speed_kmh": 3.4,
  "accuracy_m": 6.0,
  "battery": 82,
  "recorded_at": "2026-09-23T10:30:00+07:00"
}
```

Required fields: `lat`, `lng`.

Optional fields: `speed_kmh`, `accuracy_m`, `battery`, `recorded_at`. The app
uses receipt time when `recorded_at` is absent. Coordinates outside valid ranges
are rejected.

## Application and backend behavior

- The app batches samples for about two seconds before upload to protect the
  backend connection pool.
- Precise route points are retained for seven days.
- Supabase Realtime publishes new telemetry to the pet owner only through RLS.
- The 24-hour summary caps gaps and ignores sub-meter jitter or implausible
  position jumps when calculating distance.
- Qualifying activity can complete the Walk Mission, but one session identifier
  must not create duplicate activity records.

## Hardware acceptance

Before replacing the simulator, verify reconnect, power-cycle recovery, packet
fragmentation, out-of-order timestamps, low battery, indoor GPS loss, BLE range,
background behavior, and at least a 30-minute outdoor route.

