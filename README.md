# ⚔️ HabitDuel

<div align="center">
  <p><b>A competitive habit-tracking app built with Flutter and Dart Shelf.</b></p>

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
  [![Dart Backend](https://img.shields.io/badge/Backend-Dart_Shelf-0175C2?style=flat-square&logo=dart)](https://dart.dev/)
  [![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL_16-336791?style=flat-square&logo=postgresql)](https://www.postgresql.org/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
</div>

---

## 📖 About The Project

**HabitDuel** is not just another habit tracker. It relies on gamification and social contracts to help users build consistency. Two users enter a "duel" and must perform a daily check-in for a chosen habit. Skip a day, and your streak resets to zero. The user who outlasts their opponent wins the duel.

### ✨ Key Features

- **1v1 Duels** — Create open or targeted duels for 7, 14, 21, or 30 days.
- **Real-time Updates** — WebSocket integration ensures you see your opponent's check-ins and broken streaks instantly.
- **Strict UTC Tracking** — Daily check-ins are verified against server UTC time, preventing client-side time manipulation.
- **Global Leaderboard & Badges** — Compete globally and earn automated badges (e.g., 3, 5, or 10 wins).
- **Smart Notifications** — Local push notifications remind you to check in and alert you when to attack if your opponent breaks their streak.

---

## 🏗️ Tech Stack & Architecture

This is a **Fullstack Dart** project utilizing a shared language ecosystem for both client and server.

### Frontend (Flutter)

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| Architecture | Clean Architecture (Presentation, Domain, Data, Core) |
| State Management | Riverpod 2.5+ |
| Networking (REST) | Dio + Retrofit |
| Networking (Realtime) | `web_socket_channel` |
| Secure Storage | `flutter_secure_storage` (JWT tokens) |

### Backend (Dart Shelf)

| Layer | Technology |
|---|---|
| Framework | Dart `shelf` + `shelf_router` |
| Database | PostgreSQL 16 |
| Authentication | JWT (`dart_jsonwebtoken`, `crypto`) |
| Migrations | Custom idempotent migration script (raw SQL) |

---

## 📁 Project Structure

```
habitduel/
├── lib/
│   ├── core/           # Shared utilities, constants, theme
│   ├── data/           # Repositories, data sources, models
│   ├── domain/         # Entities, use cases, interfaces
│   └── presentation/   # Screens, widgets, providers
├── server/
│   ├── bin/
│   │   ├── server.dart     # Entry point
│   │   └── migrate.dart    # DB migration runner
│   ├── lib/            # Routes, handlers, services
│   └── pubspec.yaml
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x
- [Dart SDK](https://dart.dev/get-dart)
- [PostgreSQL 16](https://www.postgresql.org/download/) (local or via Docker)

### 1. Clone the Repository

```bash
git clone https://github.com/rxritet/HabitDuel.git
cd HabitDuel
```

### 2. Database & Backend Setup

```bash
# Navigate to server directory
cd server

# Install dependencies
dart pub get

# Configure environment variables
cp .env.example .env
# Edit .env and fill in your DB credentials

# Run database migrations
dart bin/migrate.dart

# Start the server (defaults to port 8080)
dart bin/server.dart
```

### 3. Frontend Setup

Open a new terminal in the project root:

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

> **Note:** Make sure the backend server is running before launching the Flutter app.

---

## ⚙️ Environment Variables

Create a `.env` file inside the `server/` directory based on `.env.example`:

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

- [x] 1v1 Duel system with streak tracking
- [x] JWT authentication
- [x] WebSocket real-time updates
- [x] Global leaderboard & badges
- [ ] Friend system & private duels
- [ ] Push notifications (FCM)
- [ ] Group duels (3+ players)
- [ ] iOS & Android store release

---

## 🤝 Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'feat: add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for more information.

---

<div align="center">
  Made with ❤️ by <a href="https://github.com/rxritet">rxritet</a>
</div>
