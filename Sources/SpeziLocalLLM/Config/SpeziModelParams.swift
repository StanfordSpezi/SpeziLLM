//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import llama


public struct SpeziModelParams: Sendable {
    public typealias LlamaProgressCallback = (@convention(c) (Float, UnsafeMutableRawPointer?) -> Void)
    
    let nLength: Int
    let addBos: Bool
    var wrapped: llama_model_params
    
    
    // number of layers to store in VRAM/
    var nGpuLayers: Int32 {
        get {
            wrapped.n_gpu_layers
        }
        set {
            wrapped.n_gpu_layers = newValue
        }
    }
    
    // the GPU that is used for scratch and small tensors
    var mainGpu: Int32 {
        get {
            wrapped.main_gpu
        }
        set {
            wrapped.main_gpu = newValue
        }
    }
    
    // how to split layers across multiple GPUs (size: LLAMA_MAX_DEVICES)
    var tensorSplit: UnsafePointer<Float>? {
        get {
            wrapped.tensor_split
        }
        set {
            wrapped.tensor_split = newValue
        }
    }

    // called with a progress value between 0 and 1, pass NULL to disable
    var progressCallback: LlamaProgressCallback? {
        get {
            wrapped.progress_callback
        }
        set {
            wrapped.progress_callback = newValue
        }
    }
    
    // context pointer passed to the progress callback
    var progressCallbackUserData: UnsafeMutableRawPointer? {
        get {
            wrapped.progress_callback_user_data
        }
        set {
            wrapped.progress_callback_user_data = newValue
        }
    }

    // Keep the booleans together to avoid misalignment during copy-by-value.
    var vocabOnly: Bool {
        get {
            wrapped.vocab_only
        }
        set {
            wrapped.vocab_only = newValue
        }
    }
    
    // use mmap if possible
    var useMmap: Bool {
        get {
            wrapped.use_mmap
        }
        set {
            wrapped.use_mmap = newValue
        }
    }
    
    // force system to keep model in RAM
    var useMlock: Bool {
        get {
            wrapped.use_mlock
        }
        set {
            wrapped.use_mlock = newValue
        }
    }
    
    
    public init(
        nLength: Int = 128,
        addBos: Bool = false,
        nGpuLayers: Int32 = 1,
        mainGpu: Int32 = 0,
        tensorSplit: UnsafePointer<Float>? = nil,
        progressCallback: LlamaProgressCallback? = nil,
        progressCallbackUserData: UnsafeMutableRawPointer? = nil,
        vocabOnly: Bool = false,
        useMmap: Bool = true,
        useMlock: Bool = false
    ) {
        self.wrapped = llama_model_params()
        
        self.nLength = nLength
        self.addBos = addBos
        
        // Overwrite nGpuLayers in case of a simulator target environment
        #if targetEnvironment(simulator)
        self.nGpuLayers = 0     // Disable Metal on simulator as crash otherwise
        #endif
        self.nGpuLayers = nGpuLayers
        self.mainGpu = mainGpu
        self.tensorSplit = tensorSplit
        self.progressCallback = progressCallback
        self.progressCallbackUserData = progressCallbackUserData
        self.vocabOnly = vocabOnly
        self.useMmap = useMmap
        self.useMlock = useMlock
    }
}
