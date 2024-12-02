//
//  LLMUpdateableLocalSchema.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 12/1/24.
//

import Foundation
import SpeziLLM

extension LLMLocalSession {
    public func update(
        parameters: LLMLocalParameters? = nil,
        contextParameters: LLMLocalContextParameters? = nil,
        samplingParameters: LLMLocalSamplingParameters? = nil,
        injectIntoContext: Bool? = nil
    ) {
        cancel()
        
        self.schema = .init(
            configuration: self.schema.configuration,
            parameters: parameters ?? self.schema.parameters,
            contextParameters: contextParameters ?? self.schema.contextParameters,
            samplingParameters: samplingParameters ?? self.schema.samplingParameters,
            injectIntoContext: injectIntoContext ?? self.schema.injectIntoContext
        )
    }
}
