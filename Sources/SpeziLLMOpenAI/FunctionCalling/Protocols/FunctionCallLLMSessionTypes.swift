//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM


package enum FunctionCallLLMSessionTypes {
    /// The response returned after successfully executing a function call.
    package struct FunctionCallResponse {
        /// The unique identifier for the function call, as assigned by the LLM.
        let functionID: String
        /// The name of the function that was called.
        let functionName: String
        /// The raw arguments string provided in the function call request.
        let functionArgument: String
        /// The result of executing the function
        let response: String?
    }

    package enum FunctionCallFailureHandling {
        /// On function call error, simply throw the error to the caller.
        case throwError

        /// On function call error, throw the error and also stop the inference immediately.
        /// The provided `ContinuationObserver` is used to finish generation with an error.
        case throwAndStopInference(ContinuationObserver<String, any Error>)

        /// On function call error, throw the error and also append a message to the LLM context.
        /// This allows the LLM to "see" the error and adjust its reasoning or responses.
        case throwAndAppendToContext
    }
}
