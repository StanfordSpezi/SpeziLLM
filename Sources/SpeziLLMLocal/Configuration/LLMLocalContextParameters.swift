//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


/// Represents the context parameters of the LLM.
/// 
/// Internally, these data points are passed as a llama.cpp `llama_context_params` C struct to the LLM.
public struct LLMLocalContextParameters: Sendable {
    // swiftlint:disable identifier_name
    /// Swift representation of the `ggml_type` of llama.cpp, indicating data types within KV caches.
    public enum GGMLType: UInt32 {
        case f32 = 0
        case f16
        case q4_0
        case q4_1
        case q5_0 = 6
        case q5_1
        case q8_0
        case q8_1
        /// k-quantizations
        case q2_k
        case q3_k
        case q4_k
        case q5_k
        case q6_k
        case q8_k
        case iq2_xxs
        case iq2_xs
        case i8
        case i16
        case i32
    }
    // swiftlint:enable identifier_name
    
    
    /// Wrapped C struct from the llama.cpp library, later-on passed to the LLM
    private var wrapped: llama_context_params
    
    
    /// Context parameters in llama.cpp's low-level C representation
    var llamaCppRepresentation: llama_context_params {
        wrapped
    }
    
    /// RNG seed of the LLM
    var seed: UInt32 {
        get {
            wrapped.seed
        }
        set {
            wrapped.seed = newValue
        }
    }
    
    /// Context window size in tokens (0 = take default window size from model)
    var contextWindowSize: UInt32 {
        get {
            wrapped.n_ctx
        }
        set {
            wrapped.n_ctx = newValue
        }
    }
    
    /// Maximum batch size during prompt processing
    var batchSize: UInt32 {
        get {
            wrapped.n_batch
        }
        set {
            wrapped.n_batch = newValue
        }
    }
    
    /// Number of threads used by LLM for generation of output
    var threadCount: UInt32 {
        get {
            wrapped.n_threads
        }
        set {
            wrapped.n_threads = newValue
        }
    }
    
    /// Number of threads used by LLM for batch processing
    var threadCountBatch: UInt32 {
        get {
            wrapped.n_threads_batch
        }
        set {
            wrapped.n_threads_batch = newValue
        }
    }
    
    /// RoPE base frequency (0 = take default from model)
    var ropeFreqBase: Float {
        get {
            wrapped.rope_freq_base
        }
        set {
            wrapped.rope_freq_base = newValue
        }
    }
    
    /// RoPE frequency scaling factor (0 = take default from model)
    var ropeFreqScale: Float {
        get {
            wrapped.rope_freq_scale
        }
        set {
            wrapped.rope_freq_scale = newValue
        }
    }

    /// Set the usage of experimental `mul_mat_q` kernels
    var useMulMatQKernels: Bool {
        get {
            wrapped.mul_mat_q
        }
        set {
            wrapped.mul_mat_q = newValue
        }
    }
    
    /// If `true`, offload the KQV ops (including the KV cache) to GPU
    var offloadKQV: Bool {
        get {
            wrapped.offload_kqv
        }
        set {
            wrapped.offload_kqv = newValue
        }
    }
    
    /// ``GGMLType`` of the key of the KV cache
    var kvKeyType: GGMLType {
        get {
            GGMLType(rawValue: wrapped.type_k.rawValue) ?? .f16
        }
        set {
            wrapped.type_k = ggml_type(rawValue: newValue.rawValue)
        }
    }
    
    /// ``GGMLType`` of the value of the KV cache
    var kvValueType: GGMLType {
        get {
            GGMLType(rawValue: wrapped.type_v.rawValue) ?? .f16
        }
        set {
            wrapped.type_v = ggml_type(rawValue: newValue.rawValue)
        }
    }
    
    /// If `true`, the (deprecated) `llama_eval()` call computes all logits, not just the last one
    var computeAllLogits: Bool {
        get {
            wrapped.logits_all
        }
        set {
            wrapped.logits_all = newValue
        }
    }
    
    /// If `true`, the mode is set to embeddings only
    var embeddingsOnly: Bool {
        get {
            wrapped.embedding
        }
        set {
            wrapped.embedding = newValue
        }
    }
    
    /// Creates the ``LLMLocalContextParameters`` which wrap the underlying llama.cpp `llama_context_params` C struct.
    /// Is passed to the underlying llama.cpp model in order to configure the context of the LLM.
    ///
    /// - Parameters:
    ///   - seed: RNG seed of the LLM, defaults to `4294967295` (which represents a random seed).
    ///   - contextWindowSize: Context window size in tokens, defaults to `1024`.
    ///   - batchSize: Maximum batch size during prompt processing, defaults to `1024` tokens.
    ///   - threadCount: Number of threads used by LLM for generation of output, defaults to the processor count of the device.
    ///   - threadCountBatch: Number of threads used by LLM for batch processing, defaults to the processor count of the device.
    ///   - ropeFreqBase: RoPE base frequency, defaults to `0` indicating the default from model.
    ///   - ropeFreqScale: RoPE frequency scaling factor, defaults to `0` indicating the default from model.
    ///   - useMulMatQKernels: Usage of experimental `mul_mat_q` kernels, defaults to `true`.
    ///   - offloadKQV: Offloads the KQV ops (including the KV cache) to GPU, defaults to `true`.
    ///   - kvKeyType: ``GGMLType`` of the key of the KV cache, defaults to ``GGMLType/f16``.
    ///   - kvValueType: ``GGMLType`` of the value of the KV cache, defaults to ``GGMLType/f16``.
    ///   - computeAllLogits: `llama_eval()` call computes all logits, not just the last one. Defaults to `false`.
    ///   - embeddingsOnly: Embedding-only mode, defaults to `false`.
    public init(
        seed: UInt32 = 4294967295,
        contextWindowSize: UInt32 = 1024,
        batchSize: UInt32 = 1024,
        threadCount: UInt32 = .init(ProcessInfo.processInfo.processorCount),
        threadCountBatch: UInt32 = .init(ProcessInfo.processInfo.processorCount),
        ropeFreqBase: Float = 0.0,
        ropeFreqScale: Float = 0.0,
        useMulMatQKernels: Bool = true,
        offloadKQV: Bool = true,
        kvKeyType: GGMLType = .f16,
        kvValueType: GGMLType = .f16,
        computeAllLogits: Bool = false,
        embeddingsOnly: Bool = false
    ) {
        self.wrapped = llama_context_default_params()
        
        self.seed = seed
        self.contextWindowSize = contextWindowSize
        self.batchSize = batchSize
        self.threadCount = threadCount
        self.threadCountBatch = threadCountBatch
        self.ropeFreqBase = ropeFreqBase
        self.ropeFreqScale = ropeFreqScale
        self.useMulMatQKernels = useMulMatQKernels
        self.offloadKQV = offloadKQV
        self.kvKeyType = kvKeyType
        self.kvValueType = kvValueType
        self.computeAllLogits = computeAllLogits
        self.embeddingsOnly = embeddingsOnly
    }
}
