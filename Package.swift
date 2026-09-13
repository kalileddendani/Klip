// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Klip",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Klip",
            path: "Sources/Klip",
            exclude: ["Info.plist", "Klip.entitlements"],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AppKit"),
            ]
        )
    ]
)
