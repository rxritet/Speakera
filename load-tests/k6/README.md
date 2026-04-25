# HabitDuel k6 Load Tests

В папке теперь несколько сценариев, а не один базовый прогон.

## Сценарии

- `api-smoke.js`
  Быстрый smoke-тест доступности основных маршрутов.
- `api-load.js`
  Расширенный основной сценарий с хорошим покрытием жизненного цикла дуэли.
- `api-lifecycle.js`
  Сценарий на полный flow двух игроков: регистрация, логин, создание вызова, принятие, check-in, детали.

## Что покрывается

- `POST /auth/register`
- `POST /auth/login`
- `GET /users/me`
- `POST /duels/`
- `GET /duels/`
- `GET /duels/:id`
- `POST /duels/:id/accept`
- `POST /duels/:id/checkin`
- `GET /leaderboard/`

## Быстрый запуск

```powershell
docker compose up -d --build db migrate server
docker compose --profile load run --rm k6
```

По умолчанию запускается `api-load.js`.

## Выбор сценария

```powershell
$env:K6_SCRIPT="api-smoke.js"
docker compose --profile load run --rm k6
```

```powershell
$env:K6_SCRIPT="api-lifecycle.js"
$env:K6_VUS="10"
$env:K6_DURATION="20s"
docker compose --profile load run --rm k6
```

Через helper-скрипт:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-stack.ps1 -LoadTest -LoadScript api-lifecycle.js
```

## Рекомендуемые профили прогонов

- Smoke: `api-smoke.js`, `5 VUs`, `15s`
- Lifecycle: `api-lifecycle.js`, `10 VUs`, `20s`
- Main load: `api-load.js`, `20 VUs`, `30s`
- Medium: `api-load.js`, `50 VUs`, `2m`
- Stress: `api-load.js`, `100 VUs`, `5m`

## Практический смысл

- `api-smoke.js` подходит для CI и быстрых проверок после деплоя.
- `api-lifecycle.js` лучше ловит поломки в бизнес-флоу между двумя пользователями.
- `api-load.js` удобен для регулярной оценки производительности API под типичной нагрузкой.

## Ограничения

- Эти сценарии покрывают Shelf + Postgres API.
- Они не нагружают напрямую Firebase Auth, Firestore или FCM.
- Для Firebase лучше поднимать Emulator Suite и делать отдельный набор сценариев на чтение и запись коллекций клиента.
