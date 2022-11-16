// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Silo",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16),
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Silo",
            targets: ["Silo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-identified-collections.git", from: "0.5.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Silo",
            dependencies: [
                .product(name: "IdentifiedCollections", package: "swift-identified-collections")
            ]
        ),
        .testTarget(
            name: "SiloTests",
            dependencies: ["Silo"]),
    ]
)
