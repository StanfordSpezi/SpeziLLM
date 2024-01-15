//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation

/*
public protocol LLMFunction {
    static var name: String { get }
    static var description: String { get }
    
    
    func execute() async throws -> String
}

extension LLMFunction {
    func retrieveProperties<Value>(ofType type: Value.Type) -> [Value] {
        let mirror = Mirror(reflecting: self)

        return mirror.children.compactMap { _, value in
            value as? Value
        }
    }
}

extension LLMFunction {
    public typealias Parameter<Value> = _ParameterPropertyWrapper<Value> where Value: LLMFunctionParameter
}

@propertyWrapper
public class _ParameterPropertyWrapper<T: LLMFunctionParameter> {   // swiftlint:disable:this type_name
    fileprivate let jsonDecoder = JSONDecoder()
    
    private var injectedValue: T? // swiftlint:disable:this discouraged_optional_collection
    
    public var wrappedValue: T {
        guard let value = injectedValue else {
            preconditionFailure("""
                                Tried to access @Parameter for value [\(T.self)] which wasn't injected yet. \
                                Are you sure that you declared the function call within the respective SpeziLLM functions and 
                                only access the @Parameter within the `LLMFunction/execute()` method?
                                """)
        }

        return value
    }
    
    public init() {}
}

extension _ParameterPropertyWrapper: ParameterValueCollector {
    func retrieve(from data: Data) throws {
        injectedValue = try jsonDecoder.decode(T.self, from: data)
    }
}

extension _ParameterPropertyWrapper: ParameterSchemaCollector {
    func schema() -> LLMFunctionParameter.LLMFunctionParameterSchema {
        T.schema
    }
}


protocol ParameterValueCollector {
    /// This method is called to retrieve all the requested values from the given ``SpeziStorage`` repository.
    /// - Parameter repository: Provides access to the ``SpeziStorage`` repository for read access.
    func retrieve(from data: Data) throws
}

protocol ParameterSchemaCollector {
    func schema() -> LLMFunctionParameter.LLMFunctionParameterSchema
}

extension LLMFunction {
    var storageValueCollectors: [ParameterValueCollector] {
        retrieveProperties(ofType: ParameterValueCollector.self)
    }

    var schema: LLMFunctionParameter.LLMFunctionParameterSchema? {
        retrieveProperties(ofType: ParameterSchemaCollector.self).first?.schema()
    }
    
    func injectParameterValues(from data: Data) throws {
        // No injection of data if no `@Parameter` declared
        guard !storageValueCollectors.isEmpty else {
            return
        }
        
        // Ensure only one parameter property exists
        guard storageValueCollectors.count == 1,
              let collector = storageValueCollectors.first else {
            throw LLMOpenAIError.illegalFunctionCallParameterCount
        }
        
        do {
            try collector.retrieve(from: data)
        } catch {
            throw LLMOpenAIError.invalidFunctionCallArguments(error)
        }
    }
}*/
