# Delivery Platform

A production-grade multi-service delivery platform (Porter / Swiggy / Uber / Rapido style) with:

- **User App** — Flutter (Android-first, iOS-ready)
- **Partner App** — Flutter (Android-first, iOS-ready)
- **Admin Panel + Backend API** — Next.js (TypeScript, Tailwind, shadcn/ui, Prisma) deployed on Vercel
- **Real-Time Tracking** — WebSocket / Socket.IO
- **APK Build** — GitHub Actions with Flutter SDK

## Repo Layout

```
/apps
  /user_app          Flutter — customer app
  /partner_app       Flutter — delivery partner app
  /admin_panel       Next.js — admin dashboard + backend API (Vercel)
/packages
  /shared_models     Shared TypeScript types
  /shared_constants  Shared constants
  /api_client        Typed API client (Dart + TS)
  /design_tokens     Shared design tokens
/infrastructure      IaC / config
/docs                Architecture & ADRs
/.github/workflows   CI: APK build, tests, lint
```

## Quick Start

See [`apps/admin_panel/README.md`](apps/admin_panel/README.md) for the admin panel + backend.
See [`.github/workflows/build-flutter-apk.yml`](.github/workflows/build-flutter-apk.yml) for the APK build pipeline.
