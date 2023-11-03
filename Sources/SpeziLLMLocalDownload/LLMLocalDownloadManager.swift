//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import os


/// Manages the download of the LLM to the local device.
public final class LLMLocalDownloadManager: NSObject, ObservableObject, Sendable, URLSessionDownloadDelegate {
    /// Defaults of possible LLMs to download via the ``LLMLocalDownloadManager``.
    public enum LLMUrlsDefaults {
        /// Regular LLama 2 7B model in its chat variation (~3.5GB)
        public static var Llama2ChatModelUrl: URL {
            URL(string: "https://huggingface.co/TheBloke/Llama-2-7b-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_0.gguf")! // swiftlint:disable:this force_unwrapping
        }
        
        /// Tiny LLama2 1B model (~700MB)
        public static var TinyLLama2ModelUrl: URL {
            URL(string: "https://huggingface.co/TheBloke/Tinyllama-2-1b-miniguanaco-GGUF/resolve/main/tinyllama-2-1b-miniguanaco.Q4_0.gguf")!   // swiftlint:disable:this force_unwrapping
        }
    }
    
    /// An enum containing all possible states of the ``LLMLocalDownloadManager``.
    public enum DownloadState: Equatable {
        case idle
        case downloading(progress: Double)
        case downloaded
        case error(Error?)
        
        
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
    
    
    /// A Swift Logger that logs important information from the `LocalLLMDownloadManager`.
    private static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziML")
    /// Remote `URL` from where the LLM file should be downloaded.
    private let llmDownloadUrl: URL
    /// Local `URL` where the downloaded model is stored.
    let llmStorageUrl: URL
    /// Indicates the current state of the ``LocalLLMDownloadManager``.
    @MainActor @Published public var state: DownloadState = .idle
    
    
    /// Creates a ``LLMLocalDownloadManager`` that helps with downloading LLM files from remote servers.
    ///
    /// - Parameters:
    ///   - llmDownloadUrl: The remote `URL` from where the LLM file should be downloaded.
    ///   - llmStorageUrl: The local `URL` where the LLM file should be stored.
    public init(
        llmDownloadUrl: URL = LLMUrlsDefaults.Llama2ChatModelUrl,
        llmStorageUrl: URL = .cachesDirectory.appending(path: "llm.gguf")
    ) {
        self.llmDownloadUrl = llmDownloadUrl
        self.llmStorageUrl = llmStorageUrl
    }
    
    
    /// Starts a `URLSessionDownloadTask` to download the specified model.
    public func startDownload() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: self.llmDownloadUrl)
        task.resume()
    }
    
    // MARK: URLSessionDownloadDelegate
    /// Indicates the progress of the current model download.
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
        Task { @MainActor in
            self.state = .downloading(progress: progress)
        }
    }
    
    /// Indicates the completion of the model download including the downloaded file `URL`.
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            _ = try FileManager.default.replaceItemAt(self.llmStorageUrl, withItemAt: location)
        } catch {
            Task { @MainActor in
                self.state = .error(error)
            }
            Self.logger.error("\(String(describing: error))")
            return
        }
        
        Task { @MainActor in
            self.state = .downloaded
        }
    }
    
    /// Indicates an error during the model download
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            self.state = .error(error)
        }
        Self.logger.error("\(String(describing: error))")
    }
}
