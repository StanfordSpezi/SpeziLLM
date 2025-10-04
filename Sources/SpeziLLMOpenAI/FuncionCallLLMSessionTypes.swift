//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM


package enum FunctionCallLLMSessionTypes {
    package struct FunctionCallResponse {
        let functionID: String
        let functionName: String
        let functionArgument: String
        let response: String?
    }

    package enum FunctionCallFailureHandling {
        /// On function call error, simply throw the error to the caller.
        case throwError

        /// On function call error, throw the error and also stop the inference immediately.
        /// The provided `ContinuationObserver` is used to finish generation with an error.
        case stopInference(ContinuationObserver<String, any Error>)

        /// On function call error, throw the error and also append a message to the LLM context.
        /// This allows the LLM to "see" the error and adjust its reasoning or responses.
        case appendToContext
    }
}
