# TimeWarden

**Your All-in-One Productivity Hub** — habit tracking, Pomodoro focus sessions, a biometric-secured journal, and a gamified dashboard. Built with Flutter and Firebase using Clean Architecture.

---

## Features

### Habit Tracker
- Create and manage daily habits with custom icons and colors
- Visual streak tracking with heatmap calendar
- Completion history and longest-streak records
- Reminders via local notifications

### Pomodoro Timer
- Classic Pomodoro technique with customizable work/short-break/long-break durations
- Background audio cues and alarm notifications (works with screen off)
- Session history and focus-time analytics
- Persistent settings saved with Hive

### Secure Journal
- Private journal entries protected by biometric authentication (fingerprint / Face ID)
- Each entry is encrypted client-side using `crypto` before storage
- Mood tagging, image attachments, and full-text search

### Dashboard & Gamification
- Unified overview of daily habits, recent journal entries, and focus stats
- Points system that rewards habit completions and Pomodoro sessions
- Streak milestones and achievements
- Heatmap visualizations powered by `fl_chart` and `flutter_heatmap_calendar`

### Authentication
- Email/password and Google Sign-In via Firebase Auth
- Persistent sessions with automatic re-authentication

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart ^3.5) |
| Backend | Firebase (Auth, Firestore, Storage, Messaging, Analytics) |
| State Management | BLoC (`flutter_bloc`) + Provider |
| Local Storage | Hive + SharedPreferences |
| Alarm / Audio | `alarm` package + `audioplayers` |
| Charts | `fl_chart` + `flutter_heatmap_calendar` |
| Security | `local_auth` (biometrics) + `crypto` |
| UI | Material 3, Google Fonts, `animations` |

---

## Architecture

The project follows **Clean Architecture** with a feature-based folder structure:

```
timewarden/lib/
├── core/                     # Shared utilities, services, theme, widgets
└── features/
    ├── auth/                 # Login, register, Google Sign-In
    ├── habits/               # Habit CRUD, streaks, reminders
    ├── pomodoro/             # Timer, sessions, settings
    ├── journal/              # Encrypted entries, mood, images
    ├── dashboard/            # Overview, gamification, heatmaps
    └── settings/             # User profile, app preferences
```

Each feature is split into:
- **domain/** — entities, repository interfaces, use cases (no Flutter/Firebase deps)
- **data/** — repository implementations, Firestore data sources, models
- **presentation/** — BLoC (events/states), pages, widgets

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.5 ([install guide](https://docs.flutter.dev/get-started/install))
- A Firebase project with **Auth**, **Firestore**, and **Storage** enabled
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/PavanKumarR20/TimeWarden.git
   cd TimeWarden/timewarden
   ```

2. **Connect your Firebase project**
   ```bash
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` (gitignored — never commit this file).

3. **Add platform config files** (also gitignored)
   - Android: place `google-services.json` in `android/app/`
   - iOS: place `GoogleService-Info.plist` in `ios/Runner/`

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Running Tests

```bash
flutter test
```

---

## Security

- `firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist` are gitignored and never committed
- Journal entries are encrypted client-side before being written to Firestore
- Biometric authentication gates access to the journal feature

---

## License

This project is for portfolio and personal use.

---

## Author

**Pavan Kumar** — [GitHub](https://github.com/PavanKumarR20)
