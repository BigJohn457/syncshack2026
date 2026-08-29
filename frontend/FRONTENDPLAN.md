src/commonMain/kotlin/ (or src/main/java/com/yourpackage/)
├── ui/
│   ├── components/       // Reusable UI (AppButton.kt, TopBar.kt, LetterCard.kt)
│   ├── screens/          // Your 5 dedicated page files
│   │   ├── Home_page.kt
│   │   ├── datetime.kt
│   │   ├── searching.kt
│   │   ├── chat.kt
│   │   └── gp_info.kt
│   └── navigation/       // Route definitions & NavHost
│       └── AppNavigation.kt
└── MainActivity.kt       // App entry point