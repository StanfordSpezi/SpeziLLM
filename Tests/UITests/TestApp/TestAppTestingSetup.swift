//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Security
import SpeziSecureStorage
import SwiftUI


private struct TestAppTestingSetup: ViewModifier {
    @Environment(SecureStorage.self) var secureStorage
    
    func body(content: Content) -> some View {
        content
            .task {
                if FeatureFlags.resetKeychain {
                    do {
                        try secureStorage.deleteAllCredentials()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
    }
}


extension View {
    func testingSetup() -> some View {
        self.modifier(TestAppTestingSetup())
    }
}
