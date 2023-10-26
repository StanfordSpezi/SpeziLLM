//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


@main
struct LocalLLMExecutionDemoApp: App {
    @UIApplicationDelegateAdaptor(LocalLLMAppDelegate.self) private var appDelegate
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .spezi(appDelegate) /// `.spezi(_)` modifier initializing the Spezi framework
        }
    }
}
