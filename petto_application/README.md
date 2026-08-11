# Petto application

The Flutter client uses the Petto staging environment by default. Production is
kept isolated until the project passes staging verification.

## Environment configuration

The default staging endpoints are centralized in
`lib/src/core/config/app_config.dart`. A different environment can be selected
without modifying source code:

```powershell
flutter run `
  --dart-define=APP_ENV=production `
  --dart-define=API_BASE_URL=https://api.example.com `
  --dart-define=SUPABASE_URL=https://project.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Only a Supabase publishable key may be included in the client. Never pass a
service-role key, database password, or Gemini key to Flutter.

For local Android emulator development, override `API_BASE_URL` with
`http://10.0.2.2:8000`. Use `http://localhost:8000` for Flutter web or an iOS
simulator running on the same machine.
