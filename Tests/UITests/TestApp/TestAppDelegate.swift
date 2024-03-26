//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SpeziLLM
import SpeziLLMFog
import SpeziLLMLocal
import SpeziLLMOpenAI


class TestAppDelegate: SpeziAppDelegate {
    private nonisolated static var caCertificateUrl: URL {
        guard let url = Bundle.main.url(forResource: "ca", withExtension: "crt") else {
            preconditionFailure("CA Certificate path not properly formed!")
        }
        
        return url
    }
    
    override var configuration: Configuration {
        Configuration {
            AccountConfiguration(configuration: [
                .requires(\.userId),
                .requires(\.password)
            ])
            
            FirebaseAccountConfiguration(authenticationMethods: .emailAndPassword)
            
            LLMRunner {
                LLMMockPlatform()
                LLMLocalPlatform()
                LLMFogPlatform(configuration: .init(caCertificate: Self.caCertificateUrl, host: "spezillmfog.local"))
                LLMOpenAIPlatform()
            }
        }
    }
}
