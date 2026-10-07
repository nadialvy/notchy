// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Notchy",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "NotchyKit"),
        .executableTarget(name: "notchy-hook", dependencies: ["NotchyKit"]),
        .executableTarget(name: "Notchy", dependencies: ["NotchyKit"]),
    ]
)
