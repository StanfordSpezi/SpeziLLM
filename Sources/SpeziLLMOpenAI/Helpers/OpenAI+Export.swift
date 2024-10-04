//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAPIRuntime

/// Convenience export of the `OpenAI/Model` type.
///
/// The ``LLMOpenAIModelType`` exports the `OpenAI/Model` describing the type of the to-be-used OpenAI Model.
/// This enables convenience access to the `OpenAI/Model` without naming conflicts resulting from the `OpenAI/Model` name.
public typealias LLMOpenAIModelType = Components.Schemas.CreateChatCompletionRequest.modelPayload
