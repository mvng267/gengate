// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GenGateiOSFoundation",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GenGateApp",
            targets: ["GenGateApp"]
        )
    ],
    targets: [
        .target(
            name: "GenGateApp",
            path: "GenGate",
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        )
    ]
)
