// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PeonNotch",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "PeonNotch",
            path: "PeonNotch/Sources",
            resources: [
                .copy("../Resources")
            ]
        ),
        .executableTarget(
            name: "notch-update",
            path: "notch-update/Sources"
        ),
    ]
)
