//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


/// The ``LLMSamplingParameters`` represents the sampling parameters of the LLM.
/// Internally, these data points are passed as a llama.cpp `llama_sampling_params` C struct to the LLM.
public struct LLMSamplingParameters: Sendable {
    /// Helper enum for the Mirostat sampling method
    public enum Mirostat {
        init(rawValue: Int, targetEntropy: Float = 5.0, learningRate: Float = 0.1) {
            switch rawValue {
            case 0:
                self = .disabled
            case 1:
                self = .v1(targetEntropy: targetEntropy, learningRate: learningRate)
            case 2:
                self = .v2(targetEntropy: targetEntropy, learningRate: learningRate)
            default:
                self = .disabled
            }
        }
        
        
        case disabled
        case v1(targetEntropy: Float, learningRate: Float)  // swiftlint:disable:this identifier_name
        case v2(targetEntropy: Float, learningRate: Float)  // swiftlint:disable:this identifier_name
        
        
        var rawValue: Int {
            switch self {
            case .disabled:
                return 0
            case .v1:
                return 1
            case .v2:
                return 2
            }
        }
    }
    
    public struct ClassifierFreeGuidance {
        let negativePrompt: String?
        let scale: Float
        
        
        public init(negativePrompt: String? = nil, scale: Float = 1.0) {
            self.negativePrompt = negativePrompt
            self.scale = scale
        }
    }
    
    
    /// Wrapped C struct from the llama.cpp library, later-on passed to the LLM.
    private var wrapped: llama_sampling_params
    
    
    /// Sampling parameters in llama.cpp's low-level C representation.
    var llamaCppRepresentation: llama_sampling_params {
        wrapped
    }
    
    var llamaCppSamplingContext: UnsafeMutablePointer<llama_sampling_context>? {
        llama_sampling_init(wrapped)
    }
    
    /// Number of previous tokens to remember.
    var rememberTokens: Int32 {
        get {
            wrapped.n_prev
        }
        set {
            wrapped.n_prev = newValue
        }
    }
    
    /// If greater than 0, output the probabilities of top n\_probs tokens.
    var outputProbabilities: Int32 {
        get {
            wrapped.n_probs
        }
        set {
            wrapped.n_probs = newValue
        }
    }
    
    /// Top-K Sampling: K most likely next words (<= 0 to use vocab size).
    var topK: Int32 {
        get {
            wrapped.top_k
        }
        set {
            wrapped.top_k = newValue
        }
    }
    
    /// Top-p Sampling: Smallest possible set of words whose cumulative probability exceeds the probability p (1.0 = disabled).
    var topP: Float {
        get {
            wrapped.top_p
        }
        set {
            wrapped.top_p = newValue
        }
    }
    
    /// Min-p Sampling (0.0 = disabled).
    var minP: Float {
        get {
            wrapped.min_p
        }
        set {
            wrapped.min_p = newValue
        }
    }
    
    /// Tail Free Sampling (1.0 = disabled).
    var tfs: Float {
        get {
            wrapped.tfs_z
        }
        set {
            wrapped.tfs_z = newValue
        }
    }
    
    /// Locally Typical Sampling.
    var typicalP: Float {
        get {
            wrapped.typical_p
        }
        set {
            wrapped.typical_p = newValue
        }
    }
    
    /// Temperature Sampling: A higher value indicates more creativity of the model but also more hallucinations.
    var temperature: Float {
        get {
            wrapped.temp
        }
        set {
            wrapped.temp = newValue
        }
    }
    
    /// Last n tokens to penalize (0 = disable penalty, -1 = context size).
    var penaltyLastTokens: Int32 {
        get {
            wrapped.penalty_last_n
        }
        set {
            wrapped.penalty_last_n = newValue
        }
    }
    
    /// Penalize repeated tokens (1.0 = disabled).
    var penaltyRepeat: Float {
        get {
            wrapped.penalty_repeat
        }
        set {
            wrapped.penalty_repeat = newValue
        }
    }
    
    /// Penalize frequency (0.0 = disabled).
    var penaltyFrequency: Float {
        get {
            wrapped.penalty_repeat
        }
        set {
            wrapped.penalty_repeat = newValue
        }
    }
    
    /// Presence penalty (0.0 = disabled).
    var penaltyPresence: Float {
        get {
            wrapped.penalty_present
        }
        set {
            wrapped.penalty_present = newValue
        }
    }
    
    /// Penalize new lines.
    var penalizeNewLines: Bool {
        get {
            wrapped.penalize_nl
        }
        set {
            wrapped.penalize_nl = newValue
        }
    }
    
    /// Mirostat sampling.
    var mirostat: Mirostat {
        get {
            .init(
                rawValue: Int(wrapped.mirostat),
                targetEntropy: wrapped.mirostat_tau,
                learningRate: wrapped.mirostat_eta
            )
        }
        set {
            wrapped.mirostat = Int32(newValue.rawValue)
            
            if case .v1(let targetEntropy, let learningRate) = mirostat {
                wrapped.mirostat_tau = targetEntropy
                wrapped.mirostat_eta = learningRate
            } else if case .v2(let targetEntropy, let learningRate) = mirostat {
                wrapped.mirostat_tau = targetEntropy
                wrapped.mirostat_eta = learningRate
            } else {
                wrapped.mirostat_tau = 5.0
                wrapped.mirostat_eta = 0.1
            }
        }
    }
    
    /// Classifier-Free Guidance.
    var cfg: ClassifierFreeGuidance {
        get {
            .init(
                negativePrompt: String(wrapped.cfg_negative_prompt),
                scale: wrapped.cfg_scale
            )
        }
        set {
            wrapped.cfg_negative_prompt = std.string(newValue.negativePrompt)
            wrapped.cfg_scale = newValue.scale
        }
    }
    
    
    /// Creates the ``LLMContextParameters`` which wrap the underlying llama.cpp `llama_context_params` C struct.
    /// Is passed to the underlying llama.cpp model in order to configure the context of the LLM.
    ///
    /// - Parameters:
    ///   - rememberTokens: Number of previous tokens to remember.
    ///   - outputProbabilities: If greater than 0, output the probabilities of top n\_probs tokens.
    ///   - topK: Top-K Sampling: K most likely next words (<= 0 to use vocab size).
    ///   - topP: Top-p Sampling: Smallest possible set of words whose cumulative probability exceeds the probability p (1.0 = disabled).
    ///   - minP: Min-p Sampling (0.0 = disabled).
    ///   - tfs: Tail Free Sampling (1.0 = disabled).
    ///   - typicalP: Locally Typical Sampling.
    ///   - temperature: Temperature Sampling: A higher value indicates more creativity of the model but also more hallucinations.
    ///   - penaltyLastTokens: Last n tokens to penalize (0 = disable penalty, -1 = context size).
    ///   - penaltyRepeat: Penalize repeated tokens (1.0 = disabled).
    ///   - penaltyFrequency: Penalize frequency (0.0 = disabled).
    ///   - penaltyPresence: Presence penalty (0.0 = disabled).
    ///   - penalizeNewLines: Penalize new lines.
    ///   - mirostat: Mirostat sampling.
    ///   - cfg: Classifier-Free Guidance.
    public init(
        rememberTokens: Int32 = 256,
        outputProbabilities: Int32 = 0,
        topK: Int32 = 40,
        topP: Float = 0.95,
        minP: Float = 0.05,
        tfs: Float = 1.0,
        typicalP: Float = 1.0,
        temperature: Float = 0.8,
        penaltyLastTokens: Int32 = 64,
        penaltyRepeat: Float = 1.1,
        penaltyFrequency: Float = 0.0,
        penaltyPresence: Float = 0.0,
        penalizeNewLines: Bool = true,
        mirostat: Mirostat = .disabled,
        cfg: ClassifierFreeGuidance = .init()
    ) {
        self.wrapped = llama_sampling_params()
        
        self.rememberTokens = rememberTokens
        self.outputProbabilities = outputProbabilities
        self.topK = topK
        self.topP = topP
        self.minP = minP
        self.tfs = tfs
        self.typicalP = typicalP
        self.temperature = temperature
        self.penaltyLastTokens = penaltyLastTokens
        self.penaltyRepeat = penaltyRepeat
        self.penaltyFrequency = penaltyFrequency
        self.penaltyPresence = penaltyPresence
        self.penalizeNewLines = penalizeNewLines
        self.mirostat = mirostat
        self.cfg = cfg
    }
}
