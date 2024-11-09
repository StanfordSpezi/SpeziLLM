//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


// swiftlint:disable identifier_name
/// Represents the available LLM models.
public enum LLMLocalModel {
    /// Llama 3.1, 8 Billion Parameters, Instruct Mode, 4-bit Version
    case llama3_1_8B_4bit
    /// Llama 3, 8 Billion Parameters, Instruction-Tuned, 4-bit Version
    case llama3_8B_4bit
    /// Llama 3.2, 1 Billion Parameters, Instruction-Tuned, 4-bit Version
    case llama3_2_1B_4bit
    /// Llama 3.2, 3 Billion Parameters, Instruction-Tuned, 4-bit Version
    case llama3_2_3B_4bit
    /// Mistral Nemo, Instruction-Tuned, Model 2407, 4-bit Version
    case mistralNeMo4bit
    /// SmolLM, 135 Million Parameters, Instruction-Tuned, 4-bit Version
    case smolLM_135M_4bit
    /// Mistral, 7 Billion Parameters, Instruction-Tuned, Version 0.3, 4-bit Version
    case mistral7B4bit
    /// Code Llama, 13 Billion Parameters, Instruction-Tuned, Hugging Face Format, 4-bit, MLX Version
    case codeLlama13b4bit
    /// Phi 2, Hugging Face Format, 4-bit, MLX Version
    case phi4bit
    /// Phi 3 Mini, 4K Context Window, Instruction-Tuned, 4-bit Version, No Q-Embedding
    case phi3_4bit
    /// Phi 3.5 Mini, Instruction-Tuned, 4-bit Version
    case phi3_5_4bit
    /// Quantized Gemma, 2 Billion Parameters, Instruction-Tuned
    case gemma2bQuantized
    /// Gemma 2, 9 Billion Parameters, Instruction-Tuned, 4-bit Version
    case gemma_2_9b_it_4bit
    /// Gemma 2, 2 Billion Parameters, Instruction-Tuned, 4-bit Version
    case gemma_2_2b_it_4bit
    /// Qwen 1.5, 0.5 Billion Parameters, Chat-Tuned, 4-bit Version
    case qwen205b4bit
    /// OpenELM, 270 Million Parameters, Instruction-Tuned
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
