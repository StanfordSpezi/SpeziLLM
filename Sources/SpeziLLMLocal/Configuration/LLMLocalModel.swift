//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


// swiftlint:disable identifier_name
/// The Local LLM Model that need to be used 
public enum LLMLocalModel {
    /// mlx-community/Meta-Llama-3.1-8B-Instruct-4bit
    case llama3_1_8B_4bit
    /// mlx-community/Meta-Llama-3-8B-Instruct-4bit
    case llama3_8B_4bit
    /// mlx-community/Llama-3.2-1B-Instruct-4bit
    case llama3_2_1B_4bit
    /// mlx-community/Llama-3.2-3B-Instruct-4bit
    case llama3_2_3B_4bit
    /// mlx-community/Mistral-Nemo-Instruct-2407-4bit
    case mistralNeMo4bit
    /// mlx-community/SmolLM-135M-Instruct-4bit
    case smolLM_135M_4bit
    /// mlx-community/Mistral-7B-Instruct-v0.3-4bit
    case mistral7B4bit
    /// mlx-community/CodeLlama-13b-Instruct-hf-4bit-MLX
    case codeLlama13b4bit
    /// mlx-community/phi-2-hf-4bit-mlx
    case phi4bit
    /// mlx-community/Phi-3-mini-4k-instruct-4bit-no-q-embed
    case phi3_4bit
    /// mlx-community/Phi-3.5-mini-instruct-4bit
    case phi3_5_4bit
    /// mlx-community/quantized-gemma-2b-it
    case gemma2bQuantized
    /// mlx-community/gemma-2-9b-it-4bit
    case gemma_2_9b_it_4bit
    /// mlx-community/gemma-2-2b-it-4bit
    case gemma_2_2b_it_4bit
    /// mlx-community/Qwen1.5-0.5B-Chat-4bit
    case qwen205b4bit
    /// mlx-community/OpenELM-270M-Instruct
    case openelm270m4bit
    /// Set the Huggingface ID of the model. e.g. "\<USER\>/\<MODEL\>"
    case custom(id: String)
    
    /// The Huggingface ID for the model
    public var hubID: String {
        switch self {
        case .llama3_1_8B_4bit:
            return "mlx-community/Meta-Llama-3.1-8B-Instruct-4bit"
        case .llama3_8B_4bit:
            return "mlx-community/Meta-Llama-3-8B-Instruct-4bit"
        case .llama3_2_1B_4bit:
            return "mlx-community/Llama-3.2-1B-Instruct-4bit"
        case .llama3_2_3B_4bit:
            return "mlx-community/Llama-3.2-3B-Instruct-4bit"
        case .mistralNeMo4bit:
            return "mlx-community/Mistral-Nemo-Instruct-2407-4bit"
        case .smolLM_135M_4bit:
            return "mlx-community/SmolLM-135M-Instruct-4bit"
        case .mistral7B4bit:
            return "mlx-community/Mistral-7B-Instruct-v0.3-4bit"
        case .codeLlama13b4bit:
            return "mlx-community/CodeLlama-13b-Instruct-hf-4bit-MLX"
        case .phi4bit:
            return "mlx-community/phi-2-hf-4bit-mlx"
        case .phi3_4bit:
            return "mlx-community/Phi-3-mini-4k-instruct-4bit-no-q-embed"
        case .phi3_5_4bit:
            return "mlx-community/Phi-3.5-mini-instruct-4bit"
        case .gemma2bQuantized:
            return "mlx-community/quantized-gemma-2b-it"
        case .gemma_2_9b_it_4bit:
            return "mlx-community/gemma-2-9b-it-4bit"
        case .gemma_2_2b_it_4bit:
            return "mlx-community/gemma-2-2b-it-4bit"
        case .qwen205b4bit:
            return "mlx-community/Qwen1.5-0.5B-Chat-4bit"
        case .openelm270m4bit:
            return "mlx-community/OpenELM-270M-Instruct"
        case .custom(let id):
            return id
        }
    }
}
