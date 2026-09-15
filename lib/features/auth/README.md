# Auth Module

Folder layout:

```text
auth/
  data/
    services/           API-calling classes (Dio), TokenStorage, error/log helpers
    dto/                Request/response wire models for every Auth endpoint
  presentation/
    notifiers/          Riverpod Notifiers — own screen UI state (loading, field errors)
    controllers/        Plain Dart controllers — orchestrate a service call + side effects
                         (AuthStateManager, ProfileIdentityService, TokenStorage)
    screens/            One screen per flow
    widgets/            Auth-only reusable widgets
  validators/           Form validation (signup fields, phone numbers)
```

Dependency flow for every flow:

```
Screen → Notifier (Riverpod) → Controller (plain Dart) → Service (Dio) → DTO → API endpoint
```

Production rules:

- Do not log passwords, OTPs, tokens, full headers, or full response bodies.
- Notifiers own visible loading/field-error state; screens read it via `ref.watch`.
- Controllers are plain Dart (no Flutter/Riverpod imports) and return an immutable
  `XResult` value object, so they can be unit tested without widgets.
- Services use `AuthApiException` for user-facing errors.
- `TokenStorage` stays under `auth/data/services/` even though it's consumed by many
  other features — Auth is its conceptual owner.
- Edit Profile (fetch/update `user/edit_profile`) is a Profile-feature concern and lives
  under `features/profile/`, not here.
