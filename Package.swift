// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "RainbowBar",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "RainbowBar",
            targets: ["RainbowBar"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/devicekit/DeviceKit",
            .upToNextMajor(from: "2.0.0")
        )
    ],
    targets: [
        .target(
            name: "RainbowBar",
            dependencies: ["DeviceKit"],
            path: "RainbowBar"
        )
    ]
)
