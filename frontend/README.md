# YouTube Automation Frontend

A Flutter cross-platform application for YouTube channel discovery and analysis with real-time progress via SSE.

## Features

- **Channel Discovery**: Search and browse YouTube channels
- **AI Analysis**: Real-time batch analysis driven by backend SSE
- **CSV Export**: Export analyzed data
- **Cross-Platform**: Web, Android, iOS, macOS, Windows, Linux

## Architecture

- **Framework**: Flutter + GetX
- **UI**: Material Design
- **State Management**: GetX controllers + view models (MVVM-ish)
- **API**: REST + SSE via `ApiWrapper` and `SSEClient`

## Getting Started

### Prerequisites

- Flutter SDK (>=3.4.3)
- Dart SDK

### Setup

```bash
flutter pub get
# Web
flutter run -d chrome
```

### Configuration

- Base URL is defined in `lib/data/remote/apis.dart` (`Endpoints.baseUrl`).
  - Default points to the hosted backend.
  - For local dev, switch to:
    ```dart
    static const String baseUrl = 'http://localhost:3000/api/';
    ```
- The app initializes an `ApiWrapper`, `SSEClient`, and Firebase in `lib/main.dart` during `initialize()`.

## Project Structure

```
lib/
├── controllers/          # GetX controllers
├── view_models/          # Business logic
├── repositories/         # Data access
├── data/                 # API wrapper, endpoints, SSE client
├── models/               # DTOs
├── views/                # Screens
├── widgets/              # UI components
├── res/                  # constants, styles, navigation
└── utils/                # helpers, extensions, validators
```

## Development Notes

- Use `dart format` and follow the Dart style guide.
- Null safety is enforced.
- Entry point and variant switching are in `lib/main.dart`.

## License

Private project — All rights reserved.
