# SmartBook - Intelligent Reader Application

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.32.7-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-orange.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modern intelligent book reading application with AI-powered features, Firebase integration, and cross-platform support.

[Features](#-features) • [Tech Stack](#-tech-stack) • [Installation](#-installation) • [Usage](#-usage) • [Contributing](#-contributing)

</div>

---

## Overview

**SmartBook** is an intelligent book reading platform combining traditional e-reading with modern AI features. Users can browse, read, and discover books with AI chatbot assistance for recommendations and discussions.

**Demo:** [YouTube](https://www.youtube.com/watch?v=3IAfKmN8pgM)

---

## Features

- Browse and discover books with advanced search & filtering
- User authentication with Google Sign-In
- Rich reading experience with HTML content rendering
- Book ratings, reviews, and personal library management
- AI chatbot for book recommendations and discussions
- Real-time Firestore synchronization
- Reading progress tracking and analytics
- Dark mode & responsive UI design
- Cross-platform support (Android, iOS, Web, Windows, macOS, Linux)

---

## 🛠 Tech Stack

**Frontend:** Flutter 3.32.7+, Dart 3.0+, BLoC Pattern  
**Backend:** SmartBook Backend API, Firebase (Auth, Firestore, Storage)  
**AI:** Gemini chat, optional RAG with MongoDB vector search  
**Build:** Gradle (Android), Xcode (iOS)

---

## Prerequisites

```bash
# Verify installations
flutter --version     # 3.32.7+
dart --version       # 3.0+
flutter doctor       # Complete setup check
```

**Requirements:**

- Flutter SDK 3.32.7+
- Dart SDK 3.0+
- Android SDK API 24+ (for Android)
- Xcode 14.0+ (for iOS)
- Java JDK 11+ (for Android build)
- Active Firebase project

---

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/ntp612k4/smartbook.git
cd smartbook
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Set Environment Variables

Create `.env` file:

```env
# Local backend running on this Windows machine.
baseURL=http://127.0.0.1:5001

# Physical phone on the same Wi-Fi:
# baseURL=http://YOUR_WINDOWS_WIFI_IP:5001

# VM backend:
# baseURL=http://YOUR_VM_EXTERNAL_IP:3000
```

### 5. Run Application

```bash
flutter run
```

### 6. Run on LDPlayer with Local Backend

LDPlayer cannot automatically reach the Windows `localhost`. Start the backend first, then run:

```bash
adb connect 127.0.0.1:5555
adb -s 127.0.0.1:5555 reverse tcp:5001 tcp:5001
flutter run -d 127.0.0.1:5555
```

## Usage

```bash
# Debug with hot reload
flutter run

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release

# Build Web
flutter build web

# Run tests
flutter test

# Code analysis
flutter analyze
dart format lib/
```

---

## Project Structure

```
lib/
├── main.dart           # App entry point
├── models/             # Data models
├── repositories/       # Data layer & APIs
├── screens/            # UI Screens with BLoC
├── services/           # Business logic
├── theme/              # Design system
└── widgets/            # Reusable components
```

---

## Security

- Sensitive files in `.gitignore`: `firebase_options.dart`, `google-services.json`
- Google Sign-In for authentication
- Firestore security rules enforced
- Never commit `.env` or credential files

---

## Contributing

```bash
# Create feature branch
git checkout -b feature/your-feature

# Commit with conventional messages
git commit -m "feat(scope): description"

# Push and open Pull Request
git push origin feature/your-feature
```

**Commit Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

## Contact

- **GitHub:** [@ntp612k4](https://github.com/ntp612k4)
- **Issues:** [GitHub Issues](https://github.com/ntp612k4/smartbook/issues)
- **Email:** support@smartbook.app

---

## License

MIT License - see [LICENSE](LICENSE) for details

---

## 🔗 Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Docs](https://firebase.google.com/docs)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart)

---

<div align="center">

Made with by SmartBook Team

</div>
