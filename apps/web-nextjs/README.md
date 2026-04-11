# GenGate Web (Next.js) — Foundation

Minimal Phase 1 scaffold for the GenGate web client.

## What runs now
- Next.js app starts with App Router shell.
- Route placeholders exist for:
  - `/login`
  - `/feed`
  - `/inbox`
  - `/location`
  - `/profile`
- Shared top navigation shell and baseline styling.
- API client placeholder (`lib/api/client.ts`) and env wiring.

## What is intentionally stubbed
- Authentication/session logic.
- Backend data fetching by domain.
- Real-time subscriptions.
- UI feature depth (forms, lists, media, messaging).

## Local run
```bash
cd apps/web-nextjs
npm install
npm run dev
```

Open http://localhost:3000.

## Basic verify
```bash
npm run lint
npm run typecheck
```

## Environment
Copy `.env.example` to `.env.local` if needed and adjust backend URL:
- `NEXT_PUBLIC_API_BASE_URL`
