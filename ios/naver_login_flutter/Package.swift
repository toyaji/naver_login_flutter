// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/naver/naveridlogin-sdk-ios-swift.git", from: "5.0.0"),
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "naver_login_flutter",
            dependencies: [
                .product(name: "NidThirdPartyLogin", package: "naveridlogin-sdk-ios-swift"),
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            path: "Sources/naver_login_flutter"
        )
    ]
)
