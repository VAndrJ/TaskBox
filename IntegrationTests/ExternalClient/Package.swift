// swift-tools-version: 6.2

import PackageDescription

let settings: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .strictMemorySafety(),
]

let package = Package(
    name: "TaskBoxExternalClient",
    platforms: [
        .macOS(.v11)
    ],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "TaskBoxExternalClient",
            dependencies: [
                .product(name: "TaskBox", package: "TaskBox")
            ],
            swiftSettings: settings
        )
    ]
)
