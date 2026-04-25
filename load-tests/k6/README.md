# HabitDuel k6 Load Tests

This folder contains a basic API load scenario for the Dart backend.

## What it covers

- `POST /auth/register`
- `GET /users/me`
- `POST /duels`
- `GET /duels`
- `GET /leaderboard/`

Each virtual user creates an isolated account, authenticates with the returned JWT,
creates a duel, and exercises the main read paths.

## Run with Docker Compose

```powershell
docker compose up -d --build db migrate server
docker compose --profile load run --rm k6
```

Optional overrides:

```powershell
$env:K6_VUS="50"
$env:K6_DURATION="2m"
docker compose --profile load run --rm k6
```

The JSON summary is exported to `load-tests/results/api-summary.json`.

## Suggested baseline

- Smoke: `20 VUs / 30s`
- Medium: `50 VUs / 2m`
- Stress: `100 VUs / 5m`

## Notes

- This scenario targets the Shelf + Postgres API, not direct Firestore writes.
- For Firebase-specific load tests, use the Firebase Emulator Suite first, then
  replay representative Firestore traffic before touching production.
