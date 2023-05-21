//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOpenAI
import SwiftUI
import XCTSpezi


struct ContentView: View {
    @EnvironmentObject var openAI: OpenAIComponent<TestAppStandard>
    
    
    var body: some View {
        Text("Your token is: \(openAI.apiToken ?? "")")
        Text("Your choice of model is: \(openAI.openAIModel)")
        Button("Test Token Change") {
            openAI.apiToken = "New Token"
        }
        Button("Test Model Change") {
            openAI.openAIModel = .gpt4
        }
    }
}
