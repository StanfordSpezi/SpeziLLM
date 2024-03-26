// swift-tools-version:5.9

//
// This source file is part of the Stanford Spezi open source project
// 
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "SpeziLLM",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .visionOS(.v1),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SpeziLLM", targets: ["SpeziLLM"]),
        .library(name: "SpeziLLMLocal", targets: ["SpeziLLMLocal"]),
        .library(name: "SpeziLLMLocalDownload", targets: ["SpeziLLMLocalDownload"]),
        .library(name: "SpeziLLMOpenAI", targets: ["SpeziLLMOpenAI"]),
        .library(name: "SpeziLLMFog", targets: ["SpeziLLMFog"])
    ],
    dependencies: [
        // .package(url: "https://github.com/MacPaw/OpenAI", .upToNextMinor(from: "0.2.6")),
        // .package(path: "../OpenAI"),
        .package(url: "https://github.com/StanfordBDHG/OpenAI", branch: "feat/fog-support"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.13.0"),
        .package(url: "https://github.com/StanfordBDHG/llama.cpp", .upToNextMinor(from: "0.2.1")),
        .package(url: "https://github.com/StanfordSpezi/Spezi", from: "1.2.1"),
        .package(url: "https://github.com/StanfordSpezi/SpeziAccount", from: "1.2.1"),
        .package(url: "https://github.com/StanfordSpezi/SpeziFirebase", from: "1.0.1"),
        .package(url: "https://github.com/StanfordSpezi/SpeziFoundation", from: "1.0.4"),
        .package(url: "https://github.com/StanfordSpezi/SpeziStorage", from: "1.0.2"),
        .package(url: "https://github.com/StanfordSpezi/SpeziOnboarding", from: "1.1.1"),
        // .package(url: "https://github.com/StanfordSpezi/SpeziChat", .upToNextMinor(from: "0.1.9")),
        // .package(path: "../SpeziChat"),
        .package(url: "https://github.com/StanfordSpezi/SpeziChat", branch: "feat/refactor-chat"),
        .package(url: "https://github.com/StanfordSpezi/SpeziViews", from: "1.3.1")
    ],
    targets: [
        .target(
            name: "SpeziLLM",
            dependencies: [
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziChat", package: "SpeziChat"),
                .product(name: "SpeziViews", package: "SpeziViews")
            ]
        ),
        .target(
            name: "SpeziLLMLocal",
            dependencies: [
                .target(name: "SpeziLLM"),
                .product(name: "llama", package: "llama.cpp"),
                .product(name: "SpeziFoundation", package: "SpeziFoundation"),
                .product(name: "Spezi", package: "Spezi")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .target(
            name: "SpeziLLMLocalDownload",
            dependencies: [
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding"),
                .product(name: "SpeziViews", package: "SpeziViews")
            ]
        ),
        .target(
            name: "SpeziLLMOpenAI",
            dependencies: [
                .target(name: "SpeziLLM"),
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "SpeziFoundation", package: "SpeziFoundation"),
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziChat", package: "SpeziChat"),
                .product(name: "SpeziSecureStorage", package: "SpeziStorage"),
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding")
            ]
        ),
        .target(
            name: "SpeziLLMFog",
            dependencies: [
                .target(name: "SpeziLLM"),
                .product(name: "Spezi", package: "Spezi"),
                // As SpeziAccount, SpeziFirebase and the firebase-ios-sdk currently don't support visionOS and macOS, perform fog node token authentication only on iOS
                .product(name: "SpeziAccount", package: "SpeziAccount", condition: .when(platforms: [.iOS])),
                .product(name: "SpeziFirebaseAccount", package: "SpeziFirebase", condition: .when(platforms: [.iOS])),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "OpenAI", package: "OpenAI")
            ]
        ),
        .testTarget(
            name: "SpeziLLMTests",
            dependencies: [
                .target(name: "SpeziLLMOpenAI")
            ]
        )
    ]
)
