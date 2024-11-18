//
//  VectorDatabase+Tokenizer.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 11/7/24.
//

import Foundation
import NaturalLanguage

public class TextSplitter {
    private let chunkSize: Int
    private let chunkOverlap: Int
    private let keepSeparator: Bool
    private let stripWhitespace: Bool
    
    public init(
        chunkSize: Int = 400,
        chunkOverlap: Int = 20,
        keepSeparator: Bool = false,
        stripWhitespace: Bool = true
    ) {
        self.chunkSize = chunkSize
        self.chunkOverlap = chunkOverlap
        self.keepSeparator = keepSeparator
        self.stripWhitespace = stripWhitespace
    }
    
    public func tokenize(_ input: String, by unit: NLTokenUnit) -> [String] {
        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.string = input
        
        var resultSet: [String] = []
        
        tokenizer.enumerateTokens(in: input.startIndex ..< input.endIndex) { tokenRange, attributes in
            resultSet.append(String(input[tokenRange]))
            return true
        }
        return resultSet
    }
    
    
    public func tokenize(_ text: String, chunkSize: Int, overlap: Int) throws -> [String] {
        guard chunkSize > 0, overlap >= 0, overlap < chunkSize else {
            throw VectorDatabaseError.invalidArgument
        }
        
        var chunks: [String] = []
        var start = text.startIndex
        
        while start < text.endIndex {
            let end = text.index(start, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            let chunk = String(text[start..<end])
            chunks.append(chunk)
            
            let overlapOffset = max(0, chunkSize - overlap)
            start = text.index(start, offsetBy: overlapOffset, limitedBy: text.endIndex) ?? text.endIndex
        }
        
        return chunks
    }
    
    public func splitText(
        _ text: String,
        separators: [String] = ["\n\n", "\n", " ", ""],
        isSeparatorRegex: Bool = false
    ) -> [String] {
        var finalChunks: [String] = []
        var separator = separators.last ?? ""
        var newSeparators: [String] = []
        
        // Determine which separator to use
        for (i, sep) in separators.enumerated() {
            let currentSeparator = isSeparatorRegex ? sep : NSRegularExpression.escapedPattern(for: sep)
            if sep.isEmpty {
                separator = sep
                break
            }
            if let _ = text.range(of: currentSeparator, options: .regularExpression) {
                separator = sep
                newSeparators = Array(separators[(i + 1)...])
                break
            }
        }
        
        let splits = splitTextWithRegex(
            text,
            separator: isSeparatorRegex ? separator : NSRegularExpression.escapedPattern(for: separator)
        )
        
        var goodSplits: [String] = []
        let mergeSeparator = keepSeparator ? "" : separator
        
        for split in splits {
            if split.count < chunkSize {
                goodSplits.append(split)
            } else {
                if !goodSplits.isEmpty {
                    let merged = mergeSplits(goodSplits, separator: mergeSeparator)
                    finalChunks.append(contentsOf: merged)
                    goodSplits.removeAll()
                }
                if newSeparators.isEmpty {
                    finalChunks.append(split)
                } else {
                    let otherChunks = splitText(split, separators: newSeparators)
                    finalChunks.append(contentsOf: otherChunks)
                }
            }
        }
        
        if !goodSplits.isEmpty {
            let merged = mergeSplits(goodSplits, separator: mergeSeparator)
            finalChunks.append(contentsOf: merged)
        }
        
        return finalChunks
    }
    
    // Private Functions
    
    private func joinDocs(_ currentDoc: [String], separator: String) -> String? {
        var text = currentDoc.joined(separator: separator)
        
        if stripWhitespace {
            text = text.trimmingCharacters(in: .whitespaces)
        }
        if text.isEmpty {
            return nil
        } else {
            return text
        }
    }
    
    private func splitTextWithRegex(_ text: String, separator: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: separator, options: [])
        let results = regex?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        var splits: [String] = []
        var lastIndex = text.startIndex
        
        results?.forEach { match in
            let range = Range(match.range, in: text)!
            let chunk = String(text[lastIndex..<range.lowerBound]).replacingOccurrences(of: separator, with: "")
            splits.append(chunk)
            lastIndex = range.lowerBound
        }
        if lastIndex < text.endIndex {
            splits.append(String(text[lastIndex...]))
        }
        return splits
    }
    
    private func mergeSplits(_ splits: [String], separator: String) -> [String] {
        let separatorLength = separator.count
        var docs: [String] = []
        var currentDoc: [String] = []
        var totalLength = 0
        
        for split in splits {
            let splitLength = split.count
            
            // Check if adding this split exceeds the chunk size
            if totalLength + splitLength + (currentDoc.isEmpty ? 0 : separatorLength) > chunkSize {
                
                // Log a warning if the current chunk exceeds the chunk size
                if totalLength > chunkSize {
                    print("Warning: Created a chunk of size \(totalLength), which is longer than the specified \(chunkSize)")
                }
                
                if !currentDoc.isEmpty {
                    // Merge the current document and add to the final list
                    if let doc = joinDocs(currentDoc, separator: separator) {
                        docs.append(doc)
                    }
                    
                    // Remove elements from the front if the current document is too long
                    while totalLength > chunkOverlap || (totalLength + splitLength + (currentDoc.isEmpty ? 0 : separatorLength) > chunkSize && totalLength > 0) {
                        if currentDoc.isEmpty {
                            break
                        }
                        
                        totalLength -= currentDoc.first?.count ?? 0 + (currentDoc.count > 1 ? separatorLength : 0)
                        currentDoc.removeFirst()
                    }
                }
            }
            
            // Add the current split to the document and update the total length
            currentDoc.append(split)
            totalLength += splitLength + (currentDoc.count > 1 ? separatorLength : 0)
        }
        
        // Add the last remaining document
        if let doc = joinDocs(currentDoc, separator: separator) {
            docs.append(doc)
        }
        
        return docs
    }
}
