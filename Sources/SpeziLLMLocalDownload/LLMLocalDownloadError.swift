//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// The ``LLMLocalDownloadError`` describes possible errors that occur during downloading models via the ``LLMLocalDownloadManager``.
public enum LLMLocalDownloadError: LocalizedError {
    /// Indicates an unknown error during downloading the model
    case unknownError
    
    
    public var errorDescription: String? {
        String(localized: LocalizedStringResource("LLM_DOWNLOAD_ERROR_DESCRIPTION", bundle: .atURL(from: .module)))
    }
    
    public var recoverySuggestion: String? {
        String(localized: LocalizedStringResource("LLM_DOWNLOAD_ERROR_RECOVERY_SUGGESTION", bundle: .atURL(from: .module)))
    }

    public var failureReason: String? {
        String(localized: LocalizedStringResource("LLM_DOWNLOAD_ERROR_FAILURE_REASON", bundle: .atURL(from: .module)))
    }
}
