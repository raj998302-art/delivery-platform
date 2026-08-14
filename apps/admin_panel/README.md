# Admin Panel + Backend (Next.js on Vercel)

The admin panel and backend API live together in this Next.js app — a single
deployment on Vercel.

## Stack

- **Next.js 15** (App Router, TypeScript, server components + API routes)
- **Tailwind CSS** + **shadcn/ui**-style primitives
- **Prisma ORM** → PostgreSQL (+ PostGIS for production geospatial queries)
- **Recharts** for analytics
- **JWT + bcrypt** admin auth, session cookie
- **TanStack Query** for client data fetching
- **Zod** validation on every API route

## Local Development

```bash
cd apps/admin_panel
cp .env.example .env.local
# Edit .env.local with your DATABASE_URL and JWT_SECRET

npm install
npx prisma generate
npx prisma db push          # creates tables
npm run db:seed             # GET /api/seed also works
npm run dev
```

Open http://localhost:3000 → redirects to `/login`.

**Demo admin:** `admin@delivery.local` / `admin123`

## API Endpoints

### Auth
- `POST /api/auth/login` — admin login (sets session cookie)
- `POST /api/auth/logout`
- `GET  /api/auth/me`

### Admin (cookie-auth)
- `GET /api/orders` — paginated list with filters
- `GET /api/partners` — paginated partners
- `PATCH /api/partners` — update partner status
- `GET /api/users` — paginated users
- `PATCH /api/users` — block/unblock
- `GET /api/services` — services + vehicle types + pricing + coupons + flags
- `PATCH /api/services` — update service pricing
- `GET /api/analytics` — dashboard KPIs + time-series
- `GET /api/tracking` — active tracking sessions + online partners
- `POST /api/dispatch` — trigger dispatch for an order
- `GET /api/seed` — bootstrap demo data

### Public (X-API-Key header)
- `POST /api/pricing/quote` — get fare quote (used by Flutter apps)
- `POST /api/tracking` — push partner location update

## Deployment (Vercel)

This directory is configured as a Vercel project rooted at `apps/admin_panel`.
On push to `main`, Vercel auto-deploys.

Required env vars (set in Vercel project settings):
- `DATABASE_URL`
- `JWT_SECRET`
- `APP_API_KEYS`
- Plus any integration keys you need (Razorpay, MSG91, Google Maps, etc.)

## Database Migrations

```bash
npx prisma migrate dev --name init
npx prisma migrate deploy     # production
npx prisma studio             # GUI for inspecting data
```

## Architecture Notes

- **Modular monolith**: all "services" (auth, user, partner, order, dispatch,
  pricing, payment, notification, wallet, support, admin) share one Next.js
  app and one Prisma schema. Future microservice extraction is straightforward
  because each domain has its own table set and its own `/api/<domain>` route.
- **Pricing is backend-authoritative**: the Flutter apps request a quote via
  `/api/pricing/quote` and receive a signed `quoteId` that expires in 10 min.
  The client never computes prices.
- **Order state machine**: see `src/lib/order-state.ts` for the strict
  transition table. Invalid transitions are rejected by the API.
- **Dispatch**: see `src/lib/dispatch.ts` — finds nearby online partners,
  ranks them by (distance, rating, acceptance, completion, current load),
  and creates 15-second expiry assignment records. First to accept wins.
