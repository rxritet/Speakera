# ⚔️ HabitDuel

<div align="center">
  <p><b>Соревновательный трекер привычек на Flutter и Dart Shelf.</b></p>

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
  [![Dart Backend](https://img.shields.io/badge/Backend-Dart_Shelf-0175C2?style=flat-square&logo=dart)](https://dart.dev/)
  [![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL_16-336791?style=flat-square&logo=postgresql)](https://www.postgresql.org/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
</div>

---

## 📖 О проекте

**HabitDuel** — это не просто трекер привычек. Приложение использует геймификацию и социальные обязательства, чтобы помочь пользователям выработать последовательность. Два игрока вступают в «дуэль» и должны ежедневно делать check-in для выбранной привычки. Пропустил день — серия сбрасывается до нуля. Тот, кто продержится дольше, выигрывает дуэль.

### ✨ Ключевые возможности

- **1v1 Дуэли** — создавай открытые или направленные дуэли на 7, 14, 21 или 30 дней
- **Real-time обновления** — WebSocket мгновенно показывает check-in'ы и сломанные серии соперника
- **UTC-верификация** — ежедневные check-in'ы проверяются по серверному UTC-времени, исключая манипуляции на клиенте
- **Лидерборд и бейджи** — глобальный рейтинг и автоматические бейджи (например, за 3, 5 или 10 побед)
- **Умные уведомления** — локальные push-уведомления напоминают о check-in'е и сигнализируют, когда соперник сломал свою серию

---

## 🏗️ Стек и архитектура

Это **Fullstack Dart** проект — единый язык для клиента и сервера.

### Frontend (Flutter)

| Слой              | Технология                                       |
|-------------------|--------------------------------------------------|
| Фреймворк         | Flutter 3.x                                      |
| Архитектура       | Clean Architecture (Presentation, Domain, Data, Core) |
| Управление состоянием | Riverpod 2.5+                               |
| Сеть (REST)       | Dio                                              |
| Сеть (Realtime)   | `web_socket_channel`                             |
| Хранилище         | `flutter_secure_storage` (JWT), `shared_preferences` |
| Уведомления       | `flutter_local_notifications`, `timezone`        |

### Backend (Dart Shelf)

| Слой              | Технология                                       |
|-------------------|--------------------------------------------------|
| Фреймворк         | Dart `shelf` + `shelf_router` + `shelf_web_socket` |
| База данных       | PostgreSQL 16                                    |
| Аутентификация    | JWT (`dart_jsonwebtoken`, `crypto`)              |
| Миграции          | Кастомный идемпотентный скрипт (raw SQL)         |
| Конфигурация      | `dotenv`                                         |

---

## 📁 Структура проекта

```
HabitDuel/
├── lib/                        # Flutter-клиент
│   ├── core/                   # Сервисы (уведомления, утилиты)
│   ├── data/                   # Репозитории и API-слой
│   ├── domain/                 # Модели и бизнес-логика
│   ├── presentation/
│   │   ├── providers/          # Riverpod-провайдеры
│   │   └── screens/            # Экраны (auth, duel, home, leaderboard, profile, settings)
│   └── main.dart               # Точка входа
├── server/                     # Dart Shelf бэкенд
│   ├── bin/
│   │   ├── server.dart         # Точка входа сервера
│   │   └── migrate.dart        # CLI-утилита миграций
│   └── lib/
│       ├── handlers/           # HTTP-обработчики (auth, duels, checkins, leaderboard)
│       ├── middleware/         # JWT-middleware
│       ├── models/             # Модели данных
│       ├── services/           # Бизнес-логика
│       ├── websocket/          # WebSocket-хаб
│       ├── cron/               # Периодические задачи
│       └── db/                 # Подключение к PostgreSQL
│   └── migrations/             # SQL-миграции (001–007)
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## 🗄 База данных

Миграции применяются в порядке номеров:

| Миграция | Таблица / Действие          |
|----------|-----------------------------|
| 001      | users                       |
| 002      | duels                       |
| 003      | duel_participants            |
| 004      | checkins                    |
| 005      | badges                      |
| 006      | indexes (оптимизация)       |
| 007      | migrations (учёт применения)|

---

## 📱 Экраны приложения

- **Login / Register** — вход и регистрация
- **Home (Duels)** — список активных дуэлей
- **Duel Detail** — детали дуэли, check-in, прогресс соперника в реальном времени
- **Create Duel** — создание дуэли с выбором привычки и соперника
- **Leaderboard** — глобальный рейтинг
- **Profile** — статистика, бейджи, история
- **Settings** — тема оформления, напоминания

---

## 🔌 API (основные эндпоинты)

| Метод | Путь                  | Описание                          |
|-------|-----------------------|-----------------------------------|
| POST  | `/auth/register`      | Регистрация нового пользователя   |
| POST  | `/auth/login`         | Вход, получение JWT               |
| GET   | `/duels`              | Список дуэлей пользователя        |
| POST  | `/duels`              | Создать дуэль                     |
| POST  | `/duels/:id/accept`   | Принять вызов                     |
| POST  | `/checkins`           | Отметить check-in                 |
| GET   | `/leaderboard`        | Глобальный рейтинг                |
| WS    | `/ws`                 | WebSocket real-time обновления    |

---

## 🚀 Быстрый старт

### Требования

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x
- [Dart SDK](https://dart.dev/get-dart) ≥ 3.0
- [PostgreSQL 16](https://www.postgresql.org/download/) (локально или через Docker)

### 1. Клонирование

```bash
git clone https://github.com/rxritet/HabitDuel.git
cd HabitDuel
```

### 2. Настройка бэкенда

```bash
cd server
dart pub get
cp .env.example .env
# Отредактируй .env — укажи данные PostgreSQL и JWT_SECRET
dart run bin/migrate.dart
dart run bin/server.dart
```

Сервер запустится на `http://localhost:8080`.

### 3. Запуск Flutter-клиента

Открой новый терминал в корне проекта:

```bash
flutter pub get
flutter run
```

> **Важно:** бэкенд должен быть запущен до старта Flutter-приложения.

---

## ⚙️ Переменные окружения

Создай файл `.env` в папке `server/` на основе `.env.example`:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=habitduel
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your_jwt_secret
PORT=8080
```

---

## 🗺️ Roadmap

- [x] Система 1v1 дуэлей с отслеживанием серий
- [x] JWT-аутентификация
- [x] WebSocket real-time обновления
- [x] Глобальный лидерборд и бейджи
- [ ] Система друзей и приватные дуэли
- [ ] Push-уведомления (FCM)
- [ ] Групповые дуэли (3+ игроков)
- [ ] Релиз в App Store и Google Play

---

## 🤝 Участие в разработке

Предложения приветствуются! Сначала открой issue, чтобы обсудить изменение.

1. Форкни репозиторий
2. Создай ветку: `git checkout -b feature/my-feature`
3. Закоммить: `git commit -m 'feat: добавить фичу'`
4. Запушить: `git push origin feature/my-feature`
5. Открой Pull Request

---

## 📄 Лицензия

Распространяется под лицензией MIT. Подробнее — в файле [`LICENSE`](LICENSE).

---

<div align="center">
  Сделано с ❤️ by <a href="https://github.com/rxritet">rxritet</a>
</div>
