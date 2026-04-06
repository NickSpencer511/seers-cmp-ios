// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SeersCMP",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "SeersCMP", targets: ["SeersCMP"]),
    ],
    targets: [
        .target(name: "SeersCMP", path: "Sources/SeersCMP"),
    ]
)
