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
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "SpeziML", targets: ["SpeziML"])
    ],
    targets: [
        .target(
            name: "SpeziML"
        ),
        .testTarget(
            name: "SpeziMLTests",
            dependencies: [
                .target(name: "SpeziML")
            ]
        )
    ]
)
