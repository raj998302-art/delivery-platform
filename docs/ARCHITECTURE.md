# Architecture

## High-Level Topology

```
┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
│   User App (Flutter) │   │ Partner App (Flutter)│   │  Admin Panel (Web)  │
│   Android-first      │   │   Android-first      │   │  Next.js + Tailwind  │
└──────────┬───────────┘   └──────────┬───────────┘   └──────────┬──────────┘
           │                          │                          │
           │     HTTPS / WebSocket    │                          │
           └──────────────┬───────────┘                          │
                          │                                      │
                          ▼                                      ▼
            ┌─────────────────────────────────────────────────────────┐
            │  Vercel — Next.js (admin_panel + backend API routes)     │
            │  - /api/auth     /api/orders     /api/partners           │
            │  - /api/users    /api/services   /api/pricing/quote      │
            │  - /api/tracking /api/dispatch   /api/analytics          │
            └─────────────────────────────┬───────────────────────────┘
                                          │
                       ┌──────────────────┼──────────────────┐
                       │                  │                  │
                       ▼                  ▼                  ▼
            ┌──────────────┐   ┌──────────────┐    ┌─────────────────┐
            │ PostgreSQL   │   │ Redis        │    │ External APIs   │
            │ + PostGIS    │   │ (BullMQ,     │    │ - MSG91/Twilio  │
            │ (Prisma ORM) │   │  geospatial) │    │ - Razorpay      │
            │              │   │              │    │ - Google Maps   │
            │              │   │              │    │ - FCM           │
            └──────────────┘   └──────────────┘    └─────────────────┘
```

## Repository Layout

```
apps/
  user_app/          Flutter — customer app (Riverpod, GoRouter, Dio, Freezed)
  partner_app/       Flutter — delivery partner app
  admin_panel/       Next.js 14 — admin dashboard + backend API
packages/
  shared_models/     (placeholder for future shared TS types)
  shared_constants/  (placeholder)
  api_client/        (placeholder — typed API client)
  design_tokens/     (placeholder)
infrastructure/      (placeholder for IaC — Terraform / Pulumi)
docs/                Architecture & ADRs
.github/workflows/
  build-flutter-apk.yml   CI: builds both Flutter APKs, uploads as artifacts
```

## Backend Architecture — Modular Monolith

The backend is a **modular monolith** — all logical services share one Next.js
deployment and one Prisma schema, but each has its own table set and its own
`/api/<domain>` route prefix. This makes future microservice extraction
straightforward without paying the operational cost of microservices on day one.

| Module          | Tables (key)                                              | API Routes                     |
|-----------------|-----------------------------------------------------------|--------------------------------|
| Auth            | users, refresh_tokens, otp_requests, admin_users          | /api/auth/*                    |
| User            | users, user_profiles, user_addresses                      | /api/users                     |
| Partner         | partners, partner_profiles, partner_documents, vehicles   | /api/partners                  |
| Order           | orders, order_items, order_status_history, locations      | /api/orders                    |
| Dispatch        | partner_assignments                                       | /api/dispatch                  |
| Pricing         | pricing_rules, fare_quotes, surge_rules, service_zones    | /api/pricing/quote             |
| Tracking        | tracking_sessions, location_updates                       | /api/tracking                  |
| Payment         | payments                                                  | (integrate Razorpay next)      |
| Wallet          | wallets, wallet_transactions, withdrawal_requests         | (TBD)                          |
| Notification    | notifications                                             | (TBD)                          |
| Support         | support_tickets, support_messages                         | (TBD)                          |
| Admin           | admin_users, audit_logs                                   | /api/auth/login                |
| Analytics       | (read model over orders, users, partners)                 | /api/analytics                 |
| Settings        | settings, feature_flags                                   | /api/services                  |

## Order State Machine

Strict transitions enforced by the backend (`src/lib/order-state.ts`):

```
DRAFT → QUOTE_CREATED → PAYMENT_PENDING → CONFIRMED → SEARCHING_PARTNER
  → PARTNER_ASSIGNED → PARTNER_ACCEPTED → PARTNER_ARRIVING → PARTNER_ARRIVED
  → PICKUP_VERIFICATION → PICKED_UP → IN_TRANSIT → ARRIVING
  → DELIVERY_VERIFICATION → DELIVERED → COMPLETED

CANCELLED / FAILED / REFUNDED are terminal states reachable from various points.
```

Invalid transitions are rejected with `400 Bad Request`.

## Pricing Engine

`src/lib/pricing.ts` — backend-authoritative. The Flutter apps request a quote
via `POST /api/pricing/quote` and receive a signed `quoteId` that expires in
10 minutes. The client never computes prices.

```
total = baseFare × vehicleMultiplier
      + perKm × distanceKm × vehicleMultiplier
      + perMin × estimatedMinutes × vehicleMultiplier
      + platformFee
      + surgeFee = (subtotal) × (surgeMultiplier − 1)
      + tax = subtotal × taxPercent / 100
      − discount (from coupon)
      (clamped to minFare)
```

All rules configurable from the admin panel (`/services`).

## Dispatch Engine

`src/lib/dispatch.ts` — finds nearby online partners, ranks them by a weighted
score:

| Factor              | Weight |
|---------------------|--------|
| Distance (closer)   | 40%    |
| Rating (higher)     | 25%    |
| Acceptance rate     | 15%    |
| Completion rate     | 10%    |
| Current load (less) | 10%    |

Top 3 candidates receive a `PartnerAssignment` with a 15-second expiry window.
First to accept wins; the others are cancelled. If no one accepts, the order
falls back to `SEARCHING_PARTNER` and the cycle repeats.

In production this becomes a PostGIS + Redis geospatial query. For MVP it's a
linear scan over online partners (sufficient for hundreds of partners).

## Authentication

- **Admin panel**: email/password → bcrypt hash → JWT signed session cookie
  (httpOnly, 8h expiry). Argon2id recommended for production (bcrypt used here
  for portability).
- **Flutter apps**: phone OTP → JWT access + refresh tokens (rotation). OTP
  provider is pluggable: `MSG91OtpProvider` / `TwilioOtpProvider` /
  `MockOtpProvider` — selected by env var.

## Real-Time Tracking

- Partner app pushes location updates via `POST /api/tracking` (batched).
- User app subscribes via WebSocket / Socket.IO (planned).
- Admin panel polls `/api/tracking` every 5s on the live map (current MVP).

For production: Socket.IO server (separate Vercel function or external
container), Redis pubsub for fanout.

## CI/CD

- **Admin panel + backend**: Vercel auto-deploys on push to `main`. Preview
  deploys on every PR.
- **Flutter apps**: GitHub Actions builds release APKs on push to `main`, on
  PRs touching `apps/user_app/**` or `apps/partner_app/**`, on tags `v*`, and
  on manual dispatch. APKs are uploaded as artifacts (30-day retention) and
  attached to GitHub Releases on version tags.

## Security Checklist

- [x] Passwords hashed with bcrypt (12 rounds) — Argon2id recommended
- [x] JWT session cookies — httpOnly, secure in prod, sameSite=lax
- [x] Refresh token rotation (schema in place)
- [x] OTP rate limiting (schema in place)
- [x] No secrets in code — all via env vars
- [x] `.gitignore` excludes `.env`, `*.keystore`, `google-services.json`
- [x] API key auth (`X-API-Key`) for Flutter → backend
- [x] Audit log for admin actions
- [ ] HTTPS-only in production (Vercel handles this)
- [ ] CORS allowlist (currently permissive — lock down in prod)
- [ ] Rate limiting on public endpoints (Vercel Edge Middleware)
