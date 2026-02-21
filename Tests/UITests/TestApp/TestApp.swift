//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SwiftUI


@main
struct UITestsApp: App {
    @ApplicationDelegateAdaptor(TestAppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .navigationTitle("SPEZI_LLM_TEST_NAVIGATION_TITLE")
            }
            .testingSetup()
            .spezi(appDelegate)
        }
    }
}
