//
//  EmbeddingFunction.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 11/7/24.
//

import Foundation
import MLX
import MLXLinalg


public enum EmbeddingFunction: String, Codable {
    case cosine
    case l2
    case innerProduct
    
    func distance(between firstVector: [Float], and secondVector: [Float]) -> Float? {
        switch self {
        case .cosine:
            return cosine(between: firstVector, and: secondVector)
        case .l2:
            return 0
        case .innerProduct:
            return 0
        }
    }
    
    func distances(between queryVector: MLXArray, and allEmbeddings: MLXArray) -> MLXArray {
        switch self {
        case .cosine:
            return cosineSimilarity(between: queryVector, and: allEmbeddings)
        case .l2:
            return squaredL2(between: queryVector, and: allEmbeddings)
        case .innerProduct:
            return MLXArray()
        }
    }
    
    // MLX Array
    
    private func squaredL2(between queryVector: MLXArray, and allEmbeddings: MLXArray) -> MLXArray {
        MLX.sum(MLX.square(allEmbeddings - queryVector), axis: 1)
    }
    
    private func cosineSimilarity(between queryVector: MLXArray, and allEmbeddings: MLXArray) -> MLXArray {
        1 - MLX.tensordot(allEmbeddings, queryVector) / (MLXLinalg.norm(allEmbeddings, axis: 1) * MLXLinalg.norm(queryVector))
    }
    
    private func innerProduct(between queryVector: MLXArray, and allEmbeddings: MLXArray) -> MLXArray {
        1 - MLX.tensordot(allEmbeddings, queryVector)
    }
    
    
    // Float Array
    
    private func cosine(between firstVector: [Float], and secondVector: [Float]) -> Float {
        let NORM_EPS = MLXArray(1e-30)
        let _firstVector = MLXArray(firstVector)
        let _secondVector = MLXArray(secondVector)
        
        let cosine = 1 - MLX.tensordot(_firstVector, _secondVector) / (
            ((MLXLinalg.norm(_firstVector) + NORM_EPS) * (MLXLinalg.norm(_secondVector)) + NORM_EPS)
        )
        
        return cosine.item(Float.self)
    }
    
    private func squaredl2(between firstVector: [Float], and secondVector: [Float]) -> Float {
        MLX.square(
            MLXLinalg.norm(
                MLXArray(firstVector) - MLXArray(secondVector)
            )
        ).item(Float.self)
    }
    
    private func innerProduct(between firstVector: [Float], and secondVector: [Float]) -> Float {
        1 - MLX.tensordot(
            MLXArray(firstVector),
            MLXArray(secondVector)
        ).item(Float.self)
    }
}
