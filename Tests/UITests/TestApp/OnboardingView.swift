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


struct OnboardingView: View {
    enum Step: String, Codable {
        case modelSelection
    }

    
    @State private var steps: [Step] = []

    
    var body: some View {
        NavigationStack(path: $steps) {
            OpenAIAPIKeyOnboardingStep {
                steps.append(.modelSelection)
            }
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .modelSelection:
                        OpenAIModelSelectionOnboardingStep {
                            steps.removeLast()
                        }
                    }
                }
        }
    }
}
