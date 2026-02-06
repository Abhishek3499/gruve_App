# Gruve App - Flutter Folder Structure

```
gruve_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── utils/
│   │   ├── assets.dart             # Centralized asset paths
│   │   └── slide_route.dart        # Custom navigation animation
│   ├── screens/
│   │   ├── intro_screen.dart       # Intro screen with sliding button
│   │   ├── splash_screen.dart      # Splash screen with video
│   │   ├── phone_number_screen.dart # Phone number login screen
│   │   └── auth/
│   │       ├── sign_in_screen.dart  # Sign in screen
│   │       └── widgets/
│   │           ├── auth_header.dart      # Logo + title widget
│   │           ├── auth_textfield.dart   # Reusable text field
│   │           ├── auth_divider.dart     # "Or continue with" divider
│   │           └── social_login_icons.dart # Social login buttons row
│   └── widgets/
│       ├── video_bg.dart           # Reusable video background
│       ├── PrimaryCtaButton.dart   # Gradient primary button
│       ├── outline_button.dart     # Outline secondary button
│       └── sliding_button.dart     # Sliding animation button
├── assets/
│   ├── auth/
│   │   └── icons/                  # Social login icons (Google, Apple)
│   ├── fonts/                      # Custom fonts (Raleway, Syncopate)
│   └── splash_screen_logo/         # App logo and video
└── pubspec.yaml                    # Dependencies and asset configuration
```

## Why This Structure is Professional & Beginner-Friendly

### ✅ **Professional Standards**
- **Separation of Concerns**: Screens, widgets, and utilities are clearly separated
- **Reusable Components**: All UI elements are modular and reusable
- **Centralized Assets**: Single source of truth for all asset paths
- **Consistent Naming**: Snake_case for files, clear descriptive names
- **Scalable Architecture**: Easy to add new screens and features

### ✅ **Beginner-Friendly**
- **Clear Organization**: Logical grouping makes code easy to find
- **Small Focused Files**: Each widget has a single responsibility
- **Minimal Dependencies**: Only essential packages used
- **Self-Documenting**: File names clearly indicate their purpose
- **No Over-Engineering**: Simple, readable code without unnecessary complexity

### ✅ **Key Features**
- **Video Background**: Reusable across all auth screens
- **Sliding Animation**: Custom widget for intro screen interaction
- **Consistent Design**: All buttons and inputs follow the same style
- **Font Management**: Properly configured fonts in pubspec.yaml
- **Asset Management**: Centralized asset path management

### ✅ **Navigation Flow**
```
SplashScreen → IntroScreen → SignInScreen → PhoneNumberScreen
```

Each screen uses the same video background and maintains consistent styling throughout the app.
