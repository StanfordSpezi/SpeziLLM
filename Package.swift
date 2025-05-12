// swift-tools-version:6.0

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
        .package(url: "https://github.com/ml-explore/mlx-swift", .upToNextMinor(from: "0.21.2")),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", exact: "2.21.2"),  // Pin MLX Swift Examples as it doesn't follow semantic versioning
        .package(url: "https://github.com/huggingface/swift-transformers", .upToNextMinor(from: "0.1.14")),
        .package(url: "https://github.com/StanfordSpezi/Spezi", from: "1.8.0"),
        .package(url: "https://github.com/StanfordSpezi/SpeziFoundation", from: "2.1.0"),
        .package(url: "https://github.com/StanfordSpezi/SpeziStorage", from: "2.1.0"),
        .package(url: "https://github.com/StanfordSpezi/SpeziOnboarding", from: "1.2.2"),
        .package(url: "https://github.com/StanfordSpezi/SpeziChat", .upToNextMinor(from: "0.2.3")),
        .package(url: "https://github.com/StanfordSpezi/SpeziViews", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.7.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.2")
    ],
    targets: [
        .target(
            name: "SpeziLLM",
            dependencies: [
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziChat", package: "SpeziChat"),
                .product(name: "SpeziViews", package: "SpeziViews")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "SpeziLLMLocal",
            dependencies: [
                .target(name: "SpeziLLM"),
                .product(name: "SpeziFoundation", package: "SpeziFoundation"),
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "Transformers", package: "swift-transformers"),
                .product(name: "MLXLLM", package: "mlx-swift-examples")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "SpeziLLMLocalDownload",
            dependencies: [
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding"),
                .product(name: "SpeziViews", package: "SpeziViews"),
                .target(name: "SpeziLLMLocal"),
                .product(name: "MLXLLM", package: "mlx-swift-examples")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "SpeziLLMOpenAI",
            dependencies: [
                .target(name: "SpeziLLM"),
                .target(name: "GeneratedOpenAIClient"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "SpeziFoundation", package: "SpeziFoundation"),
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziChat", package: "SpeziChat"),
                .product(name: "SpeziKeychainStorage", package: "SpeziStorage"),
                .product(name: "SpeziOnboarding", package: "SpeziOnboarding")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "SpeziLLMFog",
            dependencies: [
                .target(name: "SpeziLLM"),
                .target(name: "GeneratedOpenAIClient"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "Spezi", package: "Spezi")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "GeneratedOpenAIClient",
            dependencies: [
                .product(name: "SpeziKeychainStorage", package: "SpeziStorage")
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .testTarget(
            name: "SpeziLLMTests",
            dependencies: [
                .target(name: "SpeziLLMOpenAI")
            ],
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        )
    ]
)
