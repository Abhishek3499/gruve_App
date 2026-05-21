# Auth Module

Clean architecture entrypoints for new code:

```text
auth/
  core/                 Shared auth logging and error helpers
  data/
    models/             Barrel exports for API models
    services/           Barrel exports for API services
  presentation/
    controllers/        Barrel exports for screen controllers
    screens/            Barrel exports for auth screens
  validators/           Form validation
  widgets/              Auth-only UI widgets
  storage/              Token/session storage target
```

The older `api/controllers`, `api/models`, `api/services`, and `screens`
folders are kept for compatibility. New imports should prefer the barrel files
under `data/` and `presentation/` while the module is migrated gradually.

Production rules:

- Do not log passwords, OTPs, tokens, full headers, or full response bodies.
- Screens own visible loading state; services return data or throw.
- Auth screens use `AuthUiProvider` for loading, field errors, signup choices,
  OTP progress, and complete-profile image preview. Avoid local `setState` for
  auth form state.
- Services use `AuthApiException` for user-facing errors.
- Keep the video background, but share one controller and avoid per-screen video
  reinitialization.
