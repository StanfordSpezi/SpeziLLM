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
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.18.1"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", from: "1.16.0"),
        .package(url: "https://github.com/huggingface/swift-transformers", .upToNextMinor(from: "0.1.12")),
        .package(url: "https://github.com/StanfordBDHG/OpenAI", .upToNextMinor(from: "0.2.9")),
        .package(url: "https://github.com/StanfordSpezi/Spezi", from: "1.2.1"),
        .package(url: "https://github.com/StanfordSpezi/SpeziFoundation", from: "2.0.0-beta.3"),
        .package(url: "https://github.com/StanfordSpezi/SpeziStorage", from: "1.0.2"),
        .package(url: "https://github.com/StanfordSpezi/SpeziOnboarding", from: "1.1.1"),
        .package(url: "https://github.com/StanfordSpezi/SpeziChat", .upToNextMinor(from: "0.2.1")),
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
                .product(name: "SpeziFoundation", package: "SpeziFoundation"),
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXFast", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "Transformers", package: "swift-transformers"),
                .product(name: "LLM", package: "mlx-swift-examples")
            ]
        ),
        .target(
            name: "SpeziLLMLocalDownload",
            dependencies: [
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding"),
                .product(name: "SpeziViews", package: "SpeziViews"),
                .target(name: "SpeziLLMLocal"),
                .product(name: "LLM", package: "mlx-swift-examples")
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
