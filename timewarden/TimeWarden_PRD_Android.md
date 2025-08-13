# TimeWarden – All-in-One Productivity Hub (Android)

A **Flutter + Firebase** productivity app that combines **habit tracking, daily journaling, Pomodoro timer, and streak counters** into a single synchronized dashboard.

---

## 1. Objective
TimeWarden is designed for **daily personal use** while also serving as a **portfolio-grade project** to showcase skills in Flutter, Firebase, and clean architecture (BLoC).  

---

## 2. Features

### 2.1 Habit Tracker
- Add/edit/delete habits
- Mark complete/incomplete
- Streak tracking & charts
- Categorization (Health, Learning, etc.)
- Offline-first sync

**Firebase:** Firestore, Cloud Functions (streak updates), FCM notifications

---

### 2.2 Pomodoro Timer
- Custom work/break durations
- Pause/resume/cancel sessions
- Link sessions to habits
- Weekly/monthly focus charts

**Firebase:** Firestore, FCM (session end alerts)

---

### 2.3 Daily Journal
- Wins, Lessons, Gratitude pattern
- Rich text + image uploads
- Search past entries
- Calendar view

**Firebase:** Firestore, Storage (images)

---

### 2.4 Streak & Counter
- Track occasional activities (e.g., gym visits, game matches)
- Increment/decrement counters
- Auto streak calculation

**Firebase:** Firestore, Cloud Functions (streak logic)

---

### 2.5 Unified Dashboard
- Today’s habits
- Current Pomodoro status
- Latest journal entry preview
- Active streaks
- Weekly productivity summary

---

## 3. Tech Stack

### Frontend
- **Flutter** (latest stable)
- **State Management:** Flutter BLoC
- **UI:** Material 3, smooth animations, charts
- **Offline-first:** Firestore caching

**Folder Structure Example:**
```
lib/
 ├── features/
 │    ├── habits/
 │    ├── pomodoro/
 │    ├── journal/
 │    ├── streaks/
 │    ├── dashboard/
 ├── core/
 │    ├── widgets/
 │    ├── utils/
 │    ├── services/
```

---

### Backend (Firebase)
- **Auth:** Google + Email/Password
- **Firestore:** Per-user collections:
  - `/users/{userId}/habits/{habitId}`
  - `/users/{userId}/pomodoros/{sessionId}`
  - `/users/{userId}/journal/{entryId}`
  - `/users/{userId}/streaks/{streakId}`
- **Storage:** `/users/{userId}/journal_images/{imageId}`
- **Cloud Functions:**
  - Streak calculation
  - Weekly summary email (optional)
  - Push scheduling
- **Push Notifications:** FCM
- **Analytics:** Firebase Analytics

---

## 4. Development Roadmap

**Phase 1 (Week 1-2)**
- Firebase Auth
- Habit Tracker CRUD + streak logic
- Basic dashboard (habits)

**Phase 2 (Week 3)**
- Pomodoro timer + notifications
- Pomodoro history & charts

**Phase 3 (Week 4)**
- Daily journal (text + images)
- Search & calendar view

**Phase 4 (Week 5)**
- Streak counter for activities
- Unified dashboard

**Phase 5 (Week 6)**
- UI polish & animations
- Firebase Analytics
- Final testing & Play Store build

---

## 5. Success Criteria
- Smooth Android performance
- Offline-first Firestore sync
- Modular BLoC architecture
- Attractive, responsive UI
- Demonstrates multiple Firebase features
- Used daily with real data
