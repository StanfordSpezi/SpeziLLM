//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


@MainActor
class TestAppTestCase: XCTestCase, Sendable {
    let app = XCUIApplication()
    
    override nonisolated func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    
    func launch(
        enableMockMode: Bool,
        showOnboarding: Bool,
        clearAPIKeysFromKeychain: Bool
    ) {
        app.launchArguments = []
        if enableMockMode {
            app.launchArguments.append("--mockMode")
        }
        if showOnboarding {
            app.launchArguments.append("--showOnboarding")
        }
        if clearAPIKeysFromKeychain {
            app.launchArguments.append("--resetSecureStorage")
        }
        app.launch()
        XCTAssert(app.wait(for: .runningForeground, timeout: 5))
    }
}
