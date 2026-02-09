# Hero Smith

A Flutter app for creating and managing heroes for the **Draw Steel** tabletop role-playing game system.

## Features

-  **Hero Creation Wizard** - Step-by-step hero building
-  **Automatic Stat Calculation**(WIP) - Stats compute from all sources with full tracking
-  **Abilities** - View and track all hero abilities
-  **Inventory management** - Manage your inventory and gear
-  **Downtime tracking** - Tracks downtime progression, followers and guides
-  **Note taking** - Take detailed notes for your hero and the campaign
-  **Offline-First** - All data stored locally via SQLite (Drift)
-  **Automatic Update Checks** - App checks GitHub Releases for new versions on startup

## Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/heroes.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/main-page.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/main-page-2.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/abilties.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/wealth.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/respites.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/downtime.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/treasures.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/kits.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/inventory.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/languages.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/skills.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/hero-creator-story.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/hero-creator-story-2.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/hero-creator-strife.jpg" width="170" />
  <img src="https://raw.githubusercontent.com/stoneworks-dev/hero-smith-assets/main/images/hero-creator-strife-2.jpg" width="170" />
</p>


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
- **Steel Compendium** (https://steelcompendium.io) - Thanks for allowing use of the abilities dat
- **Flutter/Dart Team** - Framework and language
- **Drift** - SQLite database package

## Contact

- **Author:** stoneworks-dev
- **Email:** [support@stoneworks-software.com](mailto:support@stoneworks-software.com)
- **GitHub:** https://github.com/stoneworks-dev/hero-smith

## Installation

### Android

1. Go to the [Releases](https://github.com/stoneworks-dev/hero-smith/releases) page.
2. Download the latest `andr-X.Y.Z` release asset (`.apk` file).
3. On your device, enable **Install from unknown sources** in Settings → Security (if not already enabled).
4. Open the downloaded `.apk` and tap **Install**.
5. Launch Hero Smith from your app drawer.

**Updating:** When a new version is available, the app will show a prompt on startup. Click **Download** to get the new APK, then install it over the existing app. Your hero data is stored separately and will **not** be lost.

> **Note:** On Android, you may need to allow your phone to install unknown apps the first time. I recommend giving permission and installing from your phone file system, not the browser.

### Windows

1. Go to the [Releases](https://github.com/stoneworks-dev/hero-smith/releases) page.
2. Download the latest `win-X.Y.Z` release asset (`.exe` file).
3. Run the downloaded `.exe` to install Hero Smith.
4. Launch Hero Smith from your Start Menu or desktop shortcut.

**Updating:** When a new version is available, the app will show a prompt on startup. Click **Download** to get the new installer, then run it. Your hero data is stored separately and will **not** be lost.

## Versioning & Auto-Updates

Hero Smith uses GitHub Releases for distribution. Release tags follow a platform-specific format:

| Platform | Tag Format | Example |
|----------|-----------|---------|
| Windows  | `win-X.Y.Z` | `win-1.0.1` |
| Android  | `andr-X.Y.Z` | `andr-1.0.1` |
| iOS      | `ios-X.Y.Z` | `ios-1.0.1` |
| macOS    | `mac-X.Y.Z` | `mac-1.0.1` |
| Linux    | `linux-X.Y.Z` | `linux-1.0.1` |

On startup, the app checks GitHub for the latest release matching the current platform. If a newer version exists, a dialog is shown with release notes and a download link.

Users can:
- Dismiss with **Later**
- Check **"Don't remind me again"** to suppress future prompts
- Re-enable prompts anytime from **About → Updates**
- Manually check for updates from the About page

### For Developers: Creating a New Release

1. Update `version:` in `hero_smith/pubspec.yaml` (e.g., `1.0.0` → `1.0.1`).
2. Build the platform binaries:
   ```bash
   # Windows
   flutter build windows --release

   # Android
   flutter build apk --release
   ```
3. Create a new GitHub Release for each platform with the corresponding tag (e.g., `win-1.0.1`).
4. Upload the build artifact as a release asset.
5. Add release notes describing what changed.

The `pubspec.yaml` version and the numeric part of the tag should match (e.g., pubspec `1.0.1` ↔ tag `win-1.0.1`).

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
