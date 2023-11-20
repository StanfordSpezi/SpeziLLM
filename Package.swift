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
    name: "SpeziML",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "SpeziLLM", targets: ["SpeziLLM"]),
        .library(name: "SpeziLLMLocal", targets: ["SpeziLLMLocal"]),
        .library(name: "SpeziLLMLocalDownload", targets: ["SpeziLLMLocalDownload"]),
        .library(name: "SpeziLLMOpenAI", targets: ["SpeziLLMOpenAI"])
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI", .upToNextMinor(from: "0.2.4")),
        .package(url: "https://github.com/StanfordBDHG/llama.cpp", .upToNextMinor(from: "0.1.3")),
        //.package(url: "https://github.com/StanfordBDHG/llama.cpp", branch: "0.1.2"),
        //.package(path: "llama"),
        .package(url: "https://github.com/StanfordSpezi/Spezi", .upToNextMinor(from: "0.8.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziStorage", .upToNextMinor(from: "0.5.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziOnboarding", .upToNextMinor(from: "0.7.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziSpeech", branch: "feat/init-setup"),     // .upToNextMinor(from: "0.1.0")
        .package(url: "https://github.com/StanfordSpezi/SpeziChat", branch: "feat/init-setup")     // .upToNextMinor(from: "0.1.0")
    ],
    targets: [
        .target(
            name: "SpeziLLM",
            dependencies: [
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziChat", package: "SpeziChat")
            ]
        ),
        .target(
            name: "SpeziLLMLocal",
            dependencies: [
                .target(name: "SpeziLLM"),
                .target(name: "SpeziLLMLocalHelpers"),
                //.target(name: "llama"),
                .product(name: "llama", package: "llama.cpp"),
                //.product(name: "llama", package: "llama"),
                .product(name: "Spezi", package: "Spezi")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .target(
            name: "SpeziLLMLocalHelpers",
            dependencies: [
                //.target(name: "llama"),
                .product(name: "llama", package: "llama.cpp")
                //.product(name: "llama", package: "llama"),
            ],
            // TODO: Does this affect versioning?
            cxxSettings: [
                .unsafeFlags(["-std=c++11"])
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .target(
            name: "SpeziLLMLocalDownload",
            dependencies: [
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding")
            ]
        ),
        .target(
            name: "SpeziLLMOpenAI",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziChat", package: "SpeziChat"),
                .product(name: "SpeziLocalStorage", package: "SpeziStorage"),
                .product(name: "SpeziSecureStorage", package: "SpeziStorage"),
                .product(name: "SpeziSpeechRecognizer", package: "SpeziSpeech"),
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding")
            ]
        ),
        .testTarget(
            name: "SpeziLLMOpenAITests",
            dependencies: [
                .target(name: "SpeziLLMOpenAI")
            ]
        ),
        //.binaryTarget(name: "llama", path: "./llama/llama.xcframework")
    ]
)
