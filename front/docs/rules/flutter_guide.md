# Claude Collaboration Guide for Flutter (Android-first, Material 3)

**Purpose:** This file tells Claude exactly how to generate code for this project so outputs stay consistent, modular, and easy to maintain.

**Note:** For Flame game projects, see [flame_guide.md](flame_guide.md) instead. This guide is for business/CRUD applications with APIs, forms, and complex state management.

**Read order for Claude:** 1) Project Rules → 2) Architecture & Structure → 3) UI/Theming → 4) Patterns & Templates → 5) Workflow with Claude → 6) Checklists.

---

## 0) Project Snapshot (fill in per app)

<ARCHITECTURE>
• Primary state management: Riverpod
• Architecture: Feature-first + MVVM (presentation/domain/data)
• HTTP client: Dio
• Local storage: SharedPreferences + Hive/SQLite for complex data
• Environment: Development/Staging/Production
</ARCHITECTURE>

---

## 1) Project Rules

<CRITICAL_RULE>
**Claude MUST follow these rules in ALL code generation:**

1. **KISS:** Prefer the simplest working abstraction. No speculative layers.
2. **Separation of Concerns:** Widgets are for UI only. Business logic lives in ViewModels/Controllers. Data access lives in Repositories/Services.
3. **Single Source of Truth:** Each state has one owner (provider/bloc/viewmodel). No duplicate caches in widgets.
4. **Feature-first structure:** Place code under its feature. Shared-only code goes in lib/shared.
5. **No magic singletons:** Use DI via constructors/providers. Avoid global state.
6. **Theming only:** Do not hardcode colors, fonts, paddings. Use Theme.of(context) / ColorScheme / constants.
7. **Null safety & lints:** Fix analyzer warnings. Add types. Avoid dynamic/! unless justified.
8. **Tests for logic:** ViewModels, Repositories should have unit tests for non-trivial logic.
9. **Accessibility:** Respect text scaling, contrast, semantics, and hit targets.
10. **Docs:** Public classes/methods get brief /// comments; non-obvious code gets in-line comments.
11. **Logging:** Use AppLogger for all logs. Never use print() statements.
12. **Error handling:** Use sealed AppError classes for consistent error management.
</CRITICAL_RULE>

---

## 2) Architecture & Structure

<ARCHITECTURE>
### 2.1 Directory layout (feature-first + layers)

```
lib/
  app/
    app.dart            # MaterialApp, theming, routing bootstrap
    theme/
      theme.dart        # ThemeData/ColorScheme/Typography
    routing/
      app_router.dart   # GoRouter/Router config
    config/
      environment.dart  # Environment configuration
  shared/
    widgets/            # Reusable UI components (buttons, cards, bars)
    services/           # Cross-cutting services
      api_client.dart   # Dio HTTP client configuration
      logger.dart       # Centralized logging service
      storage/          # Persistence services
        preferences_service.dart  # SharedPreferences wrapper
        database_service.dart     # Hive/SQLite for complex data
    utils/              # Formatters, validators, helpers
      validators.dart   # Form validation utilities
    models/             # Cross-feature models & errors
      app_error.dart    # Sealed error classes
    providers/          # Global providers
  features/
    <feature_name>/
      data/             # DTOs, API clients, repositories
      domain/           # Entities, use cases (optional)
      presentation/     # Pages, widgets, viewmodels/providers
        pages/
        widgets/
        controllers/    # ViewModels/Notifiers/BLoCs
      providers.dart    # Feature-specific providers
```

### 2.2 Layering rules
• **Presentation:** Widgets + ViewModels/Providers controlling UI state.
• **Domain (optional for small features):** Pure logic/use-cases.
• **Data:** Remote/local data sources + repositories. Repositories are the API to the upper layers.

### 2.3 Naming & files
• **Files:** snake_case.dart → user_profile_page.dart, auth_repository.dart.
• **Classes:** UpperCamelCase → UserProfilePage, AuthRepository.
• **Methods/vars:** lowerCamelCase.
</ARCHITECTURE>

---

## 3) Core Services

<CODE_PATTERN>
### 3.1 Centralized Logging System

```dart
// lib/shared/services/logger.dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service that shows logs in debug mode only
class AppLogger {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: kDebugMode ? 2 : 0,
      errorMethodCount: kDebugMode ? 8 : 0,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: kDebugMode,
    ),
    level: kDebugMode ? Level.verbose : Level.nothing,
  );

  AppLogger._();

  /// Log debug message
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error, stackTrace);
    }
  }

  /// Log info message
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.i(message, error, stackTrace);
    }
  }

  /// Log warning message
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.w(message, error, stackTrace);
    }
  }

  /// Log error message
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.e(message, error, stackTrace);
    }
  }

  /// Log API calls
  static void api({
    required String method,
    required String url,
    Map<String, dynamic>? params,
    dynamic response,
    dynamic error,
  }) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln('API Call: $method $url');
      if (params != null) buffer.writeln('Params: $params');
      if (response != null) buffer.writeln('Response: $response');
      if (error != null) buffer.writeln('Error: $error');
      _logger.d(buffer.toString());
    }
  }

  /// Log navigation events
  static void nav(String route, [Map<String, dynamic>? params]) {
    if (kDebugMode) {
      _logger.i('Navigation: $route${params != null ? ' with $params' : ''}');
    }
  }
}
```
</CODE_PATTERN>

<CODE_PATTERN>
### 3.2 Error Handling

```dart
// lib/shared/models/app_error.dart
sealed class AppError {
  final String message;
  final String? code;
  const AppError(this.message, {this.code});
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.code});
}

class ValidationError extends AppError {
  final Map<String, String>? fieldErrors;
  const ValidationError(super.message, {this.fieldErrors, super.code});
}

class ServerError extends AppError {
  final int? statusCode;
  const ServerError(super.message, {this.statusCode, super.code});
}

class CacheError extends AppError {
  const CacheError(super.message, {super.code});
}

class UnknownError extends AppError {
  const UnknownError(super.message, {super.code});
}
```
</CODE_PATTERN>

<CODE_PATTERN>
### 3.3 Environment Configuration

```dart
// lib/app/config/environment.dart
enum Environment { dev, staging, prod }

class AppConfig {
  static const Environment env = Environment.dev; // Change for builds
  
  static String get apiUrl => switch (env) {
    Environment.dev => 'https://dev-api.example.com',
    Environment.staging => 'https://staging-api.example.com',
    Environment.prod => 'https://api.example.com',
  };
  
  static Duration get apiTimeout => switch (env) {
    Environment.dev => const Duration(seconds: 30),
    Environment.staging => const Duration(seconds: 15),
    Environment.prod => const Duration(seconds: 10),
  };
  
  static bool get enableCrashlytics => env == Environment.prod;
}
```
</CODE_PATTERN>

<CODE_PATTERN>
### 3.4 Network Layer

```dart
// lib/shared/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiUrl,
    connectTimeout: AppConfig.apiTimeout,
    receiveTimeout: AppConfig.apiTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
  
  // Request interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      AppLogger.api(
        method: options.method,
        url: options.uri.toString(),
        params: options.method == 'GET' ? options.queryParameters : options.data,
      );
      handler.next(options);
    },
    onResponse: (response, handler) {
      AppLogger.api(
        method: response.requestOptions.method,
        url: response.requestOptions.uri.toString(),
        response: response.data,
      );
      handler.next(response);
    },
    onError: (error, handler) {
      AppLogger.api(
        method: error.requestOptions.method,
        url: error.requestOptions.uri.toString(),
        error: error.message,
      );
      handler.next(error);
    },
  ));
  
  return dio;
});
```
</CODE_PATTERN>

---

## 4) State Management Policy

<CONSTRAINT>
Choose one approach per app. Example below assumes Riverpod.
</CONSTRAINT>

<CODE_PATTERN>
### 4.1 Riverpod conventions
• Use Notifier/AsyncNotifier for business logic.
• UI reads with ref.watch(...). Mutations only inside Notifiers.
• Provide repositories via providers (no service locators).
• Log state changes in debug mode.

**Example with logging:**

```dart
// lib/features/profile/presentation/controllers/profile_controller.dart
final profileControllerProvider =
  AutoDisposeAsyncNotifierProviderFamily<ProfileController, Profile, String>(
    ProfileController.new,
  );

class ProfileController extends AutoDisposeAsyncNotifier<Profile> {
  late final UserRepository _repo = ref.read(userRepositoryProvider);

  @override
  Future<Profile> build(String userId) async {
    AppLogger.d('Loading profile for user: $userId');
    try {
      final profile = await _repo.fetchProfile(userId);
      AppLogger.i('Profile loaded successfully: ${profile.name}');
      return profile;
    } catch (e, stack) {
      AppLogger.e('Failed to load profile', e, stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    AppLogger.d('Refreshing profile');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchProfile(arg));
  }
  
  Future<void> updateProfile(ProfileUpdate update) async {
    AppLogger.d('Updating profile with: $update');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updated = await _repo.updateProfile(arg, update);
      AppLogger.i('Profile updated successfully');
      return updated;
    });
  }
}
```
</CODE_PATTERN>

---

## 5) Material 3 Theming & Visual System

<CRITICAL_RULE>
### 5.1 Theme foundations
• **useMaterial3:** true
• **Generate ColorScheme** via ColorScheme.fromSeed.
• **Centralize typography & component** sub-themes in app/theme/theme.dart.
• **NEVER hardcode colors, fonts, or spacing** - always use Theme.of(context)
</CRITICAL_RULE>

<CODE_PATTERN>
**Theme skeleton:**

```dart
// lib/app/theme/theme.dart
import 'package:flutter/material.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF126E82),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16),
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(minimumSize: const Size(64, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
```
</CODE_PATTERN>

<CODE_PATTERN>
### 5.2 Reusable component catalog (use or extend)
• **Buttons:** PrimaryButton, SecondaryButton, IconTextButton
• **Navigation:** AppNavigationBar (bottom), AppNavigationRail (tablet+)
• **App bars:** AppTopBar(title, actions)
• **Containers:** SectionCard(title, child)
• **Form:** LabeledField, FormSection
• **Feedback:** AppSnack, AppProgressOverlay, AsyncValueWidget

**PrimaryButton:**

```dart
// lib/shared/widgets/primary_button.dart
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.leading});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Text(label),
      ]),
    );
  }
}
```

**Screen scaffold:**

```dart
// lib/shared/widgets/app_scaffold.dart
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  const AppScaffold({super.key, required this.title, required this.body, this.actions, this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
```

**AsyncValueWidget for loading states:**

```dart
// lib/shared/widgets/async_value_widget.dart
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace? stack)? error;
  
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });
  
  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: false,
      data: data,
      loading: () => loading?.call() ?? const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        AppLogger.e('AsyncValueWidget error', err, stack);
        return error?.call(err, stack) ?? 
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(err.toString()),
              ],
            ),
          );
      },
    );
  }
}
```
</CODE_PATTERN>

---

## 6) Navigation & Routing

<CODE_PATTERN>
### 6.1 GoRouter Configuration

```dart
// lib/app/routing/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) {
          AppLogger.nav('/', state.queryParameters);
          return const HomePage();
        },
        routes: [
          GoRoute(
            path: 'profile/:id',
            name: 'profile',
            builder: (context, state) {
              final userId = state.pathParameters['id']!;
              AppLogger.nav('/profile/$userId');
              return ProfilePage(userId: userId);
            },
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) {
              AppLogger.nav('/settings');
              return const SettingsPage();
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      AppLogger.e('Navigation error', state.error);
      return ErrorPage(error: state.error);
    },
  );
});

// Usage in app
class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'App',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
```
</CODE_PATTERN>

---

## 7) Forms & Validation

<CODE_PATTERN>
### 7.1 Validators

```dart
// lib/shared/utils/validators.dart
class Validators {
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }
  
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }
  
  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.length < min) {
      return '${fieldName ?? 'Field'} must be at least $min characters';
    }
    return null;
  }
  
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone is required';
    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.length < 10) return 'Enter a valid phone number';
    return null;
  }
  
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
```

### 7.2 Form Field Widget

```dart
// lib/shared/widgets/labeled_field.dart
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;
  
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            if (required) Text(' *', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
```
</CODE_PATTERN>

---

## 8) Dialogs, Sheets, and Navigation

<CODE_PATTERN>
### 8.1 Dialog system
• Use a tiny service that wraps showDialog with consistent theming.
• All confirm dialogs have Cancel (left) and OK (right).

```dart
// lib/shared/widgets/app_dialogs.dart
Future<bool?> showConfirmDialog(BuildContext context, {required String title, required String message}) {
  AppLogger.d('Showing confirm dialog: $title');
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
      ],
    ),
  );
}
```

### 8.2 Modal bottom sheet

```dart
Future<T?> showAppSheet<T>(BuildContext context, Widget child) {
  AppLogger.d('Showing bottom sheet');
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
```

### 8.3 Navigation
• Prefer go_router with typed routes (if available).
• Max 3–5 bottom destinations; use NavigationRail on wide screens.
</CODE_PATTERN>

---

## 9) Responsiveness & Accessibility

<CRITICAL_RULE>
• Use LayoutBuilder breakpoints (<600, >=600) to switch from bottom bar → rail.
• Respect MediaQuery.textScaleFactor and avoid clipped text.
• Use Semantics/tooltips for icon-only controls.
• Touch targets ≥ 48x48 dp.
</CRITICAL_RULE>

<CODE_PATTERN>
**Breakpoint wrapper:**

```dart
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  const Responsive({super.key, required this.mobile, required this.tablet});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) => c.maxWidth < 600 ? mobile : tablet,
  );
}
```
</CODE_PATTERN>

---

## 10) Data Layer Patterns

<CRITICAL_RULE>
• Repository is the only entry-point for feature data.
• Pure DTO ↔ Entity mapping. No UI imports.
• Always log data operations.
</CRITICAL_RULE>

<CODE_PATTERN>
```dart
abstract class UserRepository {
  Future<Profile> fetchProfile(String id);
  Future<Profile> updateProfile(String id, ProfileUpdate update);
}

class UserRepositoryImpl implements UserRepository {
  final Dio _client;
  UserRepositoryImpl(this._client);
  
  @override
  Future<Profile> fetchProfile(String id) async {
    try {
      AppLogger.d('Fetching profile: $id');
      final response = await _client.get('/users/$id');
      return Profile.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.e('Failed to fetch profile', e);
      throw ServerError('Failed to load profile', statusCode: e.response?.statusCode);
    }
  }
  
  @override
  Future<Profile> updateProfile(String id, ProfileUpdate update) async {
    try {
      AppLogger.d('Updating profile: $id with $update');
      final response = await _client.patch('/users/$id', data: update.toJson());
      return Profile.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.e('Failed to update profile', e);
      throw ServerError('Failed to update profile', statusCode: e.response?.statusCode);
    }
  }
}
```
</CODE_PATTERN>

---

## 11) Local Storage

<CODE_PATTERN>
```dart
// lib/shared/services/storage/preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  late final SharedPreferences _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.i('Preferences initialized');
  }
  
  String? getString(String key) {
    final value = _prefs.getString(key);
    AppLogger.d('Get preference: $key = $value');
    return value;
  }
  
  Future<bool> setString(String key, String value) async {
    AppLogger.d('Set preference: $key = $value');
    return _prefs.setString(key, value);
  }
  
  Future<bool> remove(String key) async {
    AppLogger.d('Remove preference: $key');
    return _prefs.remove(key);
  }
}

final preferencesProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('Initialize in main()');
});

// Initialize in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = PreferencesService();
  await prefs.init();
  
  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}
```
</CODE_PATTERN>

---

## 12) Testing

<CONSTRAINT>
• ViewModels/Controllers: unit tests for state transitions.
• Repositories: mock I/O; test mapping and error paths.
• Golden tests (optional) for critical widgets.
• Mock logger in tests to avoid console spam.

```dart
// test/shared/mocks/mock_logger.dart
void setupTestLogger() {
  // Override logger for tests
  AppLogger.setTestMode(true);
}
```
</CONSTRAINT>

---

## 13) Performance

<CRITICAL_RULE>
• Prefer const constructors & widgets.
• Minimize rebuilds: watch the smallest provider slice.
• Use list virtualization (ListView.builder) and pagination.
• Log performance issues in debug mode.
</CRITICAL_RULE>

---

## 14) Working with Claude (strict prompts)

<CLAUDE_INSTRUCTION>
### 14.1 How to ask Claude (developer-to-Claude)
• Always include: feature goal, destination folder, state management, and dependencies to reuse.
• Format:
  • **Context:** Current architecture and relevant files.
  • **Task:** Single focused request.
  • **Constraints:** KISS, SoC, SSOT, theming rules, use AppLogger.
  • **Output:** Files to create/modify with paths.

**Prompt template:**

```
You are contributing to a Flutter app.
Architecture: Feature-first + MVVM; State: Riverpod; Theme: Material 3 (no hard-coded colors).
Rules: KISS, SoC, SSOT, no singletons, use AppLogger for logging; tests for logic.
Task: Create a profile details screen that shows name, email, and edit button.
Place files under: lib/features/profile/presentation/pages/ and widgets/.
Reuse: UserRepository via userRepositoryProvider; PrimaryButton; AppScaffold; AppLogger.
Output: Code blocks per file with full contents.
```

### 14.2 Diff & revision policy
• If code exists, return diffs (filename + patch) or clear before/after blocks.
• If misaligned (e.g., used setState instead of Riverpod), rewrite to policy.

### 14.3 Guardrails for Claude
• Do not invent services; reuse repositories/providers listed.
• Do not hardcode styles; use Theme.of(context)/ColorScheme.
• Keep widgets <200 lines; extract sub-widgets.
• Add /// doc comments to public APIs.
• Always use AppLogger, never print().
• Handle errors with AppError sealed classes.
• Check environment config for API URLs.
</CLAUDE_INSTRUCTION>

---

## 15) Ready-to-use Snippets (Claude may copy)

<TEMPLATE>
**App entry with providers:**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final prefs = PreferencesService();
  await prefs.init();
  
  // Setup logging
  AppLogger.i('App starting in ${AppConfig.env} mode');
  
  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

// lib/app/app.dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'App',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
```

**Navigation bar:**

```dart
class AppNavigationBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const AppNavigationBar({super.key, required this.index, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (idx) {
        AppLogger.d('Navigation bar tapped: $idx');
        onTap(idx);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
```

**Section card:**

```dart
class SectionCard extends StatelessWidget {
  final String title; final Widget child; final EdgeInsetsGeometry? padding;
  const SectionCard({super.key, required this.title, required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8), child,
        ]),
      ),
    );
  }
}
```

**Feature page with error handling:**

```dart
// lib/features/profile/presentation/pages/profile_page.dart
class ProfilePage extends ConsumerWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider(userId));
    
    return AppScaffold(
      title: 'Profile',
      body: AsyncValueWidget(
        value: profileAsync,
        data: (profile) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(profile.initials),
              ),
              const SizedBox(height: 16),
              Text(profile.name, style: Theme.of(context).textTheme.headlineMedium),
              Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Edit Profile',
                onPressed: () {
                  AppLogger.d('Edit profile tapped');
                  context.push('/profile/$userId/edit');
                },
              ),
            ],
          ),
        ),
        error: (error, stack) {
          if (error is NetworkError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 64),
                  const SizedBox(height: 16),
                  Text(error.message),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Retry',
                    onPressed: () => ref.refresh(profileControllerProvider(userId)),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text('Error: ${error.toString()}'));
        },
      ),
    );
  }
}
```
</TEMPLATE>

---

## 16) Definition of Done (per PR/feature)

<CRITICAL_RULE>
**Checklist for every feature/PR:**
• Follows KISS, SoC, SSOT; no globals/singletons introduced.
• Files placed under correct feature directories.
• No hard-coded visual styles (uses Theme/ColorScheme/consts).
• All logging uses AppLogger, no print() statements.
• Error handling uses AppError sealed classes.
• Unit tests for ViewModels/Repositories with non-trivial logic.
• Accessibility pass (scaling, semantics, tap sizes).
• Analyzer passes with no warnings.
• Documentation comments added.
</CRITICAL_RULE>

---

## 17) Quick Commands & Notes

<CLAUDE_INSTRUCTION>
• **Create feature:** pages/, widgets/, controllers/, data/ in lib/features/<feature>
• **Add provider:** prefer Notifier/AsyncNotifier + provider family for params.
• **Use theme colors:** Theme.of(context).colorScheme.<role>
• **Log operations:** AppLogger.d/i/w/e for debug/info/warning/error
• **Handle errors:** Use AppError sealed classes + AsyncValue.guard
• **Breakpoints:** <600dp = phone, >=600dp = tablet/rail.
• **Dependencies in pubspec.yaml:** dio, go_router, flutter_riverpod, logger, shared_preferences, hive/sqflite

**Reminder for Claude:** If unsure, ask for the missing architectural detail (state manager, repo names, target folders) before generating large code blocks. Always use AppLogger for any logging needs, never use print().
</CLAUDE_INSTRUCTION>