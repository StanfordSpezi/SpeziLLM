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
        .library(name: "SpeziOpenAI", targets: ["SpeziOpenAI"]),
        .library(name: "SpeziSpeechRecognizer", targets: ["SpeziSpeechRecognizer"]),
        .library(name: "SpeziSpeechSynthesizer", targets: ["SpeziSpeechSynthesizer"]),
        .library(name: "SpeziLLM", targets: ["SpeziLLM"]),
        .library(name: "SpeziLLMLocal", targets: ["SpeziLLMLocal"]),
        .library(name: "SpeziLLMLocalDownload", targets: ["SpeziLLMLocalDownload"])
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI", .upToNextMinor(from: "0.2.4")),
        // .package(url: "https://github.com/StanfordBDHG/llama.cpp", .upToNextMinor(from: "0.1470.0")),
        .package(url: "https://github.com/ggerganov/llama.cpp", branch: "b1470"),
        .package(url: "https://github.com/StanfordSpezi/Spezi", .upToNextMinor(from: "0.7.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziStorage", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziOnboarding", .upToNextMinor(from: "0.6.0"))
    ],
    targets: [
        .target(
            name: "SpeziOpenAI",
            dependencies: [
                .target(name: "SpeziSpeechRecognizer"),
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziLocalStorage", package: "SpeziStorage"),
                .product(name: "SpeziSecureStorage", package: "SpeziStorage"),
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding")
            ]
        ),
        .target(
            name: "SpeziSpeechRecognizer"
        ),
        .target(
            name: "SpeziSpeechSynthesizer"
        ),
        .target(
            name: "SpeziLLM",
            dependencies: [
                .target(name: "SpeziOpenAI"),
                .product(name: "Spezi", package: "Spezi")
            ]
        ),
        .target(
            name: "SpeziLLMLocal",
            dependencies: [
                .target(name: "SpeziLLM"),
                .product(name: "llama", package: "llama.cpp"),
                .product(name: "Spezi", package: "Spezi")
            ]
        ),
        .target(
            name: "SpeziLLMLocalDownload",
            dependencies: [
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding")
            ]
        ),
        .testTarget(
            name: "SpeziOpenAITests",
            dependencies: [
                .target(name: "SpeziOpenAI")
            ]
        )
    ]
)
