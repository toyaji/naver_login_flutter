import Flutter
import NidThirdPartyLogin
import NidCore
import SafariServices
import UIKit

/// 네이버 로그인 상태를 나타내는 열거형
public enum NaverLoginStatus: String {
    case loggedIn = "loggedIn"
    case loggedOut = "loggedOut"
    case error = "error"
}

/// Flutter 플러그인 메서드를 나타내는 열거형
private enum NaverLoginPluginMethod {
    case initSdk
    case logIn
    case logOut
    case logoutAndDeleteToken
    case getCurrentAccount
    case getCurrentAccessToken
    case refreshAccessTokenWithRefreshToken
    case isLoggedIn
    case unknown
    
    init(methodName: String) {
        switch methodName {
        case "initSdk":
            self = .initSdk
        case "logIn":
            self = .logIn
        case "logOut":
            self = .logOut
        case "logoutAndDeleteToken":
            self = .logoutAndDeleteToken
        case "getCurrentAccount":
            self = .getCurrentAccount
        case "getCurrentAccessToken":
            self = .getCurrentAccessToken
        case "refreshAccessTokenWithRefreshToken":
            self = .refreshAccessTokenWithRefreshToken
        case "isLoggedIn":
            self = .isLoggedIn
        default:
            self = .unknown
        }
    }
}

/// 네이버 로그인 플러그인의 메인 클래스
@objc
public class FlutterNaverLoginPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    private var pendingResult: FlutterResult?

    // MARK: - Lifecycle

    override public init() {
        super.init()
    }

    deinit {
        // Cleanup if needed
    }

    // MARK: - Flutter Plugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterNaverLoginPlugin()
        
        // Info.plist에서 네이버 로그인 설정 값 읽기
        let infoDictionary = Bundle.main.infoDictionary
        
        guard let clientId = infoDictionary?["NidClientID"] as? String,
              let clientSecret = infoDictionary?["NidClientSecret"] as? String,
              let appName = infoDictionary?["NidAppName"] as? String,
              let urlScheme = infoDictionary?["NidUrlScheme"] as? String else {
            print("Error: Required Naver Login configuration not found in Info.plist")
            return
        }
        
        // SDK 초기화
        NidOAuth.shared.initialize(
            appName: appName,
            clientId: clientId,
            clientSecret: clientSecret,
            urlScheme: urlScheme
        )
        
        // 기본 로그인 동작 설정 (네이버 앱이 설치된 경우 네이버 앱으로 인증, 네이버 앱이 설치되어있지 않은 경우 SafariViewController를 실행해 인증하는 방식)
        NidOAuth.shared.setLoginBehavior(.appPreferredWithInAppBrowserFallback)
        
        let channel = FlutterMethodChannel(
            name: "naver_login_flutter",
            binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        // 레거시(AppDelegate) 생명주기: application(_:open:options:) 콜백 수신
        registrar.addApplicationDelegate(instance)
        // UIScene 생명주기(Flutter 신규 템플릿의 FlutterSceneDelegate):
        // scene(_:openURLContexts:) 콜백 수신. 이 경로가 없으면 SceneDelegate 기반
        // 앱에서는 로그인 콜백 URL이 플러그인까지 전달되지 않아 인증이 완료되지 않는다.
        registrar.addSceneDelegate(instance)
    }

    // MARK: - Handle Method Calls

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if pendingResult != nil {
            sendError(message: "Another request is in progress. Please wait", result: result)
            return
        }
        self.pendingResult = result
        let flutterMethod = NaverLoginPluginMethod(methodName: call.method)
        switch flutterMethod {
        case .initSdk:
            guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", 
                              message: "Arguments are required", 
                              details: nil))
            return
            }
            handleInitSdk(args)
        case .logIn:
            handleLogin()
        case .logOut:
            handleLogout()
        case .logoutAndDeleteToken:
            handleLogoutAndDeleteToken()
        case .getCurrentAccount:
            handleGetCurrentAccount()
        case .getCurrentAccessToken:
            handleGetCurrentAccessToken()
        case .refreshAccessTokenWithRefreshToken:
            handleRefreshToken()
        case .isLoggedIn:
            handleIsLoggedIn()
        case .unknown:
            pendingResult?(FlutterMethodNotImplemented)
            pendingResult = nil
        }
    }

    // MARK: - URL Callback Handling

    /// 들어온 URL이 네이버 전용 URL Scheme일 때만 SDK에 전달한다.
    /// - Returns: 네이버가 처리한 경우 `true`. 그 외에는 `false`를 반환해
    ///            다른 딥링크 플러그인이 같은 URL을 이어서 처리할 수 있도록 한다.
    private func handleNaverURL(_ url: URL) -> Bool {
        // 충돌 방지: Info.plist에 등록된 네이버 전용 URL Scheme인지 먼저 확인
        guard let scheme = Bundle.main.infoDictionary?["NidUrlScheme"] as? String,
              url.scheme?.lowercased() == scheme.lowercased() else {
            return false
        }
        return NidOAuth.shared.handleURL(url)
    }

    /// 레거시(UIApplicationDelegate) 생명주기 경로 - AppDelegate 기반 앱
    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return handleNaverURL(url)
    }

    /// UIScene 생명주기 경로 - SceneDelegate(FlutterSceneDelegate) 기반 앱.
    /// 앱이 실행 중일 때 들어오는 URL은 이 콜백으로만 전달되므로 반드시 처리해야 한다.
    @available(iOS 13.0, *)
    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        for context in URLContexts {
            if handleNaverURL(context.url) {
                return true
            }
        }
        return false
    }

    // MARK: - Handler Methods

    private func handleInitSdk(_ args: [String: Any]) {
        // Info.plist에서 네이버 로그인 설정 값 읽기
        let infoDictionary = Bundle.main.infoDictionary
        guard let clientId = infoDictionary?["NidClientID"] as? String,
              let clientSecret = infoDictionary?["NidClientSecret"] as? String,
              let appName = infoDictionary?["NidAppName"] as? String,
              let urlScheme = infoDictionary?["NidUrlScheme"] as? String else {
            sendError(message: "Required Naver Login configuration not found in Info.plist. Please check NidClientID, NidClientSecret, NidAppName, and NidUrlScheme values.")
            return
        }

        // 로그인 동작 설정
        if let behavior = args["loginBehavior"] as? String {
            switch behavior {
            case "inAppBrowser":
                NidOAuth.shared.setLoginBehavior(.inAppBrowser)
            case "app":
                NidOAuth.shared.setLoginBehavior(.app)
            case "appPreferredWithInAppBrowserFallback":
                NidOAuth.shared.setLoginBehavior(.appPreferredWithInAppBrowserFallback)
            default:
                print("Unknown login behavior: \(behavior)")
                break
            }
        }

        // SDK 초기화 완료 후 결과 전송
        sendResult(status: .loggedOut)
    }

    private func handleLogin() {
        NidOAuth.shared.requestLogin { [weak self] result in
            switch result {
            case .success(let loginResult):
                let tokenInfo: [String: Any] = [
                    "accessToken": loginResult.accessToken.tokenString,
                    "refreshToken": loginResult.refreshToken.tokenString,
                    "tokenType": "bearer",
                    "expiresAt": loginResult.accessToken.expiresAt.iso8601String()
                ]
                // 프로필 정보 조회
                self?.getUserProfile(accessToken: loginResult.accessToken.tokenString) { profileResult in
                    switch profileResult {
                    case .success(let profile):
                        self?.sendResult(status: .loggedIn, accessToken: tokenInfo, account: profile)
                    case .failure(let error):
                        self?.sendError(message: error.localizedDescription)
                    }
                }
            case .failure(let error):
                // 에러 메시지를 더 자세히 확인
                if error.localizedDescription.contains("cancel") {
                    self?.sendError(message: "Login cancelled by user")
                } else {
                    self?.sendError(message: error.localizedDescription)
                }
            }
        }
    }

    private func handleLogout() {
        NidOAuth.shared.logout()
        sendResult(status: .loggedOut)
    }

    private func handleLogoutAndDeleteToken() {
        // 먼저 토큰 삭제 시도
        NidOAuth.shared.disconnect { [weak self] result in
            switch result {
            case .success:
                // 토큰 삭제 성공 후 로그아웃 실행
                NidOAuth.shared.logout()
                self?.sendResult(status: .loggedOut)
            case .failure(let error):
                // 토큰 삭제 실패 시에도 로그아웃은 시도
                NidOAuth.shared.logout()
                self?.sendError(message: "Token deletion failed: \(error.localizedDescription)")
            }
        }
    }

    private func handleGetCurrentAccount() {
        guard let accessToken = NidOAuth.shared.accessToken?.tokenString else {
            sendError(message: "No access token available")
            return
        }

        NidOAuth.shared.getUserProfile(accessToken: accessToken) { [weak self] result in
            switch result {
            case .success(let profile):
                self?.sendResult(status: .loggedIn, account: profile)
            case .failure(let error):
                self?.sendError(message: error.localizedDescription)
            }
        }
    }

    private func handleGetCurrentAccessToken() {
        guard let token = NidOAuth.shared.accessToken else {
            sendResult(status: .loggedOut)
            return
        }

        let tokenInfo: [String: Any] = [
            "accessToken": token.tokenString,
            "refreshToken": NidOAuth.shared.refreshToken?.tokenString ?? "",
            "tokenType": "bearer",
            "expiresAt": token.expiresAt.iso8601String()
        ]

        sendResult(status: .loggedIn, accessToken: tokenInfo)
    }

    private func handleRefreshToken() {
        guard NidOAuth.shared.refreshToken != nil else {
            sendError(message: "No refresh token available")
            return
        }

        // SDK는 별도의 silent refresh API를 제공하지 않습니다.
        // reauthenticate는 재인증(UI 표시 가능) 흐름이므로,
        // Flutter 레이어의 refreshAccessTokenWithRefreshToken 메서드와 동일하게 동작합니다.
        NidOAuth.shared.reauthenticate { [weak self] result in
            switch result {
            case .success(let loginResult):
                let tokenInfo: [String: Any] = [
                    "accessToken": loginResult.accessToken.tokenString,
                    "refreshToken": loginResult.refreshToken.tokenString,
                    "tokenType": "bearer",
                    "expiresAt": loginResult.accessToken.expiresAt.iso8601String()
                ]
                self?.sendResult(status: .loggedIn, accessToken: tokenInfo)
            case .failure(let error):
                self?.sendError(message: error.localizedDescription)
            }
        }
    }

    private func handleIsLoggedIn() {
        if NidOAuth.shared.accessToken?.tokenString != nil {
            sendResult(status: .loggedIn)
        } else {
            sendResult(status: .loggedOut)
        }
    }

    // MARK: - Helper Methods

    private func getUserProfile(accessToken: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        NidOAuth.shared.getUserProfile(accessToken: accessToken) { result in
            completion(result.mapError { $0 as Error })
        }
    }

    // MARK: - Result Handling

    private func sendResult(status: NaverLoginStatus, accessToken: [String: Any]? = nil, account: [String: String]? = nil) {
        var result: [String: Any] = ["status": status.rawValue.lowercased()]
        
        if let accessToken = accessToken {
            result["accessToken"] = accessToken
        }
        
        if let account = account {
            result["account"] = account
        }
        
        DispatchQueue.main.async {
            self.pendingResult?(result)
            self.pendingResult = nil
        }
    }

    private func sendError(message: String, result: FlutterResult? = nil) {
        let errorInfo: [String: Any] = [
            "status": NaverLoginStatus.error.rawValue.lowercased(),
            "errorMessage": message
        ]
        
        DispatchQueue.main.async {
            (result ?? self.pendingResult)?(errorInfo)
            self.pendingResult = nil
        }
    }
}

extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
