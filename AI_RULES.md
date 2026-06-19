# AI_RULES.md (AI Agent Guidelines)

이 규칙은 `naver_login_flutter` 패키지의 개발, 수정, 버그 수정 및 유지보수에 참여하는 모든 AI 에이전트(Gemini, Claude, GPT 등)가 반드시 준수해야 하는 행동 제약사항 및 프로세스입니다.

---

## 🎯 1. 핵심 원칙 (Core Principles)

1. **최소 수정 원칙 (Minimal Changes)**:
   - 사용자가 요청한 버그 수정 또는 신규 기능 추가와 무관한 포맷팅 정렬, 주석 삭제, 단순 변수명 리팩토링은 절대 금지합니다.
2. **Swift Package Manager (SPM) 우선 원칙**:
   - iOS 의존성을 추가하거나 업데이트할 때 CocoaPods(Podfile, Podspec의 dependency)를 사용하지 않고, 반드시 Swift Package Manager(`Package.swift`)를 사용해야 합니다.
3. **네이티브 SDK 호환성 존중**:
   - 네이버 로그인 iOS SDK는 버전에 따라 모듈명이 `NaverThirdPartyLogin` 또는 `NidThirdPartyLogin`으로 변경되었습니다. 이를 변경할 때는 헤더 임포트 및 관련 API 서명(`NidOAuth.shared`)이 정상 매핑되는지 검증해야 합니다.
4. **린트(Lint) 에러 확인 의무화**:
   - 코드 작업 후에는 반드시 `flutter analyze` 또는 `dart analyze`를 실행하여 새로운 린트 에러가 발생하지 않았는지 확인하고 즉시 수정해야 합니다.

---

## 🛑 2. 절대 금지 조항 (Critical Constraints)

- **[FORBIDDEN] 임의의 Git 푸시 및 커밋 금지**:
   - 작업 중 `git push` 명령어는 **절대** 사용자의 명시적인 허락 없이 실행해서는 안 됩니다.
   - 로컬 작업물을 함부로 `git commit` 하거나 푸시하여 기존 작업 흐름을 방해하지 마십시오.
- **[FORBIDDEN] 임의의 `pod` 명령어 실행 금지**:
   - `pod install`, `pod update`, `pod deintegrate` 명령을 AI가 단독으로 백그라운드에서 실행하지 마십시오.
   - 단, SPM 연동을 완전하게 초기화하기 위한 목적의 안내가 필요한 경우 사용자 승인 하에 실행하도록 제안만 가능합니다.
- **[FORBIDDEN] Git Worktree 내 iOS 시뮬레이터 빌드 금지**:
   - Worktree 경로(예: `.claude/worktrees/`, `.gemini/antigravity/worktrees/` 등)에서는 Xcode 증분 빌드 캐시가 붕괴하여 빌드 시간이 170초 이상으로 증가할 수 있으므로, `flutter run` 또는 `flutter build`를 실행하지 마십시오.
   - 오직 `flutter analyze --no-pub`, `dart analyze`, `flutter test --no-pub` 등 빌드를 유발하지 않는 정적 분석 명령만 허용됩니다.
- **[FORBIDDEN] Deprecated API 사용**:
   - Flutter/Dart SDK 최신 버전을 기준으로 deprecated된 API(예: `withOpacity`)를 새 코드에 삽입하지 마십시오. (대체 API: `withValues(alpha: value)`)

---

## ⚙️ 3. Method Channel & Native Bridge 구현 규칙

Dart API(`lib/`)와 Native SDK(`ios/`, `android/`) 간의 브릿지 코드 수정 시 다음 규칙을 따릅니다.

1. **Null-Safety 및 타입 변환**:
   - Method Channel을 통해 데이터를 전달할 때 Map의 Key가 누락되거나 Value가 Null인 상황을 기본값 처리(`??`) 또는 Safe Cast를 통해 예방하십시오.
   - 예외가 발생할 경우 사전에 에러를 캐치하여 Flutter 플랫폼 예외(`PlatformException`)로 상세 에러 코드(예: `UNAUTHORIZED`, `NETWORK_ERROR`)와 메시지를 함께 반환해야 합니다.
2. **네이티브 호출 비동기 응답**:
   - iOS(Swift) 및 Android(Kotlin)의 Naver SDK 메서드는 비동기(Callback)로 동작하므로 Flutter MethodChannel `result` 전달이 누락되거나 중복 호출(Double-Reply)되지 않도록 Callback 흐름을 스레드 안전하게 보장해야 합니다.

---

## 🚀 4. 배포 체크리스트 (Release Preparation)

**새로운 버전을 배포할 때 반드시 다음 파일들의 버전을 모두 업데이트해야 합니다:**

- [ ] `pubspec.yaml` - `version:` 필드
- [ ] `ios/naver_login_flutter.podspec` - `s.version`
- [ ] `README.md` - `dependencies:` 섹션의 버전 예제
- [ ] `CHANGELOG.md` - 새 버전 섹션 추가 (한국어로 변경사항 명시)

**의존성 버전 검토:**
- [ ] 각 의존성이 정말 필요한 버전인지 검토 (라이브러리는 느슨한 제약 선호)
- [ ] 인기 있는 다른 패키지와의 호환성 충돌 여부 확인
- [ ] `pub.dev` 발행 전 드라이런 테스트: `dart pub publish --dry-run`

**병합 후 배포:**
- [ ] PR 병합
- [ ] `dart pub publish` 실행
- [ ] GitHub Releases에 태그 생성

---

## 🧪 5. 작업 완료 전 자가 검증 프로세스

AI 에이전트는 작업을 마친 후 아래 단계를 순서대로 수행하여 컴파일 및 린트 상태를 검증한 뒤 결과를 요약 보고해야 합니다. 또한 기여(PR) 제출 전에 **[CONTRIBUTING.md](CONTRIBUTING.md)**에 기술된 테스트 커버리지 요구 사항 및 CI/CD 검증 기준을 완벽하게 충족해야 합니다.

1. **정적 분석**:
   ```bash
   flutter analyze
   ```
   *검증 기준*: 경고 및 에러가 0개여야 합니다.
2. **단위 테스트**:
   ```bash
   flutter test
   ```
   *검증 기준*: 모든 테스트 케이스가 성공해야 합니다.
3. **Example 프로젝트 검증**:
   - `example/` 디렉토리에 정의된 예제 프로젝트가 정상 컴파일되는지 점검합니다.
   ```bash
   cd example
   flutter build apk --debug
   # iOS의 경우 Xcode/SPM 빌드 환경을 해치지 않는 범위 내에서 분석만 수행
   ```
4. **민감 정보 스캔**:
   - 수정한 코드 내에 네이버 개발자 센터 Client ID, Client Secret 등의 테스트용 키가 하드코딩되지 않았는지 확인합니다.
