//
//  FHIRFlattener.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 11/9/24.
//

import Foundation

public class FHIRFlattener {
    public init() {
        
    }
    
    public func splitCamel(_ text: String) -> String {
        var newText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        newText = newText.replacingOccurrences(
            of: #"([a-z])([A-Z])"#,
            with: "$1 $2",
            options: .regularExpression
        )
        
        newText = newText.replacingOccurrences(
            of: #"([A-Z]+)([A-Z][a-z])"#,
            with: "$1 $2",
            options: .regularExpression
        )
        
        return newText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func handleSpecialAttributes(attributeName: String, value: Any) -> Any {
        if attributeName.lowercased() == "resource type", let valueString = value as? String {
            return splitCamel(valueString)
        }
        return value
    }
    
    func flattenFHIR(nestedJson: [String: Any]) -> [String: Any] {
        var output: [String: Any] = [:]
        
        func flatten(jsonToFlatten: Any, name: String = "") {
            if let dictionary = jsonToFlatten as? [String: Any] {
                for (key, value) in dictionary {
                    flatten(jsonToFlatten: value, name: name + splitCamel(key) + " ")
                }
            } else if let array = jsonToFlatten as? [Any] {
                for (index, element) in array.enumerated() {
                    flatten(jsonToFlatten: element, name: name + "\(index) ")
                }
            } else {
                let attributeName = String(name.dropLast())
                output[attributeName] = handleSpecialAttributes(attributeName: attributeName, value: jsonToFlatten)
            }
        }
        
        flatten(jsonToFlatten: nestedJson)
        return output
    }
    
    func filterForPatient(entry: [String: Any]) -> Bool {
        guard let entry = entry as? [String: [String: Any]] else { return false }
        return entry["resource"]?["resourceType"] as? String == "Patient"
    }
    
    func flatToString(flatEntry: [String: String]) -> String {
        var output = ""
        
        for (attribute, value) in flatEntry {
            output += "\(attribute) is \(value)\n"
        }
        
        return output
    }
    
}
