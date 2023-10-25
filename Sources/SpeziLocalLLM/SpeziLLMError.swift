//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


public enum SpeziLLMError: Error {
    case modelNotFound
    case inputTooLong
    case failedToEval
    case contextLimit
    case modelNotReadyYet
    case generationError
}
