//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import Foundation

protocol LLMFunction: Codable {
    typealias LLMFunctionParameterSchema = JSONSchema
    
    static var name: String { get }
    static var description: String { get }
    var schema: JSONSchema { get }
    
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



struct LLMTestFunction: LLMFunction {
    static let name: String = "test"
    static let description: String = "testDescription"
    var schema: LLMFunctionParameterSchema
    
    @Parameter var parameters: SomeType
    
    init(someRandomParam: String) {
        
    }
    
    func execute() async throws -> String {
        parameters.test1
    }
}

@propertyWrapper
class Parameter<T: Codable>: Codable {
    private var injectedValue: T? // swiftlint:disable:this discouraged_optional_collection
    
    public var wrappedValue: T {
        guard let value = injectedValue else {
            preconditionFailure("""
                                Tried to access @Collect for value [\(T.self)] which wasn't injected yet. \
                                Are you sure that you are only accessing @Collect within the `Module/configure` method?
                                """)
        }

        return value
    }
    
    public init() {}
}

extension Parameter: ParameterValueCollector {
    public func retrieve(from data: Data) {
        // TODO: Decoding needs to happen here from the JSON to the value
        // We know the type here (Value), so decoding should be possible
        //injectedValues = repository[CollectedModuleValue<Value>.self] ?? []
        injectedValue = try? JSONDecoder().decode(T.self, from: data)
    }
}


protocol ParameterValueCollector {
    /// This method is called to retrieve all the requested values from the given ``SpeziStorage`` repository.
    /// - Parameter repository: Provides access to the ``SpeziStorage`` repository for read access.
    func retrieve(from data: Data)
}


extension LLMFunction {
    var storageValueCollectors: [ParameterValueCollector] {
        retrieveProperties(ofType: ParameterValueCollector.self)
    }

    func injectModuleValues(from data: Data) {
        for collector in storageValueCollectors {
            collector.retrieve(from: data)
        }
    }
}


struct SomeType: Codable {
    let test1: String
    let test2: Int
}


//let functions: [any LLMFunction] = [
// LLMTestFunction(someRandomParam: "adf")
//]

let json = "{\"test1\": \"hello\", \"test2\": 123}"
let injectedFuc = LLMTestFunction(someRandomParam: "adf").injectModuleValues(from: json.data(using: .utf8) ?? Data())
print(injectedFuc)
