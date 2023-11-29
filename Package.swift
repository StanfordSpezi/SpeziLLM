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
        .package(url: "https://github.com/StanfordBDHG/llama.cpp", .upToNextMinor(from: "0.1.5")),
        .package(url: "https://github.com/StanfordSpezi/Spezi", .upToNextMinor(from: "0.8.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziStorage", .upToNextMinor(from: "0.5.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziOnboarding", .upToNextMinor(from: "0.7.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziSpeech", .upToNextMinor(from: "0.1.1")),
        .package(url: "https://github.com/StanfordSpezi/SpeziChat", .upToNextMinor(from: "0.1.1")),
        .package(url: "https://github.com/StanfordSpezi/SpeziViews", .upToNextMinor(from: "0.6.3"))
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
                .target(name: "SpeziLLMLocalHelpers"),
                .product(name: "llama", package: "llama.cpp"),
                .product(name: "Spezi", package: "Spezi")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .target(
            name: "SpeziLLMLocalHelpers",
            dependencies: [
                .product(name: "llama", package: "llama.cpp")
            ],
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
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding"),
                .product(name: "SpeziViews", package: "SpeziViews")
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
            name: "SpeziLLMTests",
            dependencies: [
                .target(name: "SpeziLLMOpenAI")
            ]
        )
    ]
)
