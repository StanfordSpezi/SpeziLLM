//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import Foundation


extension UUID {
    // Hack to avoid changing the LLMContext's message's IDs from UUIDs to something else
    /// Generates a deterministic UUID from a string using SHA256
    static func deterministic(from string: String) -> UUID {
        // Hash the input string
        let hash = SHA256.hash(data: Data(string.utf8))
        
        // Take the first 16 bytes of the hash to form a UUID
        let uuidBytes = Array(hash.prefix(16))
        return UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        )).makeValidV4()
    }
    
    func makeValidV4() -> UUID {
        var uuid = self.uuid
        uuid.6 = (uuid.6 & 0b00001111) | 0b01000000
        uuid.8 = (uuid.8 & 0b00111111) | 0b10000000
        return UUID(uuid: uuid)
    }
}
