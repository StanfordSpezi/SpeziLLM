//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import os
import Foundation


protocol LLMFunction {
    typealias LLMFunctionParameterSchema = JSONSchema
    
    
    static var name: String { get }
    static var description: String { get }
    static var schema: JSONSchema { get }
    
    
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

@propertyWrapper
class Parameter<T: Decodable> {
    private var injectedValue: T? // swiftlint:disable:this discouraged_optional_collection
    
    public var wrappedValue: T {
        guard let value = injectedValue else {
            preconditionFailure("""
                                Tried to access @Parameter for value [\(T.self)] which wasn't injected yet. \
                                Are you sure that you declared the function call within the respective SpeziLLM functions and only access the @Parameter within the `LLMFunction/execute()` method?
                                """)
        }

        return value
    }
    
    public init() {}
}

extension Parameter: ParameterValueCollector {
    public func retrieve(from data: Data) throws {
        // TODO: Decoding needs to happen here from the JSON to the value
        // We know the type here (Value), so decoding should be possible
        //injectedValues = repository[CollectedModuleValue<Value>.self] ?? []
        injectedValue = try JSONDecoder().decode(T.self, from: data)
    }
}


protocol ParameterValueCollector {
    /// This method is called to retrieve all the requested values from the given ``SpeziStorage`` repository.
    /// - Parameter repository: Provides access to the ``SpeziStorage`` repository for read access.
    func retrieve(from data: Data) throws
}


extension LLMFunction {
    var storageValueCollectors: [ParameterValueCollector] {
        retrieveProperties(ofType: ParameterValueCollector.self)
    }

    func injectParameterValues(from data: Data) {
        // No injection of data
        guard storageValueCollectors.count != 0 && Self.schema.type != .null else {
            return
        }
        
        // Ensure only one parameter property exists
        guard storageValueCollectors.count == 1,
              let collector = storageValueCollectors.first else {
            preconditionFailure("""
                                Multiple @Parameter values have been specified within the LLMFunction.
                                Ensure that only one @Parameter value is defined that contains all relevant
                                function calling parameters, reflected in the LLMFunctionParameterSchema.
                                """)
        }
        
        collector.retrieve(from: data)
        
        /*
        for collector in storageValueCollectors {
            collector.retrieve(from: data)
        }
         */
    }
}


struct SomeType: Decodable {
    let test1: String
    let test2: Int
}

struct LLMTestFunction: LLMFunction {
    static let name: String = "test"
    static let description: String = "testDescription"
    static var schema: LLMFunctionParameterSchema = .init(
        type: .object,
        properties: [
            "test1": .init(
                type: .string,
                description: "this parameter does this and that"
            ),
            "test2": .init(
                type: .integer,
                description: "this parameter does this and that"
            )
        ]
    )
    
    static var schema2: LLMFunctionParameterSchema = .init(type: .null)
    
    @Parameter var parameter: SomeType
    
    init(someRandomParam: String) {
        
    }
    
    func execute() async throws -> String {
        parameter.test1
    }
}

//let functions: [any LLMFunction] = [
// LLMTestFunction(someRandomParam: "adf")
//]

let json = "{\"test1\": \"hello\", \"test2\": 123}"
let injectedFuc = LLMTestFunction(someRandomParam: "adf").injectParameterValues(from: json.data(using: .utf8) ?? Data())
print(injectedFuc)
