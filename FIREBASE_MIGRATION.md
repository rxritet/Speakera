# Firebase Migration Plan

## Current State
- Flutter client initializes Firebase, but the app still uses a custom Dart backend and PostgreSQL for all domain data.
- Firebase is not yet the source of truth for auth, duels, check-ins, badges, or push notifications.

## Target Data Model

### `users/{userId}`
Fields:
- `username`
- `email`
- `wins`
- `losses`
- `createdAt`
- `legacyPostgresId`

### `duels/{duelId}`
Fields:
- `habitName`
- `description`
- `creatorId`
- `opponentId`
- `status`
- `durationDays`
- `startsAt`
- `endsAt`
- `createdAt`
- `legacyPostgresId`

Subcollections:
- `participants/{userId}`
- `checkins/{checkinId}`

### `users/{userId}/badges/{badgeId}`
Fields:
- `badgeType`
- `earnedAt`
- `legacyPostgresId`

## Migration Order
1. Enable Firebase products needed for the app: Auth, Firestore, Cloud Messaging.
2. Create Firestore security rules and required composite indexes.
3. Freeze writes in PostgreSQL during the cutover window.
4. Export PostgreSQL data in this order:
   - users
   - duels
   - duel_participants
   - checkins
   - badges
5. Import users first and keep a stable ID mapping table.
6. Import duels and then attach participants and check-ins.
7. Import badges.
8. Verify counts and sample records between PostgreSQL and Firestore.
9. Switch client reads to Firebase.
10. Switch client writes to Firebase.
11. Keep PostgreSQL as read-only archive until the new flow is stable.

## Cutover Rules
- Preserve old IDs in `legacyPostgresId` fields for traceability.
- Do not delete PostgreSQL data until Firestore verification passes.
- Keep a rollback path for the first release window.

## Next Implementation Steps
- Add Firebase Auth integration on the client.
- Add Firestore repositories for auth/profile/duels.
- Add FCM token registration and notification delivery.
- Build a migration script that exports PostgreSQL rows and writes Firestore documents in batches.

## Export Command

From `server/`, run:

```bash
dart run bin/export_postgres_for_firebase.dart
```

The script writes table dumps and a manifest to `exports/firebase/` by default.

## Import Command

From `server/`, run:

```bash
dart run bin/import_firebase.dart
```

Required setup:
- Place Firebase service account JSON at `server/../service-account.json`
   or set `FIREBASE_SERVICE_ACCOUNT_PATH` in `server/.env`.
- Ensure `FIREBASE_PROJECT_ID` is set (or present in `firebase.json`).

Useful options:
- `IMPORT_DRY_RUN=true` to validate source files and mapping without writes.
- `EXPORT_DIR=...` to import from a non-default export location.

Import writes the following document paths:
- `users/{userId}`
- `duels/{duelId}`
- `duels/{duelId}/participants/{userId}`
- `duels/{duelId}/checkins/{checkinId}`
- `users/{userId}/badges/{badgeId}`
