# User App — Flutter

Customer-facing app for the Delivery Platform.

## Tech
- Flutter 3.22+ / Dart 3.4+
- Riverpod (state) · GoRouter (nav) · Dio (HTTP) · Freezed (models)
- Secure storage · Google Maps · Geolocator · Socket.IO
- Material 3 · flutter_animate

## Build APK locally
```bash
cd apps/user_app
flutter pub get
flutter run           # dev
flutter build apk --release
```

## APK Build via GitHub Actions
Push to `main` (or any branch) triggers `.github/workflows/build-flutter-apk.yml`,
which builds both `user_app` and `partner_app` APKs and uploads them as artifacts.

## Environment
Copy `.env.example` to `.env` and set:
- `API_BASE_URL` — backend URL (the Vercel deployment)
- `API_KEY` — X-API-Key for backend auth
- `GOOGLE_MAPS_API_KEY` — for maps SDK
