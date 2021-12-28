// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "asf_sam_complete_all_achievement",
  platforms: [
    .macOS(.v10_15),
  ],
  dependencies: [
    .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.13.1"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
  ],
  targets: [
    .executableTarget(
      name: "asf_sam_complete_all_achievement",
      dependencies: [
        "XMLCoder",
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ]),
  ]
)
