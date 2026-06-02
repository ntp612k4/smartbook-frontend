# SmartBook - Intelligent Reader Application

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.32.7-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-orange.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)](#)

A modern, intelligent book reading application built with Flutter and Firebase, featuring AI-powered chat, real-time synchronization, and comprehensive book management.

[Features](#-features) • [Tech Stack](#-tech-stack) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Project Structure](#-project-structure)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [API Integration](#-api-integration)
- [Deployment](#-deployment)
- [Contributing](#-contributing)
- [Troubleshooting](#-troubleshooting)
- [License](#-license)
- [Contact](#-contact)

---

## 🎯 Overview

**SmartBook** is an intelligent book reading platform that combines traditional e-reading functionality with modern AI features. Users can browse, read, and discover books while engaging with an AI chatbot for book recommendations and discussions.

**Key Highlights:**

- Cross-platform support (Android, iOS, Web, Windows, macOS, Linux)
- Real-time Firebase integration for seamless data synchronization
- AI-powered chatbot for intelligent book interactions
- Modern UI with responsive design
- Secure authentication with Google Sign-In

**Demo Video:** [Watch on YouTube](https://www.youtube.com/watch?v=3IAfKmN8pgM)

---

## ✨ Features

### Core Features

- ✅ **Book Management**
  - Browse comprehensive book catalog
  - Advanced search and filtering
  - Category-based organization (Self-help, Business, Literature, etc.)
  - Detailed book information and metadata

- ✅ **Reading Experience**
  - In-app reader with smooth scrolling
  - Rich HTML text rendering for better typography
  - Reading progress tracking with bookmark support
  - Chapter navigation (Previous/Next buttons)
  - Estimated reading time calculation

- ✅ **User Authentication**
  - Secure Google Sign-In integration
  - User profile management
  - Social features (reviews, ratings, favorites)
  - Personalized recommendations

- ✅ **AI Features**
  - AI chatbot for book recommendations
  - Real-time chat interface
  - Intelligent responses using Vector Search
  - Book summaries and insights

- ✅ **Data Synchronization**
  - Real-time Firestore sync
  - Cloud Storage for media files
  - Offline capability support
  - Cross-device data synchronization

### Additional Features

- 📊 Reading statistics and analytics
- 💾 Personal library management
- ⭐ Book ratings and community reviews
- 🔔 Smart notifications
- 🌙 Dark mode support
- 🎨 Beautiful UI with Material Design

---

## 🛠 Tech Stack

### Frontend (Mobile/Web)

- **Framework:** Flutter 3.32.7+
- **Language:** Dart 3.0+
- **State Management:** Flutter BLoC / Provider
- **UI Libraries:** Flutter ScreenUtil, Material Design
- **HTTP Client:** Dio / HTTP

### Backend & Services

- **Authentication:** Firebase Auth + Google Sign-In
- **Database:** Cloud Firestore
- **File Storage:** Firebase Storage
- **AI/Search:** Vector Search, Embeddings
- **Messaging:** Real-time Firestore

### Development & DevOps

- **Version Control:** Git
- **Build System:** Gradle (Android), Xcode (iOS)
- **Package Manager:** Pub
- **CI/CD:** GitHub Actions (recommended)
- **IDE:** VS Code / Android Studio / Xcode

### Key Dependencies

```yaml
# State Management
flutter_bloc: ^8.x.x
provider: ^6.x.x

# Firebase Services
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
firebase_storage: ^12.3.2

# Authentication
google_sign_in: ^6.2.1

# UI & Utilities
flutter_screenutil: ^5.9.0
flutter_dotenv: ^5.x.x
html: ^0.15.x
```

---

## 📋 Prerequisites

### System Requirements

- **Flutter SDK:** 3.32.7 or higher
- **Dart SDK:** 3.0 or higher
- **Android SDK:** API Level 24+ (for Android builds)
- **Xcode:** 14.0+ (for iOS builds)
- **Java JDK:** 11 or higher (for Android compilation)

### Required Tools

```bash
# Verify Flutter installation
flutter --version

# Verify Dart
dart --version

# Check complete setup
flutter doctor
```

### Firebase Setup

- Active Firebase project
- Cloud Firestore enabled
- Firebase Storage configured
- Google Sign-In enabled
- Firestore security rules configured

---

## 📦 Installation

### 1. Clone Repository

```bash
# Clone with HTTPS
git clone https://github.com/ntp612k4/smartbook.git

# Navigate to project
cd smartbook
```

### 2. Install Dependencies

```bash
# Get Flutter packages
flutter pub get

# Clean build (if needed)
flutter clean
flutter pub get
```

### 3. Firebase Configuration

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
# This generates firebase_options.dart and updates platform configs
```

### 4. Environment Setup

Create `.env` file in project root:

```bash
# Copy template if available
cp .env.example .env
```

**Example `.env` content:**

```env
FIREBASE_PROJECT_ID=smart-reader-app-f9158
API_BASE_URL=https://api.smartbook.app
DEBUG_MODE=false
LOG_LEVEL=info
```

### 5. Run Application

```bash
# Debug mode with hot reload
flutter run

# Run on specific device
flutter run -d <device_id>

# Release build
flutter build apk --release
flutter build ios --release
flutter build web
```

---

## 📁 Project Structure

```
smartbook/
├── android/                    # Android native code
│   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── google-services.json (gitignored)
│   │   └── src/
│   │       ├── main/
│   │       │   ├── AndroidManifest.xml
│   │       │   ├── kotlin/
│   │       │   └── res/
│   │       └── debug/
│   ├── gradle/
│   └── local.properties (local SDK path)
│
├── ios/                        # iOS native code
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── GoogleService-Info.plist (gitignored)
│   │   └── GeneratedPluginRegistrant.swift
│   └── Runner.xcworkspace/
│
├── lib/                        # Main Dart source
│   ├── main.dart              # App entry point
│   ├── firebase_options.dart  # Firebase config (generated, gitignored)
│   │
│   ├── models/                # Data models
│   │   ├── author.dart
│   │   ├── book.dart
│   │   ├── category.dart
│   │   ├── chapter.dart
│   │   ├── chat_message.dart
│   │   ├── reading_progress.dart
│   │   ├── review.dart
│   │   └── user.dart
│   │
│   ├── repositories/          # Data layer
│   │   ├── book_repository.dart
│   │   ├── user_repository.dart
│   │   ├── ai_chat_repository.dart
│   │   └── base_repository.dart
│   │
│   ├── screens/               # UI Screens
│   │   ├── home/
│   │   ├── onboarding/
│   │   ├── login/
│   │   ├── auth/
│   │   │   └── bloc/
│   │   ├── book_detail/
│   │   │   └── bloc/
│   │   ├── book_list/
│   │   ├── reader/
│   │   ├── profile/
│   │   ├── ai_chat/
│   │   │   └── bloc/
│   │   └── category_detail/
│   │       └── bloc/
│   │
│   ├── services/              # Business logic
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   └── notification_service.dart
│   │
│   ├── theme/                 # Design system
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   │
│   └── widgets/               # Reusable components
│       ├── buttons.dart
│       ├── book_card.dart
│       ├── author_avatar.dart
│       └── loading_indicator.dart
│
├── web/                       # Web platform
│   ├── index.html
│   ├── manifest.json
│   └── icons/
│
├── test/                      # Unit & widget tests
│   └── widget_test.dart
│
├── assets/                    # Static assets
│   ├── images/
│   │   ├── logos/
│   │   ├── icons/
│   │   └── illustrations/
│   └── screenshots/
│
├── pubspec.yaml              # Dependencies
├── pubspec.lock              # Locked versions
├── analysis_options.yaml     # Linting rules
├── .gitignore                # Git ignore patterns
├── README.md                 # This file
└── LICENSE                   # MIT License
```

---

## ⚙️ Configuration

### Firebase Configuration

Configuration is auto-generated by `flutterfire configure`:

**Generated files (in `.gitignore`):**

- `lib/firebase_options.dart` - SDK configuration
- `android/app/google-services.json` - Android config
- `ios/Runner/GoogleService-Info.plist` - iOS config

⚠️ These files contain sensitive data and should never be committed.

### Environment Variables

Create `.env` in project root:

```env
# Firebase
FIREBASE_PROJECT_ID=smart-reader-app-f9158

# API Configuration
API_BASE_URL=https://api.smartbook.app
API_TIMEOUT=30000

# Feature Flags
ENABLE_AI_CHAT=true
ENABLE_ANALYTICS=true

# Debug
DEBUG_MODE=false
LOG_LEVEL=info
```

### Firestore Security Rules

Recommended security configuration:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own documents
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Books readable by authenticated users
    match /books/{bookId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true;
    }

    // Reviews by authenticated users
    match /reviews/{reviewId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 🚀 Usage

### Running the App

```bash
# Debug mode (with hot reload)
flutter run

# Release mode
flutter run --release

# Run on specific device
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d linux         # Linux

# Verbose output for debugging
flutter run -v
```

### Building for Production

#### Android

```bash
# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

#### iOS

```bash
# Build iOS app
flutter build ios --release

# Build IPA for App Store
flutter build ipa --release
```

#### Web

```bash
# Build web app
flutter build web
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/

# Fix issues automatically
dart fix --apply
```

---

## 🔌 API Integration

### Firestore Collections

```
Database Structure:
├── users/
│   └── {userId}/
│       ├── name
│       ├── email
│       ├── profileImage
│       └── favorites[]
├── books/
│   └── {bookId}/
│       ├── title
│       ├── author
│       ├── cover
│       ├── description
│       └── chapters[]
├── chapters/
│   └── {chapterId}/
│       ├── title
│       ├── content
│       ├── bookId
│       └── order
├── reviews/
│   └── {reviewId}/
│       ├── bookId
│       ├── userId
│       ├── rating
│       └── comment
└── chat_messages/
    └── {messageId}/
        ├── userId
        ├── content
        ├── response
        └── timestamp
```

### API Calls Examples

```dart
// Get all books
final books = await BookRepository().getAllBooks();

// Get single book
final book = await BookRepository().getBookById(bookId);

// Add review
await ReviewRepository().addReview(bookId, reviewData);

// Send chat message
final response = await AIChatRepository().sendMessage(message);
```

---

## 📤 Deployment

### Firebase Hosting (Web)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Build web
flutter build web

# Deploy
firebase deploy --only hosting
```

### Google Play Store (Android)

```bash
# Generate signed APK
flutter build apk --release --split-per-abi

# Or App Bundle (recommended)
flutter build appbundle --release

# Upload via Play Console
```

### Apple App Store (iOS)

```bash
# Build release
flutter build ios --release

# Archive and upload via Xcode or Transporter
```

---

## 🤝 Contributing

### Branch Naming Convention

```bash
# Features
git checkout -b feature/your-feature-name

# Bug fixes
git checkout -b bugfix/bug-description

# Releases
git checkout -b release/v1.0.0
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** feat, fix, docs, style, refactor, test, chore

**Example:**

```
feat(reader): add page jump functionality

- Allow users to jump to specific page
- Add page input dialog
- Show current page info

Closes #123
```

### Pull Request Process

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open Pull Request
6. Wait for review and approval
7. Merge to main

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### Firebase Initialization Fails

```bash
flutterfire configure --project=smart-reader-app-f9158
flutter clean
flutter pub get
```

#### Android Build Error

```bash
./gradlew clean build
# Or
flutter clean && flutter pub get
```

#### iOS Pod Issues

```bash
cd ios/
rm -rf Pods/
cd ..
flutter clean && flutter pub get
```

#### Hot Reload Not Working

```bash
# Restart the app or press 'R' in terminal
flutter run -v
```

#### Firestore Connection Issues

- ✅ Check internet connection
- ✅ Verify Firebase project ID
- ✅ Check Firestore security rules
- ✅ Review Firebase console logs

### Debug Commands

```bash
# Verbose output
flutter run -v

# Check devices
flutter devices

# Clean rebuild
flutter clean && flutter pub get

# Check for updates
flutter pub outdated
```

---

## 📄 License

Licensed under the **MIT License** - see [LICENSE](LICENSE) for details.

---

## 📞 Contact & Support

### Project Lead

- **Email:** your.email@company.com
- **GitHub:** [@ntp612k4](https://github.com/ntp612k4)

### Support

- 📧 Email: support@smartbook.app
- 🐛 Issues: [GitHub Issues](https://github.com/ntp612k4/smartbook/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/ntp612k4/smartbook/discussions)

### Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart)

---

## 🎉 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- Community contributors

---

<div align="center">

**Made with ❤️ by the SmartBook Team**

[⬆ back to top](#smartbook---intelligent-reader-application)

</div>
