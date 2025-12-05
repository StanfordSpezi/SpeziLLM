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
        package let functionID: String
        /// The name of the function that was called.
        package let functionName: String
        /// The raw arguments string provided in the function call request.
        package let functionArgument: String
        /// The result of executing the function
        package let response: String
    }

    package enum FunctionCallFailureHandling {
        /// On function call error, simply throw the error to the caller.
        case throwError

        /// On function call error, throw the error and also stop the inference immediately.
        /// The provided `ContinuationObserver` is used to finish generation with an error.
        case throwAndStopInference(ContinuationObserver<String, any Error>)

        /// On function call error, do not throw. Instead, the error is included in the returned
        /// `FunctionCallResponse`, so the LLM can "see" the error and adjust its reasoning or responses.
        case returnErrorInResponse
    }
}
