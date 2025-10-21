# clearfi monorepo

- `apps/web` → marketing site (clearfi.nl)
- `apps/app` → klantomgeving (app.clearfi.nl)
- `apps/admin` → admin logs (admin.clearfi.nl)

## Scripts
- `pnpm dev` – start alle apps (turbo)
- `pnpm build` – build alle apps
- `pnpm lint` – lint alle apps
- `pnpm format` – prettier over de repo

## Ontwikkelen
In 2 terminals:
1) `pnpm dev` (root)
2) open de app-URL die Next toont (poortjes 3000/3001/3002)

## Volgende stappen
- Auth (email+password) met Auth.js
- Database (Postgres) met Prisma
- Domeinen & deploy
