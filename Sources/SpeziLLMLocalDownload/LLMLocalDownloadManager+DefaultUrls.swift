//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension LLMLocalDownloadManager {
    /// Defaults of possible LLMs to download via the ``LLMLocalDownloadManager``.
    public enum LLMUrlDefaults {
        /// LLama 2 7B model with `Q4_K_M` quantization in its chat variation (~3.5GB)
        public static var llama2ChatModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf") else {
                preconditionFailure("""
                    SpeziLLM: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
        
        /// LLama 2 13B model with `Q4_K_M` quantization in its chat variation (~7GB)
        public static var llama2Chat13BModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/Llama-2-13B-chat-GGML/resolve/main/llama-2-13b-chat.ggmlv3.q4_K_M.bin") else {
                preconditionFailure("""
                    SpeziLLM: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
        
        /// Phi-2 model with `Q5_K_M` quantization (~2GB)
        public static var phi2ModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q5_K_M.gguf") else {
                preconditionFailure("""
                    SpeziLLM: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
        
        /// Gemma 7B model with `Q4_K_M` quantization (~5GB)
        public static var gemma7BModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/rahuldshetty/gemma-7b-it-gguf-quantized/resolve/main/gemma-7b-it-Q4_K_M.gguf") else {
                preconditionFailure("""
                    SpeziLLM: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
        
        /// Gemma 2B model with `Q4_K_M` quantization (~1.5GB)
        public static var gemma2BModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/rahuldshetty/gemma-2b-gguf-quantized/resolve/main/gemma-2b-Q4_K_M.gguf") else {
                preconditionFailure("""
                    SpeziLLM: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
        
        /// Tiny LLama 1.1B model with `Q5_K_M` quantization in its chat variation (~800MB)
        public static var tinyLLama2ModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q5_K_M.gguf") else {
                preconditionFailure("""
                    SpeziLLM: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
    }
}
