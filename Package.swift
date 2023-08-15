// swift-tools-version:5.7

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
        .iOS(.v16)
    ],
    products: [
        .library(name: "SpeziOpenAI", targets: ["SpeziOpenAI"])
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI", .upToNextMinor(from: "0.2.3")),
        .package(url: "https://github.com/StanfordSpezi/Spezi", .upToNextMinor(from: "0.7.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziStorage", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/StanfordSpezi/SpeziOnboarding", .upToNextMinor(from: "0.4.2"))
    ],
    targets: [
        .target(
            name: "SpeziOpenAI",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziLocalStorage", package: "SpeziStorage"),
                .product(name: "SpeziSecureStorage", package: "SpeziStorage"),
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
