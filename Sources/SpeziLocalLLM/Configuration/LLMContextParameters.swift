//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


/// The ``LLMContextParameters`` represents the context parameters of the LLM.
/// Internally, these data points are passed as a llama.cpp `llama_context_params` C struct to the LLM.
public struct LLMContextParameters: Sendable {
    /// Wrapped C struct from the llama.cpp library, later-on passed to the LLM
    var wrapped: llama_context_params
    
    
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
    var nCtx: UInt32 {
        get {
            wrapped.n_ctx
        }
        set {
            wrapped.n_ctx = newValue
        }
    }
    
    /// Maximum batch size during prompt processing
    var nBatch: UInt32 {
        get {
            wrapped.n_batch
        }
        set {
            wrapped.n_batch = newValue
        }
    }
    
    /// Number of threads used by LLM for generation of output
    var nThreads: UInt32 {
        get {
            wrapped.n_threads
        }
        set {
            wrapped.n_threads = newValue
        }
    }
    
    /// Number of threads used by LLM for batch processing
    var nThreadsBatch: UInt32 {
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
    var mulMatQ: Bool {
        get {
            wrapped.mul_mat_q
        }
        set {
            wrapped.mul_mat_q = newValue
        }
    }
    
    /// If `true`, use fp16 for KV cache, fp32 otherwise
    var f16KV: Bool {
        get {
            wrapped.f16_kv
        }
        set {
            wrapped.f16_kv = newValue
        }
    }
    
    /// If `true`, the (deprecated) `llama_eval()` call computes all logits, not just the last one
    var logitsAll: Bool {
        get {
            wrapped.logits_all
        }
        set {
            wrapped.logits_all = newValue
        }
    }
    
    /// If `true`, the mode is set to embeddings only
    var embedding: Bool {
        get {
            wrapped.embedding
        }
        set {
            wrapped.embedding = newValue
        }
    }
    
    /// Creates the ``LLMContextParams`` which wrap the underlying llama.cpp `llama_context_params` C struct.
    /// Is passed to the underlying llama.cpp model in order to configure the context of the LLM.
    ///
    /// - Parameters:
    ///   - seed: RNG seed of the LLM, defaults to `4294967295` (which represents a random seed).
    ///   - nCtx: Context window size in tokens, defaults to `0` indicating the usage of the default window size from the model.
    ///   - nBatch: Maximum batch size during prompt processing, defaults to `512` tokens.
    ///   - nThreads: Number of threads used by LLM for generation of output, defaults to the processor count of the device.
    ///   - nThreadsBatch: Number of threads used by LLM for batch processing, defaults to the processor count of the device.
    ///   - ropeFreqBase: RoPE base frequency, defaults to `0` indicating the default from model.
    ///   - ropeFreqScale: RoPE frequency scaling factor, defaults to `0` indicating the default from model.
    ///   - mulMatQ: Usage of experimental `mul_mat_q` kernels, defaults to `true`.
    ///   - f16KV: Usage of fp16 for KV cache, fp32 otherwise, defaults to `true`.
    ///   - logitsAll: `llama_eval()` call computes all logits, not just the last one. Defaults to `false`.
    ///   - embedding: Embedding-only mode, defaults to `false`.
    public init(
        seed: UInt32 = 4294967295,
        nCtx: UInt32 = 0,
        nBatch: UInt32 = 512,
        nThreads: UInt32 = UInt32(ProcessInfo.processInfo.processorCount),
        nThreadsBatch: UInt32 = UInt32(ProcessInfo.processInfo.processorCount),
        ropeFreqBase: Float = 0.0,
        ropeFreqScale: Float = 0.0,
        mulMatQ: Bool = true,
        f16KV: Bool = true,
        logitsAll: Bool = false,
        embedding: Bool = false
    ) {
        self.wrapped = llama_context_params()
        
        self.seed = seed
        self.nCtx = nCtx
        self.nBatch = nBatch
        self.nThreads = nThreads
        self.nThreadsBatch = nThreadsBatch
        self.ropeFreqBase = ropeFreqBase
        self.ropeFreqScale = ropeFreqScale
        self.mulMatQ = mulMatQ
        self.f16KV = f16KV
        self.logitsAll = logitsAll
        self.embedding = embedding
    }
}
