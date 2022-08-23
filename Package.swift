// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ListPlaceholder",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "ListPlaceholder", targets: ["ListPlaceholder"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "ListPlaceholder", dependencies: [], path: "ListPlaceholder/Classes"),
    ]
)
