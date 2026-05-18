# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on a specific platform
flutter run -d chrome        # Web
flutter run -d windows       # Windows desktop

# Run tests / lint
flutter test
flutter test test/widget_test.dart   # single file
flutter analyze

# Dependencies / build
flutter pub get
flutter build web
flutter build windows
```

## Architecture

Clean Architecture, feature-first under `lib/`:

```
lib/
├── main.dart                        # runApp(MyApp())
├── app/my_app.dart                  # Root MaterialApp (currently basic placeholder)
├── core/
│   ├── dependencies/di_container.dart   # GetIt service locator (setupDI — currently empty)
│   ├── errors/                          # error_view.dart, router_error_view.dart
│   ├── observers/app_bloc_observer.dart # Global BLoC lifecycle logger
│   ├── routing/
│   │   ├── app_routes.dart              # Route constants: splashView '/', homeView, loginView
│   │   └── router_generator.dart        # GoRouter config (initial route: /login; routes commented out pending views)
│   ├── services/networking/
│   │   ├── api_consumer.dart            # Abstract HTTP interface (get/post/put/patch/delete)
│   │   ├── dio_consumer.dart            # Dio implementation; base URL http://127.0.0.1:8000/
│   │   ├── api_interceptor.dart         # Injects Authorization header
│   │   ├── api_error_handler.dart       # DioException → ApiErrorModel
│   │   └── api_error_model.dart         # {message, icon, statusCode}
│   └── utils/
│       ├── app_colors.dart              # Full clinical color palette (see below)
│       ├── app_constants.dart           # Design dimensions (375×812) + responsive breakpoints
│       ├── app_durations.dart           # Animation durations (250/500/750/1000 ms)
│       ├── app_logger.dart              # ANSI-colored console logging
│       ├── helper_functions.dart        # Arabic numeral normalization, type parsing
│       └── extensions/
│           ├── context_extensions.dart  # screenWidth/Height, scaleText, isMobileSize, isDesktopSize, isDark, isWeb…
│           └── num_extensions.dart      # .w() .h() .sp() .r() .ac() — responsive sizing
└── features/
    ├── home/
    │   └── presentation/
    │       └── views/
    │           ├── home_view.dart               # Root scaffold; uses ValueNotifier<int> for selected tab
    │           └── widgets/
    │               ├── dashboard_widget.dart    # Dashboard page content
    │               ├── home_drawer.dart         # Drawer shell (takes items, selectedIndex, onItemTap)
    │               ├── drawer_header_widget.dart # Drawer header (logo + clinic name)
    │               └── drawer_item_widget.dart  # Single animated drawer nav item
    └── reservation/
        ├── data/          # empty — ready for datasources/repos/models
        └── presentation/  # empty — ready for pages/BLoCs/widgets
```

**State management:** BLoC (`flutter_bloc ^9.1.1`). BLoC observer configured in `app_bloc_observer.dart`; no BLoCs implemented yet.

**Navigation:** GoRouter (`^17.1.0`). Routes defined in `app_routes.dart`; view builders are commented out in `router_generator.dart` pending page implementations. `my_app.dart` currently uses plain `MaterialApp` (not yet wired to GoRouter).

**HTTP:** `DioConsumer` wraps Dio with `PrettyDioLogger` and `ApiInterceptor`. The base URL points to the local FastAPI backend (`http://127.0.0.1:8000/`). Error responses map through `ApiErrorHandler` to typed `ApiErrorModel`s with HTTP and local status codes (1000–1008).

**DI:** `GetIt` via `serviceLocator` in `di_container.dart`. `setupDI()` is empty — register `DioConsumer`, repositories, and BLoCs here as features are built. `setupDI()` is not yet called from `main.dart`.

## Color Palette (`app_colors.dart`)

| Role      | Color                    |
| --------- | ------------------------ |
| Primary   | Deep Teal-Navy `#0A5C73` |
| Secondary | Steel Blue `#3A7CA5`     |
| Success   | Green `#1A8A5A`          |
| Warning   | Amber `#D4860A`          |
| Error     | Red `#BF2A2A`            |
| Info      | Blue `#1A6FA8`           |

Also exposes 9-step neutral scale and named status chips (active, scheduled, pending, critical, discharged, cancelled).

## Conventions

- When creating a new page, always add a navigation link to that page in the app header.
- New features go under `features/<name>/data/` and `features/<name>/presentation/` mirroring the `reservation/` scaffold.
- Responsive sizing uses context extensions (`.scaleWidth`, `.scaleHeight`, `.scaleText`) and num extensions (`.w()`, `.h()`, `.sp()`); avoid hardcoded pixel values.

- always use widgegts concept instead of private functions
- make each widget separated by each content
- avoid using set state if it will effect the performance or make files large instead use cubit for complex states and value notifier for simple states
- always use const where possible
- make UI design match with the good clinical systems design
- you can see all available endpoints to use through the file: `server_simulate.md`
- for the server all optional parameters make it as optional filters in the UI get the found data from the server and show it in the UI or if date deal with it as any date filteration
- **Action tracking:** after every successful write operation (add / edit / delete / confirm / cancel) call `ActionLogger.log('وصف الإجراء بالعربي')`. Import from `package:clinical_application/core/services/action_logger.dart`. Never await it in the UI — fire and forget.
- **Time display:** always show times in Arabic 12-hour format using ص (AM) and م (PM) — never raw 24-hour strings like "14:00". Use `HelperFunctions.formatTimeArabic(timeString)` for server time strings and `HelperFunctions.formatDateTimeArabic(dateTime)` for `DateTime` objects. Both helpers live in `lib/core/utils/helper_functions.dart`.
