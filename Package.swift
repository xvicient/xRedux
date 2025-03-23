// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "xRedux",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "xRedux",
            targets: ["xRedux"]
        ),
        .library(
            name: "xReduxTest",
            targets: ["xReduxTest"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "xRedux",
            dependencies: [],
            path: "Sources/xRedux"
        ),
        .target(
            name: "xReduxTest",
            dependencies: [
                "xRedux"
            ],
            path: "Sources/xReduxTest"
        )
    ]
)
