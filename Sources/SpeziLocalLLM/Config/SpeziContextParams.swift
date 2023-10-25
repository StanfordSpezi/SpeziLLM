//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


public struct SpeziContextParams: Sendable {
    var wrapped: llama_context_params
    
    
    // RNG seed, 4294967295 for random
    var seed: UInt32 {
        get {
            wrapped.seed
        }
        set {
            wrapped.seed = newValue
        }
    }
    
    // text context, 0 = from model
    var nCtx: UInt32 {
        get {
            wrapped.n_ctx
        }
        set {
            wrapped.n_ctx = newValue
        }
    }
    
    // prompt processing maximum batch size
    var nBatch: UInt32 {
        get {
            wrapped.n_batch
        }
        set {
            wrapped.n_batch = newValue
        }
    }
    
    // number of threads to use for generation
    var nThreads: UInt32 {
        get {
            wrapped.n_threads
        }
        set {
            wrapped.n_threads = newValue
        }
    }
    
    // number of threads to use for batch processing
    var nThreadsBatch: UInt32 {
        get {
            wrapped.n_threads_batch
        }
        set {
            wrapped.n_threads_batch = newValue
        }
    }
    
    // ref: https://github.com/ggerganov/llama.cpp/pull/2054
    // RoPE base frequency, 0 = from model
    var ropeFreqBase: Float {
        get {
            wrapped.rope_freq_base
        }
        set {
            wrapped.rope_freq_base = newValue
        }
    }
    
    // RoPE frequency scaling factor, 0 = from model
    var ropeFreqScale: Float {
        get {
            wrapped.rope_freq_scale
        }
        set {
            wrapped.rope_freq_scale = newValue
        }
    }

    // if true, use experimental mul_mat_q kernels
    var mulMatQ: Bool {
        get {
            wrapped.mul_mat_q
        }
        set {
            wrapped.mul_mat_q = newValue
        }
    }
    
    // use fp16 for KV cache, fp32 otherwise
    var f16KV: Bool {
        get {
            wrapped.f16_kv
        }
        set {
            wrapped.f16_kv = newValue
        }
    }
    
    // the llama_eval() call computes all logits, not just the last one
    var logitsAll: Bool {
        get {
            wrapped.logits_all
        }
        set {
            wrapped.logits_all = newValue
        }
    }
    
    // embedding mode only
    var embedding: Bool {
        get {
            wrapped.embedding
        }
        set {
            wrapped.embedding = newValue
        }
    }
    
    
    public init(
        seed: UInt32 = 0xFFFFFFFF,
        nCtx: UInt32 = 2048,    // TODO: Maybe 0, so take the context from the model
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
