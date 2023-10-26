//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziLocalLLM


class LocalLLMAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            SpeziLLMRunner()
        }
    }
}
