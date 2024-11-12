//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Hub
import MLXLLM
import Observation
import SpeziLLMLocal
import SpeziViews

/// Manages the download and storage of Large Language Models (LLM) to the local device.
///
/// One configures the ``LLMLocalDownloadManager`` via the ``LLMLocalDownloadManager/init(llmDownloadUrl:llmStorageUrl:)`` initializer,
/// passing a download `URL` as well as a storage `URL` to the ``LLMLocalDownloadManager``.
/// The download of a model is started via ``LLMLocalDownloadManager/startDownload()`` and can be cancelled (early) via ``LLMLocalDownloadManager/cancelDownload()``.
/// 
/// The current state of the ``LLMLocalDownloadManager`` is exposed via the ``LLMLocalDownloadManager/state`` property which
/// is of type ``LLMLocalDownloadManager/DownloadState``, containing states such as ``LLMLocalDownloadManager/DownloadState/downloading(progress:)``
/// which includes the progress of the download or ``LLMLocalDownloadManager/DownloadState/downloaded(storageUrl:)`` which indicates that the download has finished.
@Observable
public final class LLMLocalDownloadManager: NSObject {
    /// An enum containing all possible states of the ``LLMLocalDownloadManager``.
    public enum DownloadState: Equatable {
        case idle
        case downloading(progress: Progress)
        case downloaded(storageUrl: URL)
        case error(LocalizedError)
        
        
        public static func == (lhs: LLMLocalDownloadManager.DownloadState, rhs: LLMLocalDownloadManager.DownloadState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): true
            case (.downloading, .downloading): true
            case (.downloaded, .downloaded): true
            case (.error, .error): true
            default: false
            }
        }
    }
    
    /// The `URLSessionDownloadTask` that handles the download of the model.
    @ObservationIgnored private var downloadTask: Task<(), Never>?
    /// Indicates the current state of the ``LLMLocalDownloadManager``.
    @MainActor public var state: DownloadState = .idle
    private let modelConfiguration: ModelConfiguration
    
    @ObservationIgnored public var modelExists: Bool {
        LLMLocalDownloadManager.modelExsist(model: .custom(id: modelConfiguration.name))
    }
    
    /// Initializes a ``LLMLocalDownloadManager`` instance to manage the download of Large Language Model (LLM) files from remote servers.
    ///
    /// - Parameters:
    ///   - modelID: The Huggingface model ID of the LLM that needs to be downloaded.
    public init(model: LLMLocalModel) {
        self.modelConfiguration = .init(id: model.hubID)
    }
    
    /// Checks if a model is already downloaded to the local device.
    ///
    /// - Parameter model: The model to check for local existence.
    /// - Returns: A Boolean value indicating whether the model exists on the device.
    public static func modelExsist(model: LLMLocalModel) -> Bool {
        let repo = Hub.Repo(id: model.hubID)
        let url = HubApi.shared.localRepoLocation(repo)
        let modelFileExtension = ".safetensors"
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: url.path())
            return contents.contains { $0.hasSuffix(modelFileExtension) }
        } catch {
            return false
        }
    }
    
    /// Starts a `URLSessionDownloadTask` to download the specified model.
    public func startDownload() {
        if case let .directory(url) = modelConfiguration.id {
            Task { @MainActor in
                self.state = .downloaded(storageUrl: url)
            }
            return
        }
        
        downloadTask?.cancel()
        downloadTask = Task(priority: .userInitiated) {
            do {
                _ = try await loadModelContainer(configuration: modelConfiguration) { progress in
                    Task { @MainActor in
                        self.state = .downloading(progress: progress)
                    }
                }
                
                Task { @MainActor in
                    self.state = .downloaded(storageUrl: modelConfiguration.modelDirectory())
                }
            } catch {
                Task { @MainActor in
                    self.state = .error(
                        AnyLocalizedError(
                            error: error,
                            defaultErrorDescription: LocalizedStringResource("LLM_DOWNLOAD_FAILED_ERROR", bundle: .atURL(from: .module))
                        )
                    )
                }
            }
        }
    }
    
    /// Cancels the download of a specified model via a `URLSessionDownloadTask`.
    public func cancelDownload() {
        downloadTask?.cancel()
    }
}
