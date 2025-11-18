This is a template Flutter project. It is based on a default Flutter project Android Studio generates with some additions.

# Changes

## pubsspec.yaml
- added dependencies to set app icons with **flutter_launcher_icons** package
- set up basic assets folder structure
- changed linter to **very_good_analysis**

## Android manifest
Explicitely removed some excess Samsung and Huawei permissions that may be added if Appsflyer is used in the app.

Updated styles.xml so the app could easily use immersive mode.

## App's build.gradle.kts

Has a task to generate keystore file via a script. The script is in android/app/keystore/generate_keystore.sh. You can place it somewhere in add into PATH environment variable.

## Sources
Moved MainActivity.kt to android/app/src/main/kotlin/. No need to create folders that follow app namespace as it is each time is different.

## AI prompts
Folder docs/ has some useful rules for an AI and a basic project requirement document (PRD) for an AI to generate a scaffold structure.

You must provide docs/visual_style.md and docs/specific/specific_requirements.md.

visual_style.md should have design system description for the app: colors, typography, spacing, and layout.
specific_requirements.md should have specific requirements for the app: screens beyond loading and main, features,functionality, and user experience.

# How to start

## Placeholders
Before usage change placeholders across **whole project**

## Flutter init
Run 'flutter pub get' to download dependencies.
Run 'dart run flutter_launcher_icons' to generate app icons from assets in assets/icons/.
Run an AVD or attach a physical device.
Ensure that the basic app runs with 'flutter run'.

## Flutter hints

Clean android and flutter intermediate files to get a clean build.
```
cd ./android && ./gradlew clean && cd .. && flutter clean
```

This can help if an LLM updated something in Flutter/Kotlin logic and you do not see any changes in the app behavior.

Happy coding!