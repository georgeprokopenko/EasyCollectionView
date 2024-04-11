// swift-tools-version: 5.10
// https://github.com/georgeprokopenko/EasyCollectionView

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
        .package(url: "https://github.com/layoutBox/PinLayout.git", from: "1.0.0"),
        .package(url: "https://github.com/tonyarnold/Differ.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "EasyCollectionView", 
            dependencies: ["PinLayout", "Differ"]
        ),
        .testTarget(
            name: "EasyCollectionViewTests",
            dependencies: ["EasyCollectionView"]),
    ]
)
