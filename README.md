# Speakera

A Flutter application for managing English language learning assessments. Speakera provides a role-based dashboard for administrators and students to track test results, monitor progress, and identify at-risk learners.

---

## Features

### Authentication
- Role-based login screen (Admin / Student)
- Animated fade-in UI with password visibility toggle

### Admin Dashboard
- **Overview** — KPI stat cards (total students, average score, active tests, high-risk count)
- **Students tab** — search by name/email, filter by risk level (Low / Medium / High), risk badges
- **Tests tab** — view Placement, Progress, and Mock tests; filter by status (Active / Draft / Archived)
- **Results tab** — expandable result cards with per-skill score breakdown and bar charts
- Light / Dark theme toggle

### Student Dashboard
- Personal welcome screen with average score and best skill highlight
- Skill breakdown bar chart (Listening, Reading, Writing, Speaking, Grammar)
- Full test history with expandable result cards

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK `^3.11.0`) |
| Charts | [`fl_chart ^0.68.0`](https://pub.dev/packages/fl_chart) |
| Icons | `cupertino_icons ^1.0.8` |
| Linting | `flutter_lints ^6.0.0` |

---

## Project Structure

```
lib/
├── main.dart              # App entry point, theme & auth state
├── models/
│   └── models.dart        # UserRole, Student, Test, TestResult enums & classes
├── data/
│   └── mock_data.dart     # Mock students, tests and results
├── screens/
│   ├── login_screen.dart
│   ├── admin_dashboard.dart
│   └── student_dashboard.dart
└── widgets/
    ├── stat_card.dart     # KPI summary card
    ├── kpi_chart.dart     # fl_chart bar chart wrapper
    ├── risk_badge.dart    # Colour-coded risk level chip
    └── filter_chips.dart  # Reusable filter chip row
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.x
- Dart SDK `^3.11.0`

### Run

```bash
flutter pub get
flutter run
```

### Build (web)

```bash
flutter build web
```

---

## Platforms

The project is configured for **Android**, **iOS**, **Web**, **Windows**, **macOS**, and **Linux**.
