# 🌊 LifeFlow - Advanced Productivity Platform

LifeFlow is a modern, premium, startup-quality productivity platform that seamlessly integrates task management, habit trackers, visual journals, and metrics dashboards in a secure, **offline-first** environment. 

Featuring hybrid glassmorphism/neumorphism cards, click-scaling micro-animations, customizable contribution heatmaps, and local biometric shields, LifeFlow is engineered to wow at first glance.

---

## 🚀 Key Features

1. **Authentication Shield**: Lock your dashboard with secure local passcodes or device biometrics (Fingerprint/Face ID). *Default test PIN: `1234`*.
2. **Advanced To-Do Management**: CRUD tasks with category tags, custom subtasks checklists, priority elevations (Low, Medium, High, Critical), Pomodoro integrations, and fluid drag-and-drop lanes.
3. **Deep Focus Pomodoro Timer**: Focus timers with elegant circular countdown gauges that directly accrue focus duration inside selected tasks.
4. **Habit Streak Tracker**: Build consistency streaks, unlock badges, and visualize performance trends through horizontal GitHub contribution grids.
5. **Timeline Reflections Journal**: Safe journaling space with animated horizontal mood selectors, secure log locks, and randomized daily prompts.
6. **Productivity telemetry Dashboard**: Progress dials calculating your daily **Productivity Score** combined across tasks, habits, and journals. Plots focus trend curves with `fl_chart`.
7. **JSON Backup & Recovery**: Package your entire offline database into a secure JSON string to copy, save, or restore your workspace instantly.

---

## 🛠️ Architecture Design System

LifeFlow uses **Clean Architecture + MVVM** combined with a modular, **feature-first** package structure:

```
lib/
├── core/
│   ├── database/     # Offline-first local database management (Hive)
│   ├── navigation/   # Declarative deep-linking routing (GoRouter)
│   └── theme/        # HSL Curated Theme Colors & Custom Glass/Neumorphism styles
├── features/
│   ├── auth/         # Secure local biometric & PIN entry lock, Onboarding
│   ├── tasks/        # Draggable Kanban Lanes, Pomodoro timers, subtasks checklist
│   ├── habits/       # GitHub contribution heatmaps, streaks, consistency scoring
│   ├── journal/      # Timeline-oriented writing feed, private logs encryption, mood selector
│   ├── analytics/    # Composite productivity analytics, dynamic charts (fl_chart)
│   └── settings/     # Security switches, JSON database recovery options, data exports
├── shared/
│   └── widgets/      # Premium reusable components (GlassCard, PremiumButton, Loaders)
└── main.dart         # Safe setup bootstrapper & MaterialApp.router entry
```

---

## 📦 Setup & Dependency Installation

Ensure you have the latest **Flutter SDK** (stable channel) installed on your machine.

### 1. Fetch Package Dependencies
Navigate to the root directory and run `flutter pub get` to download all core packages:
```bash
flutter pub get
```

### 2. Supported Platforms
* **Android**: Fully supports local biometric auth and notifications. Ensure your `MainActivity.kt` inherits from `FlutterFragmentActivity` to bind `local_auth`.
* **iOS**: Ensure your `Info.plist` includes permission strings for biometric Face ID (`NSFaceIDUsageDescription`).
* **Web / Desktop (Windows/macOS)**: Compiles and runs out of the box with responsive sidebar panel views.

---

## 📈 Scalability Recommendations

For real-world production growth, we recommend the following enhancements:

* **Sync Engines**: Layer **Supabase** or **Appwrite** over the local Hive database. Write a synchronization repository that pushes local diff logs to the cloud once an internet connection is established.
* **Biometric Upgrades**: Implement **flutter_secure_storage** to safely encrypt PIN passcodes inside secure hardware enclaves (Keychain/Keystore).
* **AI Features**: Hook up **Gemini API** wrappers inside the reflection journal workspace to analyze mood trends, suggest daily prompts, and provide cognitive restructuring advice.
