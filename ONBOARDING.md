# ONBOARDING.md (개발자 및 AI 공용 온보딩 가이드)

이 문서는 `naver_login_flutter` 패키지의 개발 및 기여를 시작할 때 로컬 환경을 구성하고 연동을 테스트하는 방법을 안내합니다. 

> [!NOTE]  
> 이 문서는 로컬 환경 설치 및 기본 설정을 돕기 위한 기술 가이드입니다. 코드 수정 방법, 테스트 작성 기준, PR(Pull Request) 리뷰 프로세스 및 CI/CD 워크플로우 등 기여 전반에 관한 상세한 규칙은 **[CONTRIBUTING.md](CONTRIBUTING.md)**를 참조해 주십시오.

---

## 📌 1. 패키지 아키텍처 및 목표

본 패키지는 iOS의 `NaverThirdPartyLogin` SDK를 Swift Package Manager(SPM)를 통해 가져와 Flutter 앱과 연동되도록 지원하는 것을 최우선 목표로 합니다.

- **기존 문제**: CocoaPods와 SPM이 혼재될 때 Xcode 증분 빌드 캐시가 붕괴하여 빌드 성능이 크게 저하됨.
- **해결 방안**: 기존 CocoaPods(`podspec` dependency) 방식에서 탈피하여 SPM(`Package.swift`) 기반 네이티브 SDK 연동을 지원하고, 빌드 속도 병목을 해결함.

---

## 📂 2. 주요 폴더 구조 안내

- `lib/`: Dart 인터페이스 및 MethodChannel API 정의.
- `ios/`: Swift 기반의 iOS 네이티브 브릿지 코드 (`Classes/FlutterNaverLoginPlugin.swift`).
- `android/`: Kotlin 기반의 Android 네이티브 브릿지 코드.
- `example/`: 이 패키지를 직접 연동하여 테스트할 수 있는 예제 Flutter 앱 프로젝트.
- `test/`: Dart 단위 테스트 코드.

---

## ⚙️ 3. 개발 환경 설정 & 테스트 앱(Example) 연동

이 패키지는 플랫폼에 밀접하게 연동되므로 `example` 폴더 내의 프로젝트를 활용해 검증합니다.

### A. Naver Developers 등록 및 키 발급
1. [네이버 개발자 센터](https://developers.naver.com/)에서 애플리케이션을 등록합니다.
2. Android 및 iOS 플랫폼을 추가하여 아래 정보를 획득합니다.
   - Client ID (`ConsumerKey`)
   - Client Secret (`ConsumerSecret`)
   - URL Scheme (iOS 로그인 리다이렉션을 위함)

### B. 로컬 연동 테스트 설정 (Android/iOS)

#### 1) iOS 설정 (`example/ios/Runner/Info.plist`)
`example/ios/Runner/Info.plist`에 네이버 로그인 정보와 URL Scheme을 기입합니다.
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- 네이버 개발자 센터에 등록한 URL Scheme -->
            <string>YOUR_URL_SCHEME</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>naversearchapp</string>
    <string>naversearchthirdlogin</string>
</array>
<key>NidUrlScheme</key>
<string>YOUR_URL_SCHEME</string>
<key>NidClientID</key>
<string>YOUR_CLIENT_ID</string>
<key>NidClientSecret</key>
<string>YOUR_CLIENT_SECRET</string>
<key>NidAppName</key>
<string>YOUR_APP_NAME</string>
```

#### 2) Android 설정 (`example/android/app/src/main/res/values/strings.xml`)
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="client_id">YOUR_CLIENT_ID</string>
    <string name="client_secret">YOUR_CLIENT_SECRET</string>
    <string name="client_name">YOUR_APP_NAME</string>
</resources>
```

---

## 🧪 4. 빌드 및 테스트 실행 가이드

1. **의존성 동기화**:
   ```bash
   flutter pub get
   ```
2. **테스트 앱 실행**:
   ```bash
   cd example
   flutter pub get
   # Android 빌드 검증
   flutter build apk --debug
   ```

---

## 🔍 5. 이슈 및 문제 해결 (Troubleshooting)

- **iOS 빌드 실패 (SPM Package Resolve 오류)**:
  Xcode 캐시 충돌이 발생할 경우 다음 명령을 통해 캐시를 완전히 초기화한 후 다시 빌드합니다.
  ```bash
  rm -rf ~/Library/Caches/org.swift.swiftpm
  rm -rf ~/Library/Developer/Xcode/DerivedData
  flutter clean
  flutter pub get
  ```
- **로그인 성공 후 앱 복귀 안 됨**:
  - `Info.plist`에 입력한 `CFBundleURLSchemes`와 네이버 개발자 센터에 등록한 Scheme 값이 동일한지 재확인하십시오.
  - `AppDelegate.swift`에 `NidOAuth.shared.handleURL(url)`이 구현되어 있는지 확인하십시오.
