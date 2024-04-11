// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EasyCollectionView",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "EasyCollectionView",
            targets: ["EasyCollectionView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/layoutBox/PinLayout.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "EasyCollectionView", 
            dependencies: ["PinLayout"]
        ),
        .testTarget(
            name: "EasyCollectionViewTests",
            dependencies: ["EasyCollectionView"]),
    ]
)
