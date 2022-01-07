// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "wrangler",
  platforms: [
    .macOS(.v10_15),
  ],
  dependencies: [
    .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.13.1"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/wendyliga/SwiftKit.git", from: "2.0.0"),
    .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
  ],
  targets: [
    .executableTarget(
      name: "wrangler",
      dependencies: dependencies,
      linkerSettings: linkerSettings
    ),
  ]
)

var linkerSettings: [LinkerSetting]? {
  #if os(Linux)
  return [
    .linkedLibrary("curl")
  ]
  #else
  return nil
  #endif
}

var dependencies: [Target.Dependency] {
    var deps: [Target.Dependency] = [
      "XMLCoder",
      "SwiftKit",
      .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]
    
    #if !os(Windows)
    deps.append("PathKit")
    #endif
    
    return deps
}
