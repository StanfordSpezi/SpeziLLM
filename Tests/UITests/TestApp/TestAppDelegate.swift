//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
#if os(iOS)
import SpeziAccount
import SpeziFirebaseAccount
#endif
import SpeziLLM
import SpeziLLMFog
import SpeziLLMLocal
import SpeziLLMOpenAI
import SpeziSecureStorage


class TestAppDelegate: SpeziAppDelegate {
    private nonisolated static var caCertificateUrl: URL? {
        guard let url = Bundle.main.url(forResource: "ca", withExtension: "crt") else {
            preconditionFailure("CA Certificate not found!")
        }
        
        return url
    }
    
    override var configuration: Configuration {
        Configuration {
            #if os(iOS)
            AccountConfiguration(configuration: [
                .requires(\.userId),
                .requires(\.password)
            ])
            
            FirebaseAccountConfiguration(
                authenticationMethods: .emailAndPassword,
                emulatorSettings: (host: "localhost", port: 9099)
            )
            #endif
            
            LLMRunner {
                LLMMockPlatform()
                LLMLocalPlatform()
                LLMFogPlatform(configuration: .init(host: "spezillmfog.local", caCertificate: nil))
                LLMOpenAIPlatform()
            }
            SecureStorage()
        }
    }
}
