# HabitDuel k6 Load Tests

В папке лежит несколько сценариев, но основной прогон теперь строится вокруг длинной смешанной нагрузки и реальных тестовых пользователей.

## Сценарии

- `api-smoke.js`
  Быстрый smoke-прогон доступности основных маршрутов.
- `api-lifecycle.js`
  Полный flow двух игроков: регистрация, логин, создание вызова, принятие, check-in, детали.
- `api-load.js`
  Основной долгий сценарий с тремя параллельными типами нагрузки:
  - `auth_churn`: постоянно создает новых пользователей и логинит их
  - `duel_lifecycle`: гоняет полный жизненный цикл дуэли на заранее созданных парах
  - `browse_api`: читает health, профиль, список дуэлей, leaderboard и детали дуэлей

## Что покрывается

- `GET /healthz`
- `POST /auth/register`
- `POST /auth/login`
- `GET /users/me`
- `POST /duels/`
- `GET /duels/`
- `GET /duels/:id`
- `POST /duels/:id/accept`
- `POST /duels/:id/checkin`
- `GET /leaderboard/`

## Реальные тестовые пользователи

`api-load.js` перед стартом делает `setup()` и создает пул реальных пользователей в системе.
Дополнительно во время самого прогона сценарий `auth_churn` продолжает создавать новых пользователей, чтобы нагрузка шла не только по чтению, но и по регистрации/логину.

Префикс пользователей строится через `K6_RUN_ID`, чтобы прогоны не мешали друг другу.

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

## Основные переменные для `api-load.js`

- `K6_RUN_ID`
  Уникальный идентификатор прогона. Удобно задавать руками, если хочешь потом находить тестовых пользователей.
- `K6_AUTH_VUS`
  Число VU для сценария регистрации и логина.
- `K6_DUEL_VUS`
  Число VU для полного жизненного цикла дуэли.
- `K6_BROWSE_RATE`
  Сколько browse-итераций в секунду запускать.
- `K6_BROWSE_VUS`
  Сколько VU заранее выделить под browse.
- `K6_PAIR_COUNT`
  Сколько пар пользователей создать в `setup()`.
- `K6_RAMP_UP`
  Время разгона.
- `K6_STEADY`
  Основная полка нагрузки.
- `K6_RAMP_DOWN`
  Время плавного снижения нагрузки.

## Готовые профили прогонов

### Smoke

```powershell
$env:K6_SCRIPT="api-smoke.js"
$env:K6_VUS="5"
$env:K6_DURATION="15s"
docker compose --profile load run --rm k6
```

### Lifecycle

```powershell
$env:K6_SCRIPT="api-lifecycle.js"
$env:K6_VUS="12"
$env:K6_DURATION="45s"
docker compose --profile load run --rm k6
```

### Main Load

```powershell
$env:K6_SCRIPT="api-load.js"
$env:K6_RUN_ID="main-load-01"
$env:K6_AUTH_VUS="8"
$env:K6_DUEL_VUS="20"
$env:K6_BROWSE_RATE="25"
$env:K6_BROWSE_VUS="40"
$env:K6_PAIR_COUNT="60"
$env:K6_RAMP_UP="1m"
$env:K6_STEADY="4m"
$env:K6_RAMP_DOWN="1m"
docker compose --profile load run --rm k6
```

### Stress

```powershell
$env:K6_SCRIPT="api-load.js"
$env:K6_RUN_ID="stress-01"
$env:K6_AUTH_VUS="20"
$env:K6_DUEL_VUS="50"
$env:K6_BROWSE_RATE="80"
$env:K6_BROWSE_VUS="120"
$env:K6_PAIR_COUNT="180"
$env:K6_RAMP_UP="2m"
$env:K6_STEADY="8m"
$env:K6_RAMP_DOWN="2m"
docker compose --profile load run --rm k6
```

## Запуск через helper-скрипт

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-stack.ps1 -LoadTest -LoadScript api-load.js
```

Если нужны кастомные env-переменные, удобнее выставить их в текущей PowerShell-сессии перед запуском.

## Практический смысл

- `api-smoke.js` подходит для быстрой проверки после поднятия стека
- `api-lifecycle.js` полезен для проверки бизнес-флоу
- `api-load.js` подходит для реальной оценки устойчивости API под смешанной нагрузкой

## Ограничения

- Эти сценарии покрывают Shelf + Postgres API
- Они не нагружают напрямую Firebase Auth, Firestore или FCM
- Клиентские Flutter-only экраны и Firebase-only сценарии нужно тестировать отдельно
