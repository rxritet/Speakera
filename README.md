<div align="center">

# ⚔️ HabitDuel

**Выработай привычку побеждать.**

HabitDuel — мобильное приложение для соревновательного отслеживания привычек. Брось вызов другу, делай ежедневные чекины и доказывай, кто дисциплинированнее.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql)](https://www.postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docs.docker.com/compose)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

</div>

---

## 🎯 Что это такое

Большинство приложений для привычек скучны — ты один против себя. HabitDuel делает это соревнованием: ты и соперник выбираете привычку, устанавливаете правила и каждый день делаете чекин. Побеждает тот, кто не сдался.

### Ключевые идеи
- **Дуэли** — 1v1 челленджи с реальным ставком (стрики, репутация, XP)
- **Геймификация** — уровни, достижения, ежедневные квесты, сезоны
- **Прозрачность** — тепловая карта активности, H2H статистика, лидерборд
- **Кастомизация** — магазин аватаров, тем и бустеров

---

## ✨ Функциональность

### 🥊 Дуэли
- Создание и принятие вызовов
- Ежедневные чекины с подтверждением
- Статусы дуэли: активная / завершённая / ожидание
- Быстрые сообщения и чат внутри дуэли (WebSocket)

### 🏆 Геймификация
- **XP и уровни** — растут с каждым чекином и победой
- **Достижения** — 8+ разблокируемых наград в 5 категориях, включая секретные
- **Ежедневные квесты** — бонусные задачи для дополнительного XP
- **Сезоны** — ротируемые события и уникальные награды

### 📊 Статистика
- Общий обзор: дуэли / победы / поражения / win rate
- Тепловая карта активности за 365 дней
- H2H статистика по конкретным соперникам
- Любимое время для чекинов

### 🛍️ Магазин
- Аватары, темы оформления, эффекты
- Бустеры с таймером (ускоренный XP, streak shield)
- Три валюты: XP, гемы, монеты

### 👥 Социальные функции
- Добавление друзей и поиск соперников
- Рекомендации оппонентов по уровню
- Real-time уведомления о чекинах соперника

---

## 🏗️ Архитектура

Монорепо: Flutter-приложение + Dart Shelf backend в одном репозитории.

```
HabitDuel/
├── lib/                        # Flutter-приложение (Clean Architecture)
│   ├── core/                   # Firebase, сеть, утилиты
│   ├── data/                   # Репозитории, источники данных
│   ├── domain/                 # Бизнес-сущности и use cases
│   └── presentation/           # UI: экраны, виджеты, Riverpod провайдеры
│       ├── screens/
│       │   ├── home/           # Список дуэлей
│       │   ├── stats/          # Статистика + тепловая карта
│       │   ├── achievements/   # Дерево достижений
│       │   ├── shop/           # Магазин
│       │   └── profile/        # Профиль и настройки
│       ├── providers/          # Riverpod state management
│       └── widgets/            # Переиспользуемые компоненты
│
├── server/                     # Dart Shelf backend
│   ├── bin/                    # Entrypoint + migrate
│   ├── lib/
│   │   ├── handlers/           # HTTP handlers (auth, duels, checkins, leaderboard)
│   │   ├── services/           # Бизнес-логика
│   │   ├── db/                 # PostgreSQL слой
│   │   ├── middleware/         # JWT-аутентификация, CORS
│   │   ├── websocket/          # Real-time соединения
│   │   └── cron/               # Фоновые задачи
│   └── migrations/             # SQL-миграции
│
├── docs/                       # Документация, дизайн, Firebase, ops
├── load-tests/                 # k6 нагрузочные тесты
├── Dockerfile
└── docker-compose.yml
```

### Технологический стек

| Слой | Технология |
|------|-----------|
| Мобильный клиент | Flutter 3 + Dart |
| State management | Riverpod 2 |
| HTTP клиент | Dio |
| Real-time | WebSocket (`web_socket_channel`) |
| Backend | Dart Shelf + shelf_router |
| База данных | PostgreSQL 16 |
| Аутентификация | Firebase Auth + JWT |
| Облачное хранилище | Cloud Firestore |
| Push-уведомления | Firebase Cloud Messaging |
| Безопасное хранилище | flutter_secure_storage |
| Контейнеризация | Docker + Docker Compose |
| Нагрузочные тесты | k6 |

---

## 🚀 Быстрый старт

### Требования
- Flutter SDK `≥ 3.11.0`
- Dart SDK `≥ 3.0.0`
- Docker & Docker Compose
- Firebase проект (Auth, Firestore, FCM)

### 1. Клонирование

```bash
git clone https://github.com/rxritet/HabitDuel.git
cd HabitDuel
```

### 2. Backend (Docker)

```bash
# Скопируй и заполни переменные окружения
cp server/.env.example server/.env

# Запусти PostgreSQL + Migrations + Server
docker compose up --build

# Проверь health:
curl http://localhost:8080/healthz
```

| Сервис | URL |
|--------|-----|
| API Server | `http://localhost:8080` |
| Adminer (DB UI) | `http://localhost:8088` (профиль `tools`) |
| Dozzle (логи) | `http://localhost:9999` (профиль `observability`) |

```bash
# Запуск с дополнительными инструментами
docker compose --profile tools --profile observability up
```

### 3. Flutter-приложение

```bash
# Установи зависимости
flutter pub get

# Подключи Firebase (нужен FlutterFire CLI)
flutterfire configure

# Запусти
flutter run
```

### 4. Переменные окружения (server/.env)

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=habitduel
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your_jwt_secret
PORT=8080

FIREBASE_PROJECT_ID=your_project_id
FIREBASE_SERVICE_ACCOUNT_PATH=../service-account.json
```

---

## 🔌 API

Базовый URL: `http://localhost:8080`

| Метод | Endpoint | Описание |
|-------|----------|----------|
| `POST` | `/auth/register` | Регистрация |
| `POST` | `/auth/login` | Вход, возвращает JWT |
| `GET` | `/duels` | Список дуэлей пользователя |
| `POST` | `/duels` | Создать дуэль |
| `POST` | `/duels/:id/accept` | Принять вызов |
| `POST` | `/checkins` | Сделать чекин |
| `GET` | `/checkins/:duelId` | История чекинов |
| `GET` | `/leaderboard` | Глобальный лидерборд |
| `GET` | `/healthz` | Health check |
| `WS` | `/ws` | WebSocket (real-time события) |

Все защищённые роуты требуют заголовок `Authorization: Bearer <jwt>`.

---

## 🧪 Тестирование

```bash
# Юнит-тесты Flutter
flutter test

# Нагрузочные тесты (k6) — требует запущенный сервер
docker compose --profile load run k6

# Указать свой сценарий
K6_SCRIPT=api-load.js K6_VUS=50 K6_DURATION=60s docker compose --profile load run k6
```

Результаты нагрузочных тестов сохраняются в `load-tests/results/`.

---

## 🗂️ Документация

- [`docs/project/IMPLEMENTATION_SUMMARY.md`](docs/project/IMPLEMENTATION_SUMMARY.md) — итоги реализации HabitDuel 2.0
- [`docs/design/`](docs/design/) — дизайн-решения и UI гайдлайны
- [`docs/firebase/`](docs/firebase/) — схема Firestore и правила безопасности
- [`docs/ops/`](docs/ops/) — деплой и операционные заметки
- [`firestore.rules`](firestore.rules) — правила доступа к Firestore

---

## 🤝 Вклад в проект

1. Форкни репозиторий
2. Создай ветку: `git checkout -b feat/your-feature`
3. Сделай коммит: `git commit -m 'feat: add your feature'`
4. Открой Pull Request

Придерживайся стандартов: `flutter analyze` без ошибок, `flutter test` зелёный.

---

## 📄 Лицензия

MIT © [rxritet](https://github.com/rxritet)

---

<div align="center">
  <b>HabitDuel</b> — потому что привычки лучше формируются, когда есть соперник. ⚔️
</div>
