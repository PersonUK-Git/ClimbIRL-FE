# 🧗 ClimbIRL - Flutter Mobile App

ClimbIRL is a premium, gamified task management application built with Flutter. It transforms productivity into an RPG-like experience where users earn XP, unlock achievements, and climb a global leaderboard by completing real-life tasks. 

## ✨ Features

-   **🎨 Stunning Glassmorphic UI**: High-end design with sleek animations and modern typography.
-   **📈 Leveling & XP System**: Earn XP for every task completed, with dynamic level-ups and rank titles.
-   **🔥 Streak Tracking**: Stay consistent and preserve your daily streaks.
-   **🏆 Achievement Gallery**: Over 20+ unlockable achievements with rarity-based rewards.
-   **🥈 Global Leaderboards**: Compare your progress with others on Weekly and Monthly scales.
-   **📱 Dynamic Onboarding**: A high-retention onboarding flow with premium animations.
-   **🌓 Theme Support**: Fully optimized for both Light and Dark modes.

## 🛠️ Technical Stack

-   **Framework**: [Flutter](https://flutter.dev/) (Material 3)
-   **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Cubit pattern)
-   **Navigation**: [go_router](https://pub.dev/packages/go_router)
-   **Animations**: [flutter_animate](https://pub.dev/packages/flutter_animate)
-   **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
-   **API Client**: [http](https://pub.dev/packages/http)
-   **Local Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences)

## 🏗️ Architecture

The app follows a clean, decoupled architecture:

1.  **UI Layer**: Screens and Widgets listening to Cubit states.
2.  **Domain/State Layer (Cubit)**: Handles business logic and UI state changes.
3.  **Data Layer (Repository)**: Abstracts API calls and handles data conversion from/to Models.
4.  **Network Layer**: Centralized API constants and base configurations.

### 📂 Directory Breakdown

-   `lib/core/`: Application-wide configurations.
    -   `theme/`: Custom color schemes and component themes.
    -   `network/`: API endpoints and base URL configuration. `api_constants.dart` handles environment switching.
    -   `constants/`: XP thresholds, level titles, and static category data.
-   `lib/cubits/`: State management logic for each feature (Auth, Dashboard, Tasks, Leaderboard).
-   `lib/data/`:
    -   `repositories/`: Logic for communicating with the backend API.
-   `lib/models/`: Type-safe data classes (User, Task, Achievement).
-   `lib/screens/`: High-level page layouts (Login, Dashboard, Profile).
-   `lib/widgets/`: Modular, reusable components (TaskCard, AchievementIcon).

## 🚀 Getting Started

### 1. Prerequisite
Ensure you have the Flutter SDK installed and the `ClimbIRL_BE` server running.

### 2. Configure API
Open `lib/core/network/api_constants.dart` and update the `_devBaseUrl` to match your computer's local IP address if testing on a physical device.

```dart
static const String _devBaseUrl = 'http://YOUR_LOCAL_IP:5000/api';
static const bool _isProd = false; // Set to false for local development
```

### 3. Run Commands

```bash
# Fetch dependencies
flutter pub get

# Run on a connected device/emulator
flutter run
```

### 4. Deployment

#### Local Builds 
To build the app locally for testing or manual distribution:

```bash
# Android (APK)
flutter build apk --release

# Android (App Bundle for Play Store)
flutter build appbundle --flavor prod --release

# iOS (Requires macOS/Xcode)
flutter build ios --release
```

#### Automated Deployment (GitHub Actions)
The project includes a GitHub Actions workflow for automated deployment to the Google Play Store (Closed Testing / Alpha track).

To trigger a deployment:
1. Go to the **Actions** tab in the GitHub repository.
2. Select the **Deploy Flutter App** workflow.
3. Click the **Run workflow** dropdown.
4. Type `yes` in the confirmation field (this is a safety check to prevent accidental deployments).
5. Click **Run workflow**.

This workflow will:
- Check out the code.
- Set up Java and Flutter.
- Install dependencies.
- Decode the keystore and set up signing properties.
- Increment the `versionCode` in `android/app/build.gradle.kts` and commit the change back to `main`.
- Build the production App Bundle.
- Upload the bundle to the Google Play Store on the `alpha` track.

## 🎥 Key Technical Details

-   **State Management**: Uses the BLoC library's `Cubit` for a simplified yet powerful unidirectional data flow.
-   **Atomic Completes**: Task completion is handled atomically in the backend, and the frontend updates the entire User state to keep XP and Levels in sync.
-   **Responsive Layout**: Uses `MediaQuery` and flexible widgets to ensure a consistent experience across different screen sizes.

---
Developed with ❤️ by the ClimbIRL Team.
