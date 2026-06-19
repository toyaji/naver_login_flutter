# naver_login_flutter
[![Build Status](https://img.shields.io/badge/pub-v3.0.0-success.svg)](https://pub.dev/packages/naver_login_flutter)
[![Build Status](https://img.shields.io/badge/naverAosSDK-v5.10.0-success.svg)](https://github.com/naver/naveridlogin-sdk-android)
[![Build Status](https://img.shields.io/badge/naverIosSDK-v5.0.0-success.svg)](https://github.com/naver/naveridlogin-sdk-ios-swift)
[![Build Status](https://img.shields.io/badge/build-passing-success.svg)](https://github.com/toyaji/naver_login_flutter)

A Flutter plugin for using the native Naver Login SDKs on Android and iOS.

## AndroidX support

- for [AndroidX Flutter projects](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)

## Migration 
- [Migrating from `flutter_naver_login` to `naver_login_flutter` 3.0.0](#migrating-from-flutter_naver_login-to-naver_login_flutter-300)

## 📌 Fork Background & Purpose

This repository is a **dedicated fork** of [yoonjaepark/flutter_naver_login](https://github.com/yoonjaepark/flutter_naver_login). The package has been renamed to `naver_login_flutter` to mark its independence and major structural improvements.

### Why this Fork exists?
* **2026 CocoaPods Deprecation Response**: Apple and the Flutter ecosystem are phasing out CocoaPods (switching to read-only mode by the end of 2026). This plugin is refactored to fully support **Swift Package Manager (SPM)** native dependency mapping on iOS.
* **Xcode Build Speed Optimization**: Mixing CocoaPods and SPM in large projects (such as Zelly) invalidates the Xcode incremental build cache, causing significant compilation bottlenecks (often over 170 seconds). By transitioning this package to SPM, we restore build caching functionality.
* **Active Community Maintenance**: As the original repository lacks frequent updates, this fork ensures compatibility with the latest Flutter stable versions and native SDK revisions.

## 📚 Onboarding & AI Guidelines
This repository contains specialized documentation for developers and AI agents:
- [ONBOARDING.md](ONBOARDING.md): Step-by-step local setup, Naver Console setup, and local example project configuration.
- [AI_RULES.md](AI_RULES.md): Strict development rules, Xcode build cache safety guidelines, and self-verification flows for AI agents (Gemini, Claude, GPT, etc.).
- [SPM_INTEGRATION_STANDARDS.md](doc/SPM_INTEGRATION_STANDARDS.md): Technical specifications of the Swift Package Manager (SPM) bridge architecture and clean-up guides.

## Installation

### 1. Add dependency
Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  naver_login_flutter: ^3.0.0
```

### 2. Configure Native Projects (Recommended)

`naver_login_flutter` provides an automated configuration tool that safely injects your API keys into the correct iOS and Android configuration files while properly isolating your **Client Secret** into gitignored local files.

Run the interactive setup tool from the root of your Flutter project:

```bash
dart run naver_login_flutter:configure
```

You can also pass arguments directly:
```bash
dart run naver_login_flutter:configure --app-name="Your App" --client-id="xxx" --client-secret="yyy" --url-scheme="zzz"
```

> **Note:** If you prefer not to use the CLI and need to configure your projects manually, you must still follow our secure secret management approach. Do not hardcode your client secret directly into public configuration files. See the **[Manual Configuration Guide](doc/MANUAL_CONFIGURATION.md)** for step-by-step instructions.



## Migration Guide

### Migrating from `flutter_naver_login` to `naver_login_flutter` 3.0.0

Since this package is a fork that transitioned to **Swift Package Manager (SPM)** and separated from the original `flutter_naver_login`, you must perform the following steps to migrate:

#### 1. Update `pubspec.yaml`
Remove the old package and add the new one:
```yaml
dependencies:
  # Remove: flutter_naver_login: ^2.x.x
  naver_login_flutter: ^3.0.0
```

#### 2. Update Dart Imports
Find and replace all your import statements:
```dart
// Before
import 'package:flutter_naver_login/flutter_naver_login.dart';

// After
import 'package:naver_login_flutter/naver_login_flutter.dart';
```

#### 3. iOS Clean Build (Crucial for SPM Transition)
Because the old package used CocoaPods and the new one uses SPM natively, you **must** clean your iOS build cache to prevent conflicts:
```bash
cd ios
pod deintegrate
rm -rf Podfile.lock Pods/
cd ..
flutter clean
flutter pub get
```


## Usage

### Types

#### NaverLoginResult
```dart
class NaverLoginResult {
  final NaverLoginStatus status;
  final NaverAccountResult? account;
}
```

#### NaverToken
```dart
class NaverToken {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String expiresAt;
  
  bool isValid();
}
```

#### NaverAccountResult
```dart
class NaverAccountResult {
  final String id;
  final String nickname;
  final String name;
  final String email;
  final String gender;
  final String age;
  final String birthday;
  final String birthyear;
  final String profileImage;
  final String mobile;
  final String mobileE164;
}
```

#### NaverLoginStatus
```dart
enum NaverLoginStatus {
  loggedIn,
  loggedOut,
  error
}
```

### API Examples

#### Login
```dart
try {
  final NaverLoginResult res = await FlutterNaverLogin.logIn();
  if (res.status == NaverLoginStatus.loggedIn) {
    // Login successful
    final account = res.account;
    print('User name: ${account?.name}');
  }
} catch (error) {
  print('Login failed: $error');
}
```

#### Get Current Access Token
```dart
try {
  final NaverToken token = await FlutterNaverLogin.getCurrentAccessToken();
  if (token.isValid()) {
    print('Access Token: ${token.accessToken}');
    print('Refresh Token: ${token.refreshToken}');
    print('Token Type: ${token.tokenType}');
    print('Expires At: ${token.expiresAt}');
  }
} catch (error) {
  print('Failed to get token: $error');
}
```

#### Get Current Account
```dart
try {
  final NaverAccountResult account = await FlutterNaverLogin.getCurrentAccount();
  print('User name: ${account.name}');
  print('User email: ${account.email}');
  print('User profile: ${account.profileImage}');
} catch (error) {
  print('Failed to get account: $error');
}
```

#### Logout
```dart
try {
  final NaverLoginResult res = await FlutterNaverLogin.logOut();
  if (res.status == NaverLoginStatus.loggedOut) {
    // Logout successful
  }
} catch (error) {
  print('Logout failed: $error');
}
```

#### Logout and Delete Token
```dart
try {
  final NaverLoginResult res = await FlutterNaverLogin.logOutAndDeleteToken();
  if (res.status == NaverLoginStatus.loggedOut) {
    // Logout and token deletion successful
  }
} catch (error) {
  print('Logout and token deletion failed: $error');
}
```

## Troubleshooting

### iOS Issues

1. **SPM Cache / Xcode Build Errors**
   - Since this package uses Swift Package Manager (SPM) natively, you may occasionally encounter Xcode caching issues (e.g., missing module errors).
   - Solution: Clear Xcode's DerivedData and the Flutter build cache:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   ```

2. **Minimum iOS Version**
   - The Naver Login SDK requires iOS 13.0 or higher.
   - Solution: Ensure your `ios/Podfile` (if you have one for other plugins) is set to `platform :ios, '13.0'` or higher.

### Android Issues

1. **Missing Configuration Crashes**
   - If the app crashes on launch or when attempting to log in, it is usually because the Naver API keys are missing from your `AndroidManifest.xml` or `build.gradle.kts`.
   - Solution: Re-run the automated tool `dart run naver_login_flutter:configure` and verify that `android/local.properties` contains your `naver.client_secret`.

## 🤝 Contributing & AI Agent Collaboration

This project is open-source and actively welcomes contributions from both **human developers** and **AI agents** (Gemini, Claude, GPT, etc.). 

Please refer to our **[CONTRIBUTING.md](CONTRIBUTING.md)** for detailed instructions on:
* Environment setup and self-verification flows.
* Specialized build warnings and constraints for AI agents.
* Automated testing and GitHub Actions CI pipelines.
* Code review and pull request approval workflows.

## License

This project is licensed under the BSD 2-Clause License - see the LICENSE file for details.
