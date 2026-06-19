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
2. **내 애플리케이션 > API 설정** 탭에서 **로그인 오픈 API 서비스 환경**에 **Android**와 **iOS** 플랫폼을 추가합니다.
3. 각 플랫폼별 설정 항목을 아래와 같이 등록하고 발급된 정보를 획득합니다.

#### 📱 iOS 설정 항목
* **다운로드 URL**: 서비스 중인 앱스토어 URL (개발 중에는 임의의 URL 입력 가능)
* **URL Scheme**: iOS 로그인 완료 후 앱으로 되돌아오기 위한 스키마 (예: `zellynaver`)
  > [!IMPORTANT]
  > 네이버 SDK 제약 상 URL Scheme은 **영문 소문자로만** 구성해야 정상 작동합니다.
* **Client ID** (`ConsumerKey`)
* **Client Secret** (`ConsumerSecret`)

#### 🤖 Android 설정 항목
* **다운로드 URL**: 서비스 중인 플레이스토어 URL (개발 중에는 임의의 URL 입력 가능)
* **안드로이드 앱 패키지 이름**: 프로젝트 Android 앱의 패키지명 (예: `com.example.naver_login_flutter_example`)
* **안드로이드 앱 단말기 키 해시(Key Hash)**:
  앱이 빌드될 때 사용된 인증서 서명의 키 해시 값을 등록해야 합니다. 개발 단계(디버그)와 릴리즈 단계의 키 해시가 각각 필요하며, 일치하지 않으면 로그인 시 오류가 발생합니다.

  **디버그 키 해시(Debug Key Hash) 추출 명령어:**
  * **macOS / Linux:**
    ```bash
    keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64
    ```
  * **Windows (PowerShell):**
    ```powershell
    keytool -exportcert -alias androiddebugkey -keystore $env:USERPROFILE\.android\debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64
    ```
    *(참고: `keytool` 명령어를 사용하려면 JDK가 설치되어 있어야 하며, `openssl`이 환경 변수에 등록되어 있어야 합니다.)*


### B. 자동 설정 (CLI) - 가장 권장하는 방법

네이버 개발자 센터에서 발급받은 정보를 준비한 뒤, 터미널에서 아래 명령어를 실행하면 `Info.plist`, `AndroidManifest.xml`, 환경변수 등 모든 네이티브 설정이 자동으로, 보안 원칙에 맞게 세팅됩니다.

```bash
dart run naver_login_flutter:configure
```

실행 후 화면의 안내에 따라 아래 정보를 순서대로 입력하세요:
1. `Naver App Name`
2. `Naver Client ID`
3. `Naver Client Secret` (보안을 위해 로컬 파일에만 격리 저장됩니다)
4. `iOS URL Scheme`

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
