// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "humane-swift",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "Humane", targets: ["Humane"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
    ],
    targets: [
        .target(name: "Humane"),

        .testTarget(
            name: "HumaneTests",
            dependencies: [
                "Humane",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
            ]
        ),
    ]
)
