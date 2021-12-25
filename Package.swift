// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "RequestKit",
    products: [
        .library(name: "RequestKit", targets: ["RequestKit"])
    ],
    targets: [
        .target(name: "RequestKit", dependencies: [], exclude:["Info.plist"]),
        .testTarget(name: "RequestKitTests", dependencies: ["RequestKit"], exclude:["Info.plist"])
   ],
   swiftLanguageVersions: [.version("3.0"), .version("4.0"), .version("4.1"), .version("4.2")]
)
