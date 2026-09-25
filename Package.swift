// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SamFlow",
    platforms: [.macOS(.v15)],
    targets: [
        // Domain + persistence. No SwiftUI, no AppKit — runs in tests without a UI.
        .target(name: "SamFlowKit"),

        // The macOS app shell. UI only; all rules live in SamFlowKit.
        .executableTarget(name: "SamFlow", dependencies: ["SamFlowKit"]),

        .testTarget(name: "SamFlowKitTests", dependencies: ["SamFlowKit"]),
    ]
)
