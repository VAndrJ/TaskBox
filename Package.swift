// swift-tools-version: 6.2

import PackageDescription

let settings: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .strictMemorySafety(),
]

let package = Package(
    name: "TaskBox",
    platforms: [
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
        .macOS(.v11),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "TaskBox",
            targets: ["TaskBox"]
        )
    ],
    targets: [
        .target(
            name: "TaskBox",
            swiftSettings: settings
        ),
        .testTarget(
            name: "TaskBoxTests",
            dependencies: ["TaskBox"],
            swiftSettings: settings
        ),
    ],
)
