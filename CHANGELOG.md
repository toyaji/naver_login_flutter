## 3.2.1
* **iOS SPM 빌드 실패 수정**: `Package.swift`가 네이버 iOS SDK를 `from: "5.1.0"`(다음 메이저 직전까지)로 열어둬서, `Package.resolved` 없이 새로 해석할 때 SwiftPM이 iOS 15를 요구하는 5.2.x를 선택했고, iOS 13을 선언한 플러그인 패키지 타겟과 충돌해 빌드가 깨지던 문제를 수정했습니다. 제약을 `.upToNextMinor(from: "5.1.0")`(= `>=5.1.0 <5.2.0`)로 좁혀 CocoaPods의 `~> 5.1.0`과 동일 범위로 맞췄습니다. 최소 iOS 버전 변경은 없습니다. ([#21](https://github.com/toyaji/naver_login_flutter/issues/21))

## 3.2.0
* **`isLoggedIn()` 예외 발생 수정**: `FlutterNaverLogin.isLoggedIn()`이 로그인 상태와 무관하게 항상 타입 오류로 실패하던 문제를 수정했습니다. 네이티브가 다른 메서드와 동일하게 `{"status": ...}` Map을 반환하는데 Dart가 `bool`로 읽고 있던 것이 원인입니다. 네이티브 동작 변경은 없습니다. ([#18](https://github.com/toyaji/naver_login_flutter/issues/18))
* **Android client secret 로그 노출 수정**: Android 플러그인이 `println`으로 client secret 전문을 logcat에 출력하던 문제를 수정했습니다. 이제 앞 3자와 길이만 남긴 마스킹 값(`abc******* (10 chars)`)으로 출력되어, 설정이 제대로 주입됐는지는 확인하면서도 값 자체는 노출되지 않습니다. ([#17](https://github.com/toyaji/naver_login_flutter/issues/17))
* **로그 출력 제어 추가**: 플러그인이 등록 시점에 무조건 SDK 로그를 켜던 동작을 제거하고, 앱이 로그 출력을 제어할 수 있도록 했습니다. ([#17](https://github.com/toyaji/naver_login_flutter/issues/17))
  * `FlutterNaverLogin.setLogEnabled(bool)` API로 런타임에 켜고 끌 수 있습니다.
  * Android 초기값은 `AndroidManifest.xml`의 `com.naver.sdk.logEnabled` 메타데이터를 따르며, 값이 없으면 앱의 debuggable 여부를 따릅니다. 즉 릴리스 빌드에서는 기본으로 꺼집니다.
  * iOS 초기값은 디버그 빌드에서 켜지고 릴리스 빌드에서 꺼집니다. 단 네이버 iOS SDK는 로그 on/off API를 제공하지 않아 SDK 내부 로그는 제어 대상이 아닙니다.
  * 플러그인의 나머지 진단 로그도 동일한 스위치를 따르며, `android.util.Log`를 사용하도록 변경했습니다. 설정 누락 등 초기화 실패 로그는 원인 파악을 위해 스위치와 무관하게 항상 출력됩니다.

## 3.1.2
* **Android 로그인 결과 accessToken 누락 수정**: Android에서 `login()` 성공 시 `NaverLoginResult.accessToken`이 항상 `null`로 반환되던 문제를 수정했습니다. 이제 iOS와 동일하게 로그인 결과에 토큰 정보(accessToken, refreshToken, tokenType, expiresAt)가 포함됩니다. ([#14](https://github.com/toyaji/naver_login_flutter/issues/14))
* **Android 16 screenOrientation 크래시 수정**: Android 15/16의 strict mode 정책으로 인해 Naver SDK의 `NidOAuthCustomTabActivity`에서 발생하던 크래시를 수정했습니다. 플러그인 매니페스트에서 해당 액티비티의 `screenOrientation`을 `unspecified`로 오버라이드합니다. ([#13](https://github.com/toyaji/naver_login_flutter/issues/13))

## 3.1.1
* **iOS 로그인 재시도 로직 제거 (롤백)**: v3.0.5(및 v3.1.0)에 추가되었던 `-1005 (NSURLErrorNetworkConnectionLost)` 에러 발생 시 자동 로그인 재시도하는 로직을 제거했습니다. 실제 환경에서 에러가 정상 판별되지 않고, 강제 재시도 시 네이버 앱이 연속으로 2회 실행되어 부자연스러운 사용자 흐름을 만드는 UX 결함이 식별되어 롤백 조치했습니다. 해당 이슈는 네이버 네이티브 iOS SDK 측의 자체적인 커넥션 풀 문제로, 추후 네이티브 SDK 업데이트 버전이 릴리즈되면 수정 버전을 제공할 예정입니다.

## 3.1.0
* **Built-in Kotlin & SDK Update**: Bumped minimum Flutter SDK to 3.44.0 to support Built-in Kotlin. Removed explicit `kotlin-android` plugin application from Android Gradle scripts to prevent future build failures.
* **CocoaPods Removal**: Removed CocoaPods integration from the example iOS project.

## 3.0.5
* **iOS 재로그인 네트워크 오류 완화**: 로그아웃 직후 재로그인 시 Naver SDK 내부 URLSession 커넥션 풀 문제로 `NSURLErrorNetworkConnectionLost(-1005)`가 발생하는 경우가 있어, 해당 에러에 한해 로그인을 1회 자동 재시도하도록 했습니다. 네이버 SDK 측 권고에 따른 완화 조치이며, 그 외 로그인 동작에는 영향이 없습니다. ([naver/naveridlogin-sdk-ios-swift#6](https://github.com/naver/naveridlogin-sdk-ios-swift/issues/6))

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
