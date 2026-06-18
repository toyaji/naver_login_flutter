// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_naver_login",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "flutter-naver-login",
            targets: ["flutter_naver_login"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/naver/naveridlogin-sdk-ios-swift.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "flutter_naver_login",
            dependencies: [
                .product(name: "NidThirdPartyLogin", package: "naveridlogin-sdk-ios-swift"),
            ],
            path: "Sources/flutter_naver_login"
        )
    ]
)
