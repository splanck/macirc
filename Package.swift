// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macirc",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "IRCKit", targets: ["IRCKit"]),
        .library(name: "NetKit", targets: ["NetKit"]),
        .library(name: "DataKit", targets: ["DataKit"]),
        .library(name: "ThemeKit", targets: ["ThemeKit"]),
        .library(name: "AppStore", targets: ["AppStore"]),
        .executable(name: "macIRCApp", targets: ["macIRCApp"])
    ],
    dependencies: [],
    targets: [
        .target(name: "IRCKit"),
        .target(name: "NetKit", dependencies: ["IRCKit"]),
        .target(name: "DataKit"),
        .target(name: "ThemeKit"),
        .target(name: "AppStore"),
        .executableTarget(
            name: "macIRCApp",
            dependencies: ["IRCKit", "NetKit", "DataKit", "ThemeKit", "AppStore"]
        ),
        .testTarget(
            name: "IRCKitTests",
            dependencies: ["IRCKit"]
        ),
        .testTarget(
            name: "NetKitTests",
            dependencies: ["NetKit"]
        ),
        .testTarget(
            name: "DataKitTests",
            dependencies: ["DataKit"]
        ),
        .testTarget(
            name: "ThemeKitTests",
            dependencies: ["ThemeKit"]
        ),
        .testTarget(
            name: "macIRCAppTests",
            dependencies: ["macIRCApp"]
        ),
        .testTarget(
            name: "AppStoreTests",
            dependencies: ["AppStore"]
        )
    ]
)
