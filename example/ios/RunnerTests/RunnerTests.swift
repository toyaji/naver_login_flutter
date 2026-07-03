import Flutter
import NidCore
import UIKit
import XCTest

@testable import naver_login_flutter

// Naver SDK가 로그아웃 직후 재로그인 시 공유 URLSession 커넥션 풀 문제로
// NSURLErrorNetworkConnectionLost(-1005)를 반환하는 경우가 있어, 해당 에러만
// 선별해 1회 재시도한다. 이 판별 로직을 검증한다. (참고: naver/naveridlogin-sdk-ios-swift#6)
class RunnerTests: XCTestCase {

  func testIsNetworkConnectionLostError_matchesNetworkConnectionLost() {
    let plugin = FlutterNaverLoginPlugin()
    let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)
    let error = NidError.serverError(.networkError(underlying))

    XCTAssertTrue(plugin.isNetworkConnectionLostError(error))
  }

  func testIsNetworkConnectionLostError_ignoresOtherNetworkErrorCodes() {
    let plugin = FlutterNaverLoginPlugin()
    let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
    let error = NidError.serverError(.networkError(underlying))

    XCTAssertFalse(plugin.isNetworkConnectionLostError(error))
  }

  func testIsNetworkConnectionLostError_ignoresNonServerErrors() {
    let plugin = FlutterNaverLoginPlugin()
    let error = NidError.clientError(.canceledByUser)

    XCTAssertFalse(plugin.isNetworkConnectionLostError(error))
  }
}
