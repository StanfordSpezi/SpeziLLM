//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import MLXNN


extension Module {
    /// Compute the number of parameters in a possibly quantized model
    public func numParameters() -> Int {
        leafModules()
            .flattenedValues()
            .map { mod -> Int in
                if let quantized = mod as? QuantizedLinear {
                    return quantized.scales.size * quantized.groupSize
                } else if let quantized = mod as? QuantizedEmbedding {
                    return quantized.scales.size * quantized.groupSize
                } else {
                    return mod.parameters()
                        .flattenedValues()
                        .reduce(0) { $0 + $1.size }
                }
            }
            .reduce(0, +)
    }
}
