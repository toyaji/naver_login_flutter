## 3.0.4
* **Android ProGuard 호환성 수정**: R8 활성화 환경에서 Naver Login SDK 내부 Koin DI 클래스가 제거/난독화되어 `NidServiceLocator.<clinit>`에서 `ClassCastException`이 발생하는 문제를 수정했습니다. `consumer-rules.pro`를 추가하여 앱 빌드 시 별도 설정 없이 자동으로 SDK 클래스가 보존됩니다.

## 3.0.3
* **가져오기 편의성 개선**: 패키지를 사용할 때 메인 패키지 파일(`package:naver_login_flutter/naver_login_flutter.dart`)만 가져와도 모든 주요 데이터 타입과 열거형에 직접 접근할 수 있도록 `export` 설정을 추가했습니다. 예제 앱 및 문서를 이에 맞추어 업데이트했습니다.

## 3.0.2
* **의존성 호환성 개선**: 다른 패키지들과의 버전 충돌을 줄이기 위해 의존성 제약을 완화했습니다.
  * `xml`: `^7.0.1` → `^6.0.0` (aws_client 등 다른 패키지와의 호환성 개선)
  * `args`: `^2.7.0` → `^2.0.0` (기본 API만 사용)
  * `path`: `^1.9.1` → `^1.8.0` (기본 API만 사용)

## 3.0.1
* **iOS & SPM 마이그레이션**: iOS를 Swift Package Manager(SPM) 전용으로 완전히 마이그레이션하고 CocoaPods 의존성을 제거했습니다. iOS `UIScene` 생명주기를 완벽 지원하여 로그인 콜백이 동작하지 않던 버그를 수정하고 URL Scheme 자동 구성 로직을 개선했습니다.
* **설정 자동화 CLI 도입**: 네이버 SDK 연동 설정을 대화형으로 자동 구성해주며, Client Secret 등 민감 정보를 분리 관리해주는 CLI 설정 도구(`dart run naver_login_flutter:configure`)를 새롭게 지원합니다.
* **Android 빌드 도구 현대화**: Gradle, Android Gradle Plugin, NDK, Kotlin 버전을 최신으로 업그레이드하고 빌드 과정을 최적화했습니다. AndroidManifest placeholder 관련 린트 및 설정 문제를 수정했습니다.
* **보안 강화 및 예제 앱 정리**: 예제 앱 내부의 민감 정보(액세스 토큰) 로그 노출을 차단하고, 불필요한 설정 파일 및 구조를 단순화했습니다.
* **품질 관리 및 CI 안정화**: 민감 정보 노출을 감지하는 workflow 추가, 정적 분석 lint ignore 규칙 무관용 적용, 전체 테스트 코드 및 구성 템플릿 린트 에러를 완전히 해결하여 빌드 및 배포 신뢰도를 높였습니다.

## 3.0.0
* **New Package Name**: Renamed to `naver_login_flutter` and officially separated from the unmaintained `flutter_naver_login`. (Note: You must update all your `import` statements!)
* **SPM Support**: Migrated iOS to support both Swift Package Manager (SPM) and CocoaPods dual support structure.
* **SDK Bump**: Updated Naver Login SDKs (Android v5.11.2, iOS v5.1.0).
* **Legacy Issues Resolved**: Migrated deprecated `NaverIdLoginSDK` to `NidOAuthCallback`, fixing various long-standing legacy iOS bugs (including #92, #86, #70, #130 from the original repo).
* **Behavior Changes**: Fixed iOS default login behavior and login state removal issues on entering background.
* **Tests & CI**: Added comprehensive unit test coverage (>90%) for data models and `MethodChannel` logic. Added GitHub Actions CI pipeline to enforce SPM build stability and code quality.
* **Documentation**: Added comprehensive project documentation, onboarding guides, and AI rules for the SPM transition.

## 2.1.1
* iOS migration guide updates
  * Added detailed migration steps from pre-2.1.0 to 2.1.0
  * Updated Info.plist key changes (naverServiceAppUrlScheme → NidUrlScheme, etc.)
  * Updated AppDelegate implementation with NidThirdPartyLogin
  * Added migration process guide with pod deintegrate steps

## 2.1.0
* Complete README.md structure overhaul
  * Clear separation of Installation, Platform Setup, Usage, and Troubleshooting sections
  * Added Korean documentation (README.ko.md)
* Version information updates
  * Updated links to official sites (pub.dev, cocoapods.org)
  * Updated Naver SDK versions (Android: v5.10.0, iOS: v5.0.0)
* Android setup enhancements
  * Added taskAffinity configuration guide
  * Detailed MainActivity setup instructions
* API documentation improvements
  * Added detailed descriptions for all major types (NaverLoginResult, NaverToken, etc.)
  * Enhanced API usage examples (login, token management, account info)
  * Added error handling examples
* Added troubleshooting guides for iOS/Android build issues
  * CocoaPods version error solutions
  * Build system error solutions
  * Proguard configuration guide

## 2.0.1
* Fix login error report twice to flutter in Android
  * Failure delivering result ResultInfo to activity : java.lang.IllegalStateException: Reply already submitted

## 2.0.0
* Upgrade flutter plugin template to latest
  * Add iOS PrivacyInfo.xcprivacy
  * Migrate to Swift
  * Support Xcode 16
  * Update min iOS version to 12 which is [Flutter supported minimum iOS version](https://docs.flutter.dev/deployment/ios#review-xcode-project-settings)
* Upgrade naver ios sdk to 4.2.3
  * [Changelog](https://github.com/naver/naveridlogin-sdk-ios/releases)
  * Fix [Xcode 16 error](https://developers.naver.com/forum/posts/36188)
* Upgrade naver android sdk to 5.10.0
  * [Changelog](https://github.com/naver/naveridlogin-sdk-android/releases)
  * Update target sdk version to 34

## 1.9.0
* update naver sdk 5.9.0
* remove naver sdk aar file, and get it from maven
* support proguard
* add workaround android device back button on FlutterFragmentActivity [flutter/#117061](https://github.com/flutter/flutter/issues/117061)
* migrate example to [AGP declarative plugins block](https://docs.flutter.dev/release/breaking-changes/flutter-gradle-plugin-apply)

## 1.8.0
* naver sdk 5.4.0
* fix issues

## 1.7.0
* naver sdk 5.2.0
* android kotlinX dependencies 

## 1.6.0
* Add User Information (mobile, birthyear, mobileE164)

## 1.5.0
* refreshAccessTokenWithRefreshToken method
* add ios expiresAt

## 1.4.0
* ios guide reademe update

## 1.3.1
* minor bugfix

## 1.3.0
* naver login sdk 5.0.1 Update
* example update

## 1.2.4
* Added logOutAndDeleteToken method instead of logout
* ios prefix k to naver
* remove ios http allow info

## 1.2.3
* refreshToken
* example ios build error fix

## 1.2.2

* null type Exception
* android naver sdk 4.2.6 update
* naverLoginResult.status error code update

## 1.2.1

* flutter 2.0.3 migration, update to null safety

## 1.2.0

* flutter 1.12 migration

## 1.1.1

* readme update

## 1.1.0

* build.gradle update
* readme update
* android logout fix

## 1.0.1

* ios13 background error fix

## 1.0.0

* ios13 pod version update

## 0.3.4

* Readme.md

## 0.3.3

* ios Naver App login enable

## 0.3.2

* ios Naver App login disable

## 0.3.1

* Android Login Cancle error fix

## 0.3.0

* migrate to AndroidX

## 0.2.1

* Readme.md

## 0.2.0

* ios issue add Readme.md

## 0.1.3

* ios swift to object-c

## 0.1.2

* ios build issue list add readme.md

## 0.1.1

* pod spec change.

## 0.1.0

* ios swift5 support.
* readme add for ios cocoapods.
* ios dependency Alamofire (5.0.0-beta.6) vesion update

## 0.0.1

* Initial release.
