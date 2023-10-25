//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


struct SpeziLLMTaskIdentifier: Hashable {
    let taskIdentifier: String
    
    
    init(fromModel model: any SpeziLLMModel) {
        self.taskIdentifier = String(describing: type(of: model))
    }
}
