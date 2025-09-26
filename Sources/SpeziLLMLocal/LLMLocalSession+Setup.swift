//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Hub
import MLXLLM
import MLXLMCommon


extension LLMLocalSession {
    private func verifyModelDownload() -> Bool {
        let repo = Hub.Repo(id: self.schema.configuration.name)
        let url = Self.hubApi.localRepoLocation(repo)
        let modelFileExtension = ".safetensors"
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: url.path())
            return contents.contains { $0.hasSuffix(modelFileExtension) }
        } catch {
            return false
        }
    }
    
    // swiftlint:disable:next identifier_name
    internal func _setup(continuation: AsyncThrowingStream<String, any Error>.Continuation?) async -> Bool {
#if targetEnvironment(simulator)
        return await _mockSetup(continuation: continuation)
#else
        Self.logger.debug("SpeziLLMLocal: Local LLM is being initialized")
        
        await MainActor.run {
            self.state = .loading
        }
        
        guard verifyModelDownload() else {
            if let continuation {
                await finishGenerationWithError(LLMLocalError.modelNotFound, on: continuation)
            }
            Self.logger.error("SpeziLLMLocal: Local LLM file could not be opened, indicating that the model file doesn't exist")
            return false
        }
        
        do {
            let modelContainer = try await LLMModelFactory.shared.loadContainer(configuration: self.schema.configuration)
            
            let numParams = await modelContainer.perform { modelContext in
                modelContext.model.numParameters()
            }
            
            await MainActor.run {
                self.modelContainer = modelContainer
                self.numParameters = numParams
                self.state = .ready
            }
        } catch {
            continuation?.yield(with: .failure(error))
            Self.logger.error("SpeziLLMLocal: Failed to load local `modelContainer`")
            return false
        }
        
        Self.logger.debug("SpeziLLMLocal: Local LLM has finished initializing")
        return true
#endif
    }
    
    private func _mockSetup(continuation: AsyncThrowingStream<String, any Error>.Continuation?) async -> Bool {
        Self.logger.debug("SpeziLLMLocal: Local Mock LLM is being initialized")
        
        await MainActor.run {
            self.state = .loading
        }
        
        try? await Task.sleep(for: .seconds(1))
        
        await MainActor.run {
            self.state = .ready
        }
        
        Self.logger.debug("SpeziLLMLocal: Local Mock LLM has finished initializing")
        
        return true
    }
}
