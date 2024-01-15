//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI


extension Int: LLMFunctionParameter {
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .integer
        )
    }
}

extension Float: LLMFunctionParameter {
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .number
        )
    }
}

extension Double: LLMFunctionParameter {
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .number
        )
    }
}

extension String: LLMFunctionParameter {
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .string
        )
    }
}

extension Bool: LLMFunctionParameter {
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .boolean
        )
    }
}

extension Array: LLMFunctionParameter where Element: Decodable {
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .array
        )
    }
}


public protocol LLMFunctionParameterWrappedCompatible: Decodable {}

extension Int: LLMFunctionParameterWrappedCompatible {}
extension Float: LLMFunctionParameterWrappedCompatible {}
extension Double: LLMFunctionParameterWrappedCompatible {}
extension String: LLMFunctionParameterWrappedCompatible {}
extension Bool: LLMFunctionParameterWrappedCompatible {}
extension Array: LLMFunctionParameterWrappedCompatible where Element: LLMFunctionParameterWrappedCompatible {}
extension Optional: LLMFunctionParameter where Wrapped: LLMFunctionParameterWrappedCompatible {
    public static var schema: LLMFunctionParameterPropertySchema {
        .init(
            type: .null     // Dummy value for optional parameters
        )
    }
}
