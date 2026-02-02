# Hero Smith

A Flutter app for creating and managing heroes for the **Draw Steel** tabletop role-playing game system.

## Features

-  **Hero Creation Wizard** - Step-by-step hero building (Story → Strength → Strife)
-  **Modular Component System** - Classes, ancestries, kits, perks, titles, and more
-  **Automatic Stat Calculation** - Stats compute from all sources with full tracking
-  **Abilities Management** - View, organize, and track all hero abilities
-  **Offline-First** - All data stored locally via SQLite (Drift)
-  **Draw Steel Themed** - UI designed around the TTRPG aesthetic

## Screenshots

*Coming soon*


## License

This project is licensed under the **Apache License 2.0**.

See [LICENSE](LICENSE) for full terms.

## Draw Steel Creator License

Hero Smith is an independent product published under the DRAW STEEL Creator License and is not affiliated with MCDM Productions, LLC.

DRAW STEEL © 2024 MCDM Productions, LLC.

## Privacy

Hero Smith collects no personal data. All hero data is stored locally on your device.

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for details.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

All contributions are subject to the Apache License 2.0.

## Acknowledgments

- **MCDM Productions** - Creators of Draw Steel TTRPG. Great game!
- **Steel Compendium** (https://steelcompendium.io) - Thanks for allowing use of the abilities data.
- **Flutter/Dart Team** - Framework and language
- **Drift** - SQLite database package

## Contact

- **Author:** stoneworks-dev
- **Email:** [support@stoneworks-software.com](mailto:support@stoneworks-software.com)
- **GitHub:** https://github.com/stoneworks-dev/hero-smith

## Getting Started

### Prerequisites

- Flutter SDK 3.3.0+
- Dart 3.3.0+

### Installation

```bash
# Clone the repository
git clone https://github.com/stoneworks-dev/hero-smith.git

# Navigate to the Flutter project
cd hero-smith/hero_smith

# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### “Source-Only” Repo

Regenerate the platform folders locally:

```bash
cd hero-smith

# Generate platform folders (android, ios, web, etc.)
flutter create .

flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Optional
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Database Reset

Delete the local database file or uninstall the app to reset all data.

## Project Structure

```
hero_smith/
├── lib/
│   ├── core/
│   │   ├── db/           # Drift database, providers
│   │   ├── models/       # Domain models (Component, HeroAssembly)
│   │   ├── repositories/ # Database access layer
│   │   ├── services/     # Business logic (grant services)
│   │   ├── seed/         # JSON → Components seeding
│   │   └── theme/        # App theming and styling
│   ├── features/
│   │   ├── creators/     # Hero creation wizard
│   │   ├── heroes_sheet/ # Hero view/edit screens
│   │   └── main_pages/   # Top-level navigation
│   └── widgets/          # Reusable UI components
└── data/                 # JSON data files for seeding
```

## Data Flow

1. JSON files (`data/`) → seeded to `Components` table on first run
2. User selections → stored in database with source tracking
3. `HeroAssemblyService.assemble()` → unified `HeroAssembly` view

## Building for Release

```bash
# Build release APK (for testing)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## Building on Other Platforms

Hero Smith is a Flutter project and is intended to be buildable on multiple platforms (Android, iOS, macOS, Linux, Windows, Web). If you clone this repository, you can generally build and run the app on whatever platforms your development machine supports.

Notes:

- Platform support depends on your OS and installed toolchain (Xcode, Android SDK, Visual Studio build tools, Linux desktop libraries, etc.). These requirements vary by environment and change over time.
- iOS/macOS builds require a Mac due to Apple tooling.
- The app relies on bundled assets under `hero_smith/data/` (declared in `pubspec.yaml`), so make sure assets are present when adapting/packaging.
- If you’re unsure what your machine supports, `flutter doctor` is the best starting point.

---

*Hero Smith is a fan-made, independent product published under the DRAW STEEL Creator License and is not affiliated with MCDM Productions, LLC. DRAW STEEL © 2024 MCDM Productions, LLC.*
