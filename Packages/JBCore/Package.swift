// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JBCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "JBGeo", targets: ["JBGeo"]),
        .library(name: "JBWorld", targets: ["JBWorld"]),
        .library(name: "JBRules", targets: ["JBRules"]),
        .library(name: "JBSim", targets: ["JBSim"]),
        .library(name: "JBStory", targets: ["JBStory"]),
        .library(name: "JBSave", targets: ["JBSave"]),
    ],
    targets: [
        .target(name: "JBGeo", dependencies: []),
        .testTarget(name: "JBGeoTests", dependencies: ["JBGeo"]),
        .target(name: "JBWorld", dependencies: ["JBGeo"]),
        .testTarget(name: "JBWorldTests", dependencies: ["JBWorld", "JBGeo"]),
        .target(name: "JBRules", dependencies: ["JBWorld"]),
        .testTarget(name: "JBRulesTests", dependencies: ["JBRules", "JBWorld"]),
        .target(name: "JBSim", dependencies: ["JBRules"]),
        .testTarget(name: "JBSimTests", dependencies: ["JBSim", "JBRules"]),
        .target(name: "JBStory", dependencies: ["JBSim"]),
        .testTarget(name: "JBStoryTests", dependencies: ["JBStory", "JBSim"]),
        .target(name: "JBSave", dependencies: ["JBSim"]),
        .testTarget(name: "JBSaveTests", dependencies: ["JBSave", "JBSim"]),
        .testTarget(name: "JBCoreArchitectureTests"),
    ]
)
