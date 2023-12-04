//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


/// The ``LLMContextParameters`` represents the context parameters of the LLM.
/// Internally, these data points are passed as a llama.cpp `llama_context_params` C struct to the LLM.
public struct LLMContextParameters: Sendable {
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
    
    /// If `true`, use fp16 for KV cache, fp32 otherwise
    var useFp16Cache: Bool {
        get {
            wrapped.f16_kv
        }
        set {
            wrapped.f16_kv = newValue
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
    
    /// Creates the ``LLMContextParameters`` which wrap the underlying llama.cpp `llama_context_params` C struct.
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
    ///   - useFp16Cache: Usage of fp16 for KV cache, fp32 otherwise, defaults to `true`.
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
        useFp16Cache: Bool = true,
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
        self.useFp16Cache = useFp16Cache
        self.computeAllLogits = computeAllLogits
        self.embeddingsOnly = embeddingsOnly
    }
}
