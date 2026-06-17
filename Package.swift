// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NotchFlow",
    platforms: [
        // Designed for macOS Monterey (12) and newer. Builds for both
        // Apple Silicon and Intel via the standard universal toolchain.
        .macOS(.v12)
    ],
    products: [
        .executable(name: "NotchFlow", targets: ["NotchFlow"])
    ],
    targets: [
        .executableTarget(
            name: "NotchFlow",
            path: "Sources/NotchFlow"
        )
    ]
)
