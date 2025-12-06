// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Iskra",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // Vapor — A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .executableTarget(
            name: "Iskra",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "IskraTests",
            dependencies: [
                .target(name: "Iskra"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
