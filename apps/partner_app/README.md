# Partner App — Flutter

Delivery partner app for the Delivery Platform.

## Features
- Partner registration & KYC
- Online/offline toggle
- Incoming order requests (accept/reject with 15s timer)
- Live navigation to pickup & drop
- Pickup verification (OTP / QR)
- Delivery confirmation
- Earnings dashboard & wallet
- Withdrawal requests
- Order history & ratings

## Build
```bash
cd apps/partner_app
flutter pub get
flutter build apk --release
```

## Environment
Copy `.env.example` to `.env` and set:
- `API_BASE_URL` — backend URL (Vercel deployment)
- `API_KEY` — X-API-Key for backend auth
- `GOOGLE_MAPS_API_KEY` — for maps SDK
