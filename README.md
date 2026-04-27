# HabitDuel

HabitDuel — это соревновательное приложение для трекинга привычек, где личные цели превращаются в дуэли, серии, XP, достижения и рост профиля. Репозиторий включает Flutter-клиент, локальный Dart backend на Shelf, PostgreSQL-инфраструктуру для API-сценариев, интеграцию с Firebase и нагрузочные тесты на k6.

## Что есть в проекте

- Flutter-приложение для Android, iOS и Web.
- Дуэли привычек: 1v1, групповые лобби, инвайты, чекины, серии и рейтинг.
- Геймификация: XP, достижения, квесты, магазин, аватары, события и прогресс профиля.
- Firebase-интеграция: Auth, Firestore, FCM и локальные уведомления.
- Локальный backend на Dart: REST API, JWT, PostgreSQL, миграции, WebSocket и сценарии для нагрузочного тестирования.
- Готовые PowerShell-скрипты и Docker Compose для локального запуска.

## Текущее состояние архитектуры

Проект находится в гибридном состоянии:

- Flutter-клиент уже сильно опирается на Firebase и использует Firestore как основной источник данных для заметной части пользовательских сценариев.
- Локальный Shelf + PostgreSQL backend по-прежнему нужен для REST API, JWT-флоу, миграций, WebSocket и k6-нагрузки.
- В результате в репозитории сосуществуют две рабочие модели:
  - Firebase-first для клиентских фич приложения.
  - Локальный API-стек для backend-разработки, smoke-checks и нагрузочных тестов.

Это не просто мобильное приложение и не только сервер. Репозиторий устроен как full-stack база для разработки, демо и проверки производительности.

## Стек

### Клиент

- Flutter
- Dart
- Riverpod
- Dio
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Firebase Messaging
- Flutter Local Notifications
- Shared Preferences
- Flutter Secure Storage
- WebSocket Channel

### Backend

- Dart
- Shelf
- Shelf Router
- Shelf WebSocket
- PostgreSQL 16
- `dart_jsonwebtoken`
- Docker Compose

### Инструменты качества

- `flutter_test`
- `dart analyze`
- `flutter_lints`
- k6

## Основные возможности

- Аутентификация: email/password и Google Sign-In.
- Дуэли: создание, принятие, просмотр и завершение.
- Групповые дуэли и открытые лобби.
- Чекины и подготовка к trusted check-in через Apple Health / Google Fit-подобные метрики.
- Профиль, лидерборд, достижения, статистика, магазин, события и квесты.
- Локальные уведомления и hooks для push-уведомлений через FCM.
- Demo/presentation mode для web.

## Структура репозитория

```text
lib/                    Flutter-приложение
android/                Android-проект
ios/                    iOS-проект
web/                    Web-обвязка Flutter
assets/                 Брендинг и ассеты
test/                   Flutter-тесты
server/                 Dart Shelf backend и SQL-миграции
load-tests/k6/          k6 smoke/lifecycle/load сценарии
load-tests/results/     Результаты нагрузочных прогонов
scripts/                PowerShell-скрипты для локальной разработки
docs/design/            Дизайн и продуктовые заметки
docs/firebase/          Firebase-документация и миграция
docs/ops/               Операционные инструкции
docs/project/           Сводка по реализации
```

## Быстрый старт

### Требования

- Flutter SDK с доступными командами `flutter` и `dart`
- Docker Desktop
- Android Studio и/или Xcode для мобильной разработки
- Настроенный Firebase-проект

### Установка зависимостей

Клиент:

```powershell
flutter pub get
```

Backend при локальной работе вне Docker:

```powershell
Set-Location .\server
dart pub get
Set-Location ..
```

### Подъём локального backend-стека

Минимальный запуск:

```powershell
docker compose up -d --build db migrate server
```

Проверка здоровья API:

```powershell
curl http://localhost:8080/healthz
```

Рекомендуемый helper-скрипт для Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-stack.ps1
```

Расширенный режим с UI для логов и БД:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-stack.ps1 -Observability -Tools
```

После запуска доступны:

- API: `http://localhost:8080`
- Dozzle: `http://localhost:9999`
- Adminer: `http://localhost:8088`

## Запуск приложения

### Web

Самый быстрый локальный сценарий:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-web.ps1
```

Скрипт:

- поднимает `db`, `migrate` и `server`
- ждёт готовности API
- запускает Flutter Web на `http://localhost:8081`
- передаёт `--dart-define=API_BASE_URL=http://localhost:8080`

Если нужен web-сценарий с явным включением Firebase:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dev-web.ps1 -EnableFirebaseWeb
```

### Android debug

Для Android-эмулятора в debug уже есть дефолтный адрес `http://10.0.2.2:8080`, поэтому обычно достаточно:

```powershell
flutter run -d android
```

Для физического Android-устройства нужно передать LAN IP компьютера:

```powershell
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8080
```

### iOS debug

Для iOS Simulator в debug используется `http://localhost:8080`:

```powershell
flutter run -d ios
```

Для физического iPhone также нужен LAN IP компьютера:

```powershell
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8080
```

## Мобильное приложение

### Платформы

- Android-проект находится в `android/`
- iOS-проект находится в `ios/`
- Web target находится в `web/`

### Идентификаторы

- Android `applicationId`: `com.rxritet.habitduel`
- iOS bundle id: `com.rxritet.habitduel`
- Android app label: `HabitDuel`

### Разрешения и уведомления

- Android запрашивает `INTERNET` и `POST_NOTIFICATIONS`
- iOS настроен на локальную разработку с `localhost` и `127.0.0.1`
- локальные уведомления инициализируются при старте приложения
- FCM инициализируется на не-web платформах

### Firebase-конфиг

В репозитории уже лежат платформенные конфиги:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Перед реальным релизом стоит отдельно проверить, что они указывают на нужный Firebase-проект.

## Сборки

### Release APK

Для non-debug мобильных сборок `API_BASE_URL` нужно передавать явно:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8080
```

Артефакты появятся в:

```text
build/app/outputs/flutter-apk/
```

Для иконок используется `assets/branding/app_icon.png`.

### Важное замечание по релизу

Текущая конфигурация ориентирована на dev/demo-distribution. Перед публикацией в Google Play или App Store нужно отдельно подготовить нормальную release-signing конфигурацию, секреты и production-настройки окружения.

## Backend

### Что делает сервер

Локальный backend в `server/` предоставляет:

- `/healthz`
- `/auth/*`
- защищённый `/users/me`
- `/duels/*`
- `/leaderboard/*`
- WebSocket-комнаты через `/ws/*`
- миграции, импорт и экспорт demo-данных

### Docker-сервисы

В `docker-compose.yml` описаны:

- `db` — PostgreSQL 16
- `migrate` — применение SQL-миграций
- `server` — Shelf API
- `adminer` — UI для БД
- `dozzle` — просмотр логов
- `k6` — нагрузочные прогоны API

### Основные переменные окружения

- `POSTGRES_PASSWORD`
- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `JWT_SECRET`
- `PORT`
- `K6_SCRIPT`
- `K6_VUS`
- `K6_DURATION`

## Firebase и модель данных

Firebase сейчас играет ключевую роль в клиентской части:

- Firebase Auth используется для входа и сессий.
- Cloud Firestore хранит пользователей, дуэли, бейджи, рейтинг, инвентарь, квесты и события.
- Firebase Messaging подключён под мобильные push-сценарии.

Ключевые файлы:

- `firestore.rules`
- `firestore.indexes.json`
- `firebase.json`
- `docs/firebase/FIREBASE_MIGRATION.md`
- `docs/firebase/FIREBASE_APP_UPDATES.md`

### Импорт demo-данных в Firestore

Демо JSON лежит в `server/exports/firebase-demo`.

Запускать импорт лучше из директории `server/`:

```powershell
Set-Location .\server
$env:EXPORT_DIR='exports/firebase-demo'
$env:DEMO_CURRENT_USER_ID='<your Firebase Auth uid>'
$env:DEMO_CURRENT_USERNAME='Aliar'
dart run bin/import_firebase.dart
```

Полезный dry-run режим:

```powershell
$env:IMPORT_DRY_RUN='true'
```

Импортер ожидает service account JSON либо в корне репозитория как `service-account.json`, либо через `FIREBASE_SERVICE_ACCOUNT_PATH`.

## Архитектура по слоям

### Flutter-клиент

Клиент организован близко к clean architecture:

- `lib/domain/` — сущности, контракты репозиториев, use cases
- `lib/data/` — реализации репозиториев и data source слой
- `lib/presentation/` — Riverpod providers, экраны и виджеты
- `lib/core/` — сеть, Firebase, уведомления, тема, health stubs, константы и утилиты

### State management

В проекте есть провайдеры для:

- auth
- duels
- achievements
- stats
- shop
- profile
- social
- leaderboard
- events
- theme
- gamification

### Стратегия доступа к данным

Самая важная деталь реализации — гибридный data layer:

- аутентификация и значительная часть клиентских сценариев уже опираются на Firebase
- Firestore-backed data sources являются основными для профиля, дуэлей и лидерборда
- REST backend сохранён для API-ориентированных сценариев и нагрузочного тестирования
- real-time обновления постепенно смещаются в сторону Firestore streams, но локальный backend всё ещё поддерживает WebSocket-флоу

## Тесты и проверки качества

### Flutter

Анализ кода:

```powershell
dart analyze
```

Тесты:

```powershell
flutter test
```

Сейчас в репозитории есть только минимальный placeholder smoke test в `test/widget_test.dart`, поэтому анализатор пока полезнее, чем текущее покрытие UI-тестами.

### Backend

В `server/pubspec.yaml` подключён пакет `test`, но отдельных backend test files сейчас в репозитории нет. На практике серверная проверка сейчас держится на:

- локальном запуске API
- ручной проверке маршрутов
- k6 сценариях

### k6-нагрузка

Доступные сценарии:

- `api-smoke.js`
- `api-lifecycle.js`
- `api-load.js`

Базовый запуск:

```powershell
docker compose --profile load run --rm k6
```

Запуск конкретного сценария:

```powershell
$env:K6_SCRIPT='api-lifecycle.js'
docker compose --profile load run --rm k6
```

Результат сохраняется в:

```text
load-tests/results/api-summary.json
```

## Операционная работа

Полезные команды:

```powershell
docker compose logs server --tail 200
docker compose ps
docker compose down
```

Подробности по эксплуатации и отладке собраны в `docs/ops/OPERATIONS.md`.

## Что уже реализовано

- обновлённый UI дуэлей и набор продуктовых экранов
- Firestore-first repositories и providers
- локальные уведомления и FCM hooks
- синхронизация профиля и лидерборда
- поддержка group duel lobby
- подготовка trusted check-in через health-метрики
- миграции backend, demo exports и load-test сценарии

## Что ещё важно перед production

- расширить автоматическое тестовое покрытие
- довести release signing и секреты до production-уровня
- повторно проверить Firestore rules и indexes
- усилить production-конфигурацию мобильных сборок
- завершить оставшиеся шаги по Firebase cutover

## Документация по проекту

- `docs/design/DESIGN.md`
- `docs/design/DESIGN_2.0.md`
- `docs/firebase/FIREBASE_MIGRATION.md`
- `docs/firebase/FIREBASE_APP_UPDATES.md`
- `docs/ops/OPERATIONS.md`
- `docs/project/IMPLEMENTATION_SUMMARY.md`

## Коротко

HabitDuel — это full-stack проект с Flutter-клиентом, Firebase-first продуктовой логикой и локальным Dart/PostgreSQL backend для API, миграций и нагрузочной валидации. Если работа идёт над мобильной частью, основной фокус — Flutter + Firebase. Если нужно проверять серверные сценарии, поднимайте Docker-стек и используйте встроенные k6 и ops-инструменты.
