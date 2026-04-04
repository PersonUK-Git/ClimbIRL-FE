# ClimbIRL 🧗‍♂️

ClimbIRL is a modern, mobile-first gamification application built with Flutter. It transforms mundane task management into an engaging, progression-based experience, encouraging users to "level up" their real-life productivity.

## ✨ Key Features

- **📊 Dynamic Dashboard**: Re-imagined task overview with XP tracking, daily streaks, and quick stats visualization.
- **✅ Gamified Tasks**: Manage your daily objectives and earn experience points for every completion.
- **🏆 Achievement System**: Unlock unique milestones as you progress and improve your productivity across different categories.
- **🥇 Competitive Leaderboards**: See how you stack up against other users and climb the ranks.
- **👤 Personalized Profile**: Track your growth, view your stats, and customize your journey.

## 🛠️ Technical Stack

- **Framework**: [Flutter](https://flutter.dev/) (Material 3)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Cubit pattern)
- **Navigation**: [go_router](https://pub.dev/packages/go_router)
- **Animations**: [flutter_animate](https://pub.dev/packages/flutter_animate) & [flutter_staggered_animations](https://pub.dev/packages/flutter_staggered_animations)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Typography**: [google_fonts](https://pub.dev/packages/google_fonts) (Inter, Roboto, or Outfit)
- **UI Components**: [percent_indicator](https://pub.dev/packages/percent_indicator), [shimmer](https://pub.dev/packages/shimmer)

## 📁 Project Structure

```bash
lib/
├── core/         # Theme, constants, and utilities
├── cubits/       # Business logic / State management
├── data/         # Mock data and repositories
├── models/       # Data entities
├── screens/      # Feature-specific UI screens
│   ├── dashboard/
│   ├── achievements/
│   ├── leaderboard/
│   ├── tasks/
│   └── profile/
└── widgets/      # Shared UI components
```

## 🚀 Getting Started

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/climbirl.git
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the application**:
    ```bash
    flutter run
    ```

---

*Built with ❤️ for productivity seekers.*
