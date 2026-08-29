src/commonMain/kotlin/ (or src/main/java/com/yourpackage/)
├── ui/
│   ├── components/       // Reusable UI (AppButton.kt, TopBar.kt, LetterCard.kt)
│   ├── screens/          // Your 5 dedicated page files
│   │   ├── HomeScreen.kt
│   │   ├── ComposeScreen.kt
│   │   ├── DriftMapScreen.kt
│   │   ├── LetterDetailScreen.kt
│   │   └── ArchiveScreen.kt
│   └── navigation/       // Route definitions & NavHost
│       ├── Screen.kt     // Sealed class or Type-Safe routes
│       └── AppNavigation.kt
└── MainActivity.kt       // App entry point