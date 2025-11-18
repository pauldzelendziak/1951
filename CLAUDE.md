# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a dual-structure Flutter template project:

- `front/` - Flutter app (Android-only)
- `back/` - Configuration system using YAML files

The project uses a configuration-driven approach where `back/config.yaml` provides build-time constants that are parsed by `build.gradle.kts` and exposed to Flutter via platform channels.

## Common Development Commands

### Setup
```bash
cd front
flutter pub get
dart run flutter_launcher_icons  # Generate app icons
```

### Development
```bash
cd front
flutter analyze                  # Lint and analyze code
flutter build apk --debug       # Build debug APK (for testing only)
flutter clean                   # Clean build cache
```

### Android Clean Build
```bash
cd front/android && ./gradlew clean && cd .. && flutter clean
```
Use this when Kotlin/Flutter changes aren't reflected in app behavior.

## Architecture Overview

### Configuration System
- `back/config.yaml` contains app configuration (app IDs, API keys, domains, etc.)
- `front/android/app/build.gradle.kts` parses YAML and exposes values as BuildConfig constants
- Flutter accesses these via platform channels, not hardcoded values

### Build System Features
- Automatic keystore generation via `generate_keystore.sh` script
- YAML-driven configuration with SnakeYAML parsing
- BuildConfig constants for all app parameters

### Key Architecture Principles (from docs/rules/flutter_rules.md)
- **Feature-first folder structure**: Organize by screens/features, not by file type
- **Event-based communication**: No direct dependencies between features
- **Modular design**: UI, Business Logic, Data, and Service layers separation
- **Centralized services**: Dialog, navigation, analytics, and remote config management
- **Platform-specific code isolation**: Minimal Flutter/Kotlin interface via platform channels

### Mobile App Specifications
- **Android only** (no iOS components needed)
- **Portrait orientation** locked (except WebView screens)
- **Immersive mode** for all screens except WebViews
- **Multi-language support**: EN base + 9 additional locales (RU, IT, DE, FR, ES, PT, PL, SK, TR, UK)
- **Custom localization system** using JSON files (not Flutter's default)

### Core Modules Required
- Remote config with caching
- AppsFlyer analytics integration
- Connectivity checking
- WebView with OAuth/payments support
- Custom dialog system
- Background management
- Immersive mode handling

### Technical Requirements
- **Hide all debug logs in release builds**
- **Use BuildConfig.DEBUG** for debug logging control
- **Feature modules depend only on core modules**, never on each other
- **Very Good Analysis** linter (configured in analysis_options.yaml)
- **No hardcoded values** - use BuildConfig constants from YAML config

## Development Guidelines

### Naming Restrictions
Avoid these words in code and strings (not comments/docs):
- Regular projects: 'casino', 'bets', 'bet', 'slots', 'slot', 'money', 'gambling', 'jackpot', 'wager', 'payout', 'roulette', 'poker', 'blackjack', 'bingo', 'casino games', 'lottery', 'scratch', 'prize', 'win', 'double down', 'spin'
- Social casino: 'money', 'gambling', 'wager', 'payout'

### Implementation Approach
- Start implementation only with 95% confidence in approach
- Ask questions for clarification before proceeding
- Re-scan PRD after implementation to verify all requirements met
- Build debug APK to check for build errors when needed
- Use real SDK/API keys from config, never substitute with fake ones

### Package Management
- Use latest available package versions
- Check for updates with `flutter pub outdated`
- Only downgrade for compatibility issues

## Key Technical Implementations

### Back Button Handling
Complex dual-system implementation required for Android 13+ compatibility:
- Modern `OnBackInvokedDispatcher` for Android 13+
- Legacy `onBackPressed()` for older versions  
- See `docs/tech/flutter_back.md` for complete implementation guide

### Display Mode Management
Built-in Flutter system for immersive/normal mode switching:
- `SystemUiMode.immersiveSticky` for fullscreen
- `SystemUiMode.manual` with overlays for normal mode
- See `docs/tech/flutter_immersive.md` for implementation details

### WebView Implementation
Comprehensive WebView system using flutter_inappwebview:
- OAuth popup window support
- File upload capabilities
- Deeplink handling for all custom URL schemes
- Pull-to-refresh functionality
- See `docs/tech/webview.md` for complete implementation guide

### AppsFlyer Integration
- Native Kotlin implementation with Flutter platform channels
- 10-second timeout for conversion data polling
- Automatic customer user ID setting from remote config
- Installation source detection with organic fallback

## Important Build Configuration

### Required BuildConfig Constants
These constants are exposed from `build.gradle.kts` to Flutter:
- CONFIG_URL, INSTALLER_PARAM, USER_ID_PARAM, GAID_PARAM
- APPSFLYER_ID_PARAM, APPSFLYER_SOURCE_PARAM, APPSFLYER_DEV_KEY
- SUPPORT_LINK, PRIVACY_LINK, SUPPORT_LINK_PARAM, PRIVACY_LINK_PARAM
- APPMETRICA_SDK_KEY (if available)

### Keystore Management
- Automatic keystore generation before builds
- Script: `android/app/keystore/generate_keystore.sh`
- Uses app_id from YAML config for keystore naming and passwords