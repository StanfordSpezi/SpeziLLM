//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Security
import SwiftUI


private struct HealthGPTAppTestingSetup: ViewModifier {
    func resetKeychain() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]

        for itemClass in secItemClasses {
            let spec: [String: Any] = [kSecClass as String: itemClass]
            SecItemDelete(spec as CFDictionary)
        }
    }


    func body(content: Content) -> some View {
        content
            .task {
                if FeatureFlags.resetKeychain {
                    resetKeychain()
                }
            }
    }
}


extension View {
    func testingSetup() -> some View {
        self.modifier(HealthGPTAppTestingSetup())
    }
}
