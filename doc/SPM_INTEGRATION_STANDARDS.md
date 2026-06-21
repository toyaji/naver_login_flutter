# SPM_INTEGRATION_STANDARDS.md (SPM 연동 규격 및 Xcode 빌드 최적화)

이 문서는 `naver_login_flutter` 패키지에서 iOS Swift Package Manager(SPM)를 공식 연동하고 Xcode 빌드 최적화를 유지하기 위한 설계 아키텍처 및 구현 표준을 정의합니다.

---

## 🧱 1. SPM 연동 아키텍처 개요

기존 Flutter 플러그인은 CocoaPods(`.podspec`)를 통해 iOS 프레임워크와 외부 SDK를 관리했습니다. 그러나 Flutter 3.22 이상부터 공식 지원되는 **Swift Package Manager(SPM) 통합 표준**에 맞게 플러그인 빌드 파이프라인을 조정합니다.

```
+------------------------------------------+
|          Flutter Application             |
+------------------------------------------+
                     |
                     v
+------------------------------------------+
|        naver_login_flutter               |
| (Flutter Plugin Root - Package.swift)    |
+------------------------------------------+
      |                               |
      v (Native Target Build)         v (External Package Resolve)
+------------------------+  +-------------------------------------+
| ios/Classes/           |  | Naver ID Login SDK (SPM)            |
| Swift Plugin Bridge    |  | Repository: naveridlogin-sdk-ios... |
+------------------------+  +-------------------------------------+
```

---

## 📦 2. Package.swift 구성 가이드라인

패키지 루트에 위치하는 `Package.swift` 파일은 Swift 툴체인 사양과 외부 의존성을 관리합니다. 이를 수정할 때 아래 템플릿 표준을 반드시 유지해야 합니다.

### 권장 `Package.swift` 구조
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "naver_login_flutter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "naver-login-flutter",
            targets: ["naver_login_flutter"]
        )
    ],
    dependencies: [
        // Naver SDK SPM 배포처 지정
        .package(url: "https://github.com/naver/naveridlogin-sdk-ios-swift.git", from: "5.1.0"),
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "naver_login_flutter",
            dependencies: [
                .product(name: "NidThirdPartyLogin", package: "naveridlogin-sdk-ios-swift"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/naver_login_flutter"
        )
    ]
)
```

### ⚠️ SPM 적용 시 `naver_login_flutter.podspec` 수정 지침
SPM을 사용할 때 CocoaPods Podspec이 중복으로 라이브러리를 링크하면 **Linker Duplicate Symbol** 오류 또는 빌드 캐시 붕괴가 발생할 수 있습니다.
- **의존성 제외**: `.podspec` 내부에 `s.dependency 'NaverThirdPartyLogin'` 등의 구문을 완전히 삭제해야 합니다.
- Podspec은 Flutter가 SPM을 활성화하지 않았을 경우의 폴백(Fallback) 목적으로만 제공되거나, SPM이 활성화된 환경에서는 빈 프레임워크 타겟 형태로 구성되어 SPM 타겟 컴파일을 방해하지 않아야 합니다.

---

## ⚡ 3. Xcode 증분 빌드 캐시 (Incremental Build Cache) 붕괴 방지 규칙

1. **상대 경로 참조 금지**:
   - Xcode 빌드 시 외부 의존성을 로컬의 상대 경로 Pod으로 혼합하여 가져오면, 빌드할 때마다 캐시 경로가 갱신되어 캐시가 무효화됩니다. 외부 SDK는 반드시 원격 Git 저장소의 고정된 태그/버전 SPM 의존성으로만 참조하십시오.
2. **DerivedData 격리 유지**:
   - AI 에이전트는 로컬 터미널에서 Xcode 빌드를 실행할 때 특정 환경변수(`PBP_XCODE_BUILD...`)를 훼손하거나 임의의 디렉토리에서 독자적인 빌드를 시도하면 안 됩니다.
   - 플러그인 변경 사항이 메인 앱에 정상 반영되려면, 메인 앱의 Xcode 워크스페이스 상에서 빌드를 트리거하고 플러그인의 소스 파일 변경만 처리하도록 관리하십시오.

---

## 🛠️ 4. SPM 연동 검증 및 롤백 절차

개발 중 SPM 라이브러리가 Xcode에 정상적으로 캐스팅되지 않을 경우 아래 절차에 따라 청소(Clean)하고 복구합니다.

```bash
# 1. Flutter 빌드 아티팩트 청소
flutter clean

# 2. iOS 디렉토리 내 임시 빌드 아티팩트 제거
rm -rf ios/.symlinks
rm -rf ios/Pods
rm -rf ios/Podfile.lock

# 3. Xcode DerivedData 전체 삭제 (SPM 캐시 초기화)
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 4. 의존성 재생성
flutter pub get
```
이후 Xcode 또는 VS Code에서 `flutter run`을 통해 패키지 해결(Resolving Package Graph)이 성공적으로 완료되는지 점검합니다.
