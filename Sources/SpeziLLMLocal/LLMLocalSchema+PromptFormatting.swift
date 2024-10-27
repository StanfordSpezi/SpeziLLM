//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLM


extension LLMLocalSchema {
    /// Holds default prompt formatting strategies for [Llama2](https://ai.meta.com/llama/) as well as [Phi-2](https://www.microsoft.com/en-us/research/blog/phi-2-the-surprising-power-of-small-language-models/) models.
    public enum PromptFormattingDefaults {
        /// Prompt formatting closure for the [Llama3](https://ai.meta.com/llama/) model
        public static let llama3: (@Sendable (LLMContext) throws -> String) = { chat in // swiftlint:disable:this closure_body_length
            /// BOS token of the LLM, used at the start of each prompt passage.
            let BEGINOFTEXT = "<|begin_of_text|>"
            /// The system identifier.
            let SYSTEM = "system"
            /// The user identifier.
            let USER = "user"
            /// The assistant identifier.
            let ASSISTANT = "assistant"
            /// The start token for enclosing the role of a particular message, e.g. <|start_header_id|>{role}<|end_header_id|>
            let STARTHEADERID = "<|start_header_id|>"
            /// The end token for enclosing the role of a particular message, e.g. <|start_header_id|>{role}<|end_header_id|>
            let ENDHEADERID = "<|end_header_id|>"
            /// The token that signifies the end of the message in a turn.
            let EOTID = "<|eot_id|>"
            
            guard chat.first?.role == .system else {
                throw LLMLocalError.illegalContext
            }
            
            var systemPrompts: [String] = []
            var initialUserPrompt: String = ""
            
            for contextEntity in chat {
                if contextEntity.role != .system {
                    if contextEntity.role == .user {
                        initialUserPrompt = contextEntity.content
                        break
                    } else {
                        throw LLMLocalError.illegalContext
                    }
                }
                
                systemPrompts.append(contextEntity.content)
            }
            
            /// Build the initial Llama3 prompt structure
            /// 
            /// Template of the prompt structure:
            /// <|begin_of_text|>
            /// <|start_header_id|>user<|end_header_id|>
            /// {{ user_message }}<|eot_id|>
            /// <|start_header_id|>assistant<|end_header_id|>
            var prompt = """
            \(BEGINOFTEXT)
            \(STARTHEADERID)\(SYSTEM)\(ENDHEADERID)
            \(systemPrompts.joined(separator: " "))\(EOTID)
            
            \(STARTHEADERID)\(USER)\(ENDHEADERID)
            \(initialUserPrompt)\(EOTID)
            
            """ + " "   // Add a spacer to the generated output from the model
            
            for contextEntity in chat.dropFirst(2) {
                if contextEntity.role == .assistant() {
                    /// Append response from assistant to the Llama3 prompt structure
                    prompt += """
                    \(STARTHEADERID)\(ASSISTANT)\(ENDHEADERID)
                    \(contextEntity.content)
                    \(EOTID)
                    """
                } else if contextEntity.role == .user {
                    /// Append response from user to the Llama3 prompt structure
                    prompt += """
                    \(STARTHEADERID)\(USER)\(ENDHEADERID)
                    \(contextEntity.content)
                    \(EOTID)
                    """ + " "   // Add a spacer to the generated output from the model
                }
            }
            
            prompt +=
            """
            \(STARTHEADERID)\(ASSISTANT)\(ENDHEADERID)
            """
            
            return prompt
        }
        
        /// Prompt formatting closure for the [Llama2](https://ai.meta.com/llama/) model
        public static let llama2: (@Sendable (LLMContext) throws -> String) = { chat in     // swiftlint:disable:this closure_body_length
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
            
            for contextEntity in chat {
                if contextEntity.role != .system {
                    if contextEntity.role == .user {
                        initialUserPrompt = contextEntity.content
                        break
                    } else {
                        throw LLMLocalError.illegalContext
                    }
                }
                
                systemPrompts.append(contextEntity.content)
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
            
            for contextEntity in chat.dropFirst(2) {
                if contextEntity.role == .assistant() {
                    /// Append response from assistant to the Llama2 prompt structure
                    ///
                    /// A template for appending an assistant response to the overall prompt looks like:
                    /// {user_message_1} [/INST]){model_reply_1}</s>
                    prompt += """
                    \(contextEntity.content)\(EOS)
                    """
                } else if contextEntity.role == .user {
                    /// Append response from user to the Llama2 prompt structure
                    ///
                    /// A template for appending an assistant response to the overall prompt looks like:
                    /// <s>[INST] {user_message_2} [/INST]
                    prompt += """
                    \(BOS)\(BOINST) \(contextEntity.content) \(EOINST)
                    """ + " "   // Add a spacer to the generated output from the model
                }
            }
            
            return prompt
        }
        
        /// Prompt formatting closure for the [Phi-2](https://www.microsoft.com/en-us/research/blog/phi-2-the-surprising-power-of-small-language-models/) model
        public static let phi2: (@Sendable (LLMContext) throws -> String) = { chat in
            guard chat.first?.role == .system else {
                throw LLMLocalError.illegalContext
            }
            
            var systemPrompts: [String] = []
            var initialUserPrompt: String = ""
            
            for contextEntity in chat {
                if contextEntity.role != .system {
                    if contextEntity.role == .user {
                        initialUserPrompt = contextEntity.content
                        break
                    } else {
                        throw LLMLocalError.illegalContext
                    }
                }
                
                systemPrompts.append(contextEntity.content)
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
            
            for contextEntity in chat.dropFirst(2) {
                if contextEntity.role == .assistant() {
                    /// Append response from assistant to the Phi-2 prompt structure
                    prompt += """
                    Output: \(contextEntity.content)\n
                    """
                } else if contextEntity.role == .user {
                    /// Append response from assistant to the Phi-2 prompt structure
                    prompt += """
                    Instruct: \(contextEntity.content)\n
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
        /// - Important: System prompts are ignored as Gemma doesn't support them
        public static let gemma: (@Sendable (LLMContext) throws -> String) = { chat in
            /// Start token of Gemma
            let startToken = "<start_of_turn>"
            /// End token of Gemma
            let endToken = "<end_of_turn>"
            
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
            
            for contextEntity in chat {
                if contextEntity.role == .assistant() {
                    /// Append response from assistant to the Gemma prompt structure
                    prompt += """
                    \(startToken)model
                    \(contextEntity.content)\(endToken)\n
                    """
                } else if contextEntity.role == .user {
                    /// Append response from assistant to the Gemma prompt structure
                    prompt += """
                    \(startToken)user
                    \(contextEntity.content)\(endToken)\n
                    """
                }
            }
            
            /// Model starts responding after
            if chat.last?.role == .user {
                prompt += "\(startToken)model\n"
            }
            
            return prompt
        }
    }
}
