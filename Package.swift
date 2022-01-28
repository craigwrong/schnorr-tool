// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "schnorr-tool",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto", from: "2.0.0"),
        .package(name: "Base16", url: "https://github.com/metabolist/base16", from: "1.0.0"),
    ],
    targets: [
        .binaryTarget(name: "secp256k1",
            url: "https://github.com/craigwrong/secp256k1/releases/download/22.0.1-craigwrong.1/secp256k1.xcframework.zip", checksum: "fff5415b72449331212cb75c71a47445cbe54fed061dc82153dcadbffae10f69"
                                  //path: "cmark-gfm.xcframework"
            // path: "secp256k1.xcframework"
            ),
        .target(
            name: "ECHelper",
            dependencies: ["secp256k1"]),
        .executableTarget(
            name: "schnorr-tool",
            dependencies: [
                "ECHelper",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Base16", package: "base16"),
                .product(name: "Crypto", package: "swift-crypto"),
            ]),
    ]
)
