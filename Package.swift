// swift-tools-version: 5.5

import PackageDescription

let package = Package(
  name: "Bonsai",
  products: [
    .library(
      name: "Bonsai",
      targets: ["Bonsai"]
    ),
  ],
  targets: [
    .target(
      name: "Bonsai"
    ),
    .executableTarget(
      name: "BonsaiBenchmark",
      dependencies: ["Bonsai"],
      path: "Benchmark",
      exclude: ["fixture.html"]
    ),
    .testTarget(
      name: "BonsaiTests",
      dependencies: ["Bonsai"]
    ),
  ]
)
