//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziChat


extension LLMLocalSchema {
    /// Holds default prompt formatting strategies for [Llama2](https://ai.meta.com/llama/) as well as [Phi-2](https://www.microsoft.com/en-us/research/blog/phi-2-the-surprising-power-of-small-language-models/) models.
    public enum PromptFormattingDefaults {
        /// Prompt formatting closure for the [Llama2](https://ai.meta.com/llama/) model
        public static let llama2: (@Sendable (Chat) throws -> String) = { chat in     // swiftlint:disable:this closure_body_length
            /// BOS token of the LLM, used at the start of each prompt passage.
            let BOS = "<s>"
            /// EOS token of the LLM, used at the end of each prompt passage.
            let EOS = "</s>"
            /// BOSYS token of the LLM, used at the start of the system prompt.
            let BOSYS = "<<SYS>>"
            /// EOSYS token of the LLM, used at the end of the system prompt.
            let EOSYS = "<</SYS>>"
            /// BOINST token of the LLM, used at the start of the instruction part of the prompt.
            let BOINST = "[INST]"
            /// EOINST token of the LLM, used at the end of the instruction part of the prompt.
            let EOINST = "[/INST]"
            
            guard chat.first?.role == .system else {
                throw LLMLocalError.illegalContext
            }
            
            var systemPrompts: [String] = []
            var initialUserPrompt: String = ""
            
            for chatEntity in chat {
                if chatEntity.role != .system {
                    if chatEntity.role == .user {
                        initialUserPrompt = chatEntity.content
                        break
                    } else {
                        throw LLMLocalError.illegalContext
                    }
                }
                
                systemPrompts.append(chatEntity.content)
            }
            
            /// Build the initial Llama2 prompt structure
            ///
            /// A template of the prompt structure looks like:
            /// """
            /// <s>[INST] <<SYS>>
            /// {your_system_prompt}
            /// <</SYS>>
            ///
            /// {user_message_1} [/INST]
            /// """
            var prompt = """
            \(BOS)\(BOINST) \(BOSYS)
            \(systemPrompts.joined(separator: " "))
            \(EOSYS)
            
            \(initialUserPrompt) \(EOINST)
            """ + " "   // Add a spacer to the generated output from the model
            
            for chatEntry in chat.dropFirst(2) {
                if chatEntry.role == .assistant {
                    /// Append response from assistant to the Llama2 prompt structure
                    ///
                    /// A template for appending an assistant response to the overall prompt looks like:
                    /// {user_message_1} [/INST]){model_reply_1}</s>
                    prompt += """
                    \(chatEntry.content)\(EOS)
                    """
                } else if chatEntry.role == .user {
                    /// Append response from user to the Llama2 prompt structure
                    ///
                    /// A template for appending an assistant response to the overall prompt looks like:
                    /// <s>[INST] {user_message_2} [/INST]
                    prompt += """
                    \(BOS)\(BOINST) \(chatEntry.content) \(EOINST)
                    """ + " "   // Add a spacer to the generated output from the model
                }
            }
            
            return prompt
        }
        
        /// Prompt formatting closure for the [Phi-2](https://www.microsoft.com/en-us/research/blog/phi-2-the-surprising-power-of-small-language-models/) model
        public static let phi2: (@Sendable (Chat) throws -> String) = { chat in
            guard chat.first?.role == .system else {
                throw LLMLocalError.illegalContext
            }
            
            var systemPrompts: [String] = []
            var initialUserPrompt: String = ""
            
            for chatEntity in chat {
                if chatEntity.role != .system {
                    if chatEntity.role == .user {
                        initialUserPrompt = chatEntity.content
                        break
                    } else {
                        throw LLMLocalError.illegalContext
                    }
                }
                
                systemPrompts.append(chatEntity.content)
            }
            
            /// Build the initial Phi-2 prompt structure
            ///
            /// A template of the prompt structure looks like:
            /// """
            /// System: {your_system_prompt}
            /// Instruct: {model_reply_1}
            /// Output: {model_reply_1}
            /// """
            var prompt = """
            System: \(systemPrompts.joined(separator: " "))
            Instruct: \(initialUserPrompt)\n
            """
            
            for chatEntry in chat.dropFirst(2) {
                if chatEntry.role == .assistant {
                    /// Append response from assistant to the Phi-2 prompt structure
                    prompt += """
                    Output: \(chatEntry.content)\n
                    """
                } else if chatEntry.role == .user {
                    /// Append response from assistant to the Phi-2 prompt structure
                    prompt += """
                    Instruct: \(chatEntry.content)\n
                    """
                }
            }
            
            /// Model starts responding after
            if chat.last?.role == .user {
                prompt += "Output: "
            }
            
            return prompt
        }
        
        /// Prompt formatting closure for the [Gemma](https://ai.google.dev/gemma/docs/formatting) models
        public static let gemma: (@Sendable (Chat) throws -> String) = { chat in
            /// Start token of Gemma
            let startToken = "<start_of_turn>"
            /// End token of Gemma
            let endToken = "<end_of_turn>"
            
            /// Gemma doesn't allow for system prompts
            guard !chat.contains(where: {
                switch $0.role {
                case .system, .function: true
                default: false
                }}) else {
                throw LLMLocalError.illegalContext
            }
            
            /// Build the initial Gemma prompt structure
            ///
            /// A template of the prompt structure looks like:
            /// """
            /// <start_of_turn>user
            /// knock knock<end_of_turn>
            /// <start_of_turn>model
            /// who is there<end_of_turn>
            /// <start_of_turn>user
            /// Gemma<end_of_turn>
            /// <start_of_turn>model
            /// Gemma who?<end_of_turn>
            /// """
            var prompt = ""
            
            for chatEntry in chat {
                if chatEntry.role == .assistant {
                    /// Append response from assistant to the Gemma prompt structure
                    prompt += """
                    \(startToken)model
                    \(chatEntry.content)\(endToken)\n
                    """
                } else if chatEntry.role == .user {
                    /// Append response from assistant to the Gemma prompt structure
                    prompt += """
                    \(startToken)user
                    \(chatEntry.content)\(endToken)\n
                    """
                }
            }
            
            /// Model starts responding after
            if chat.last?.role == .user {
                prompt += "\(startToken)model"
            }
            
            return prompt
        }
    }
}
