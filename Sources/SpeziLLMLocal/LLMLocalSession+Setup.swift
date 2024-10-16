//
//  LLMLocalSession+Setup.swift
//  SpeziLLM
//
//  Created by Leon Nissen on 10/4/24.
//

import Foundation
@preconcurrency import MLXLLM
@preconcurrency import Hub


extension LLMLocalSession {
    private func verifyModelDownload() -> Bool {
        let repo = Hub.Repo(id: self.schema.configuration.name)
        let url = HubApi.shared.localRepoLocation(repo)
        let modelFileExtension = ".safetensors"
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: url.path())
            return contents.first(where: { $0.hasSuffix(modelFileExtension) }) != nil
        } catch {
            return false
        }
    }
    
    
    func setup(continuation: AsyncThrowingStream<String, Error>.Continuation) async -> Bool {
        Self.logger.debug("SpeziLLMLocal: Local LLM is being initialized")
        
        await MainActor.run {
            self.state = .loading
        }
        
        guard verifyModelDownload() else {
            await finishGenerationWithError(LLMLocalError.modelNotFound, on: continuation)
            Self.logger.error("SpeziLLMLocal: Local LLM file could not be opened, indicating that the model file doesn't exist")
            return false
        }
        
        do {
            let modelContainer = try await loadModelContainer(configuration: self.schema.configuration)
            
            let numParams = await modelContainer.perform { [] model, _ in
                return model.numParameters()
            }
            
            await MainActor.run {
                self.modelContainer = modelContainer
                self.numParameters = numParams
                self.state = .ready
            }
        } catch {
            continuation.yield(with: .failure(error))
            Self.logger.error("SpeziLLMLocal: Failed to load local `modelContainer`")
            return false
        }
        return true
    }
}
