# HabitDuel Operations

## Quick start

Backend only:

```powershell
docker compose up -d --build db migrate server
```

Backend with live log UI:

```powershell
docker compose --profile observability up -d --build db migrate server dozzle
```

Backend with DB UI:

```powershell
docker compose --profile tools up -d --build db migrate server adminer
```

Windows helper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-stack.ps1 -Observability -Tools
```

Load test with a specific k6 scenario:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-stack.ps1 -LoadTest -LoadScript api-lifecycle.js
```

## URLs

- API health: `http://localhost:8080/healthz`
- Dozzle logs: `http://localhost:9999`
- Adminer: `http://localhost:8088`

## Log strategy

The Dart server now writes structured JSON logs to stdout. Important fields:

- `event`
- `requestId`
- `method`
- `path`
- `statusCode`
- `durationMs`

Use `requestId` to correlate a user-visible error with a single backend request.

Example:

```powershell
docker compose logs server --tail 200
```

## Firebase checks

Runtime dependency map for the new client flows:

- Firebase Auth: login/register/session
- Firestore: profiles, duels, achievements, stats, social, shop, quests, events
- FCM: device token sync and push handling

Before production rollout, validate:

1. `flutterfire` config matches the intended Firebase project.
2. Firestore rules are deployed after the new collections and subcollections.
3. At least one real device confirms FCM token registration.
4. Firestore indexes are deployed alongside rules.

## Recommended incident workflow

1. Reproduce the failing action.
2. Open Dozzle or `docker compose logs server`.
3. Search by route or `requestId`.
4. Confirm whether the failure is API, Firestore permissions, or client-only UI logic.
5. If Firestore is involved, compare the failing collection path against `firestore.rules`.
