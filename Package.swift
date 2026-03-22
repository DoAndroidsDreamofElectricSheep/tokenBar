// swift-tools-version: 6.2
import CompilerPluginSupport
import Foundation
import PackageDescription

let sweetCookieKitPath = "../SweetCookieKit"
let useLocalSweetCookieKit =
    ProcessInfo.processInfo.environment["TOKENBAR_USE_LOCAL_SWEETCOOKIEKIT"] == "1"
let sweetCookieKitDependency: Package.Dependency =
    useLocalSweetCookieKit && FileManager.default.fileExists(atPath: sweetCookieKitPath)
    ? .package(path: sweetCookieKitPath)
    : .package(url: "https://github.com/steipete/SweetCookieKit", from: "0.4.0")

let package = Package(
    name: "TokenBar",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1"),
        .package(url: "https://github.com/apple/swift-log", from: "1.9.1"),
        .package(url: "https://github.com/apple/swift-syntax", from: "600.0.1"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.4.0"),
        sweetCookieKitDependency,
    ],
    targets: {
        var targets: [Target] = [
            .target(
                name: "TokenBarCore",
                dependencies: [
                    "TokenBarMacroSupport",
                    .product(name: "Logging", package: "swift-log"),
                    .product(name: "SweetCookieKit", package: "SweetCookieKit"),
                ],
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
            .macro(
                name: "TokenBarMacros",
                dependencies: [
                    .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                    .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                ]),
            .target(
                name: "TokenBarMacroSupport",
                dependencies: [
                    "TokenBarMacros",
                ]),
        ]

        #if os(macOS)
        targets.append(contentsOf: [
            .executableTarget(
                name: "TokenBar",
                dependencies: [
                    .product(name: "Sparkle", package: "Sparkle"),
                    .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                    "TokenBarMacroSupport",
                    "TokenBarCore",
                ],
                path: "Sources/TokenBar",
                resources: [
                    .process("Resources"),
                ],
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                    .define("ENABLE_SPARKLE"),
                ]),
        ])

        targets.append(.testTarget(
            name: "TokenBarTests",
            dependencies: ["TokenBar", "TokenBarCore"],
            path: "Tests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]))
        #endif

        return targets
    }())
