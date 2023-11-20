//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Manages the download of an LLM to the local device.
public final class LLMLocalDownloadManager: NSObject, ObservableObject {
    /// Defaults of possible LLMs to download via the ``LLMLocalDownloadManager``.
    public enum LLMUrlDefaults {
        /// LLama 2 7B model in its chat variation (~3.5GB)
        public static var llama2ChatModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/Llama-2-7b-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_0.gguf") else {
                preconditionFailure("""
                    SpeziML: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
        
        /// LLama 2 13B model in its chat variation (~7GB)
        public static var llama2Chat13BModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/Llama-2-13B-chat-GGML/resolve/main/llama-2-13b-chat.ggmlv3.q4_0.bin") else {
                preconditionFailure("""
                    SpeziML: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
        
        /// Tiny LLama2 1B model (~700MB)
        public static var tinyLLama2ModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v0.3-GGUF/resolve/main/tinyllama-1.1b-chat-v0.3.Q4_0.gguf") else {
                preconditionFailure("""
                    SpeziML: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
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
    
    /// The delegate handling the download manager tasks.
    private var downloadDelegate: LLMLocalDownloadManagerDelegate?
    /// The `URLSessionDownloadTask` that handles the download of the model.
    private var downloadTask: URLSessionDownloadTask?
    /// Remote `URL` from where the LLM file should be downloaded.
    private let llmDownloadUrl: URL
    /// Local `URL` where the downloaded model is stored.
    let llmStorageUrl: URL
    /// Indicates the current state of the ``LLMLocalDownloadManager``.
    @MainActor @Published public var state: DownloadState = .idle
    
    
    /// Creates a ``LLMLocalDownloadManager`` that helps with downloading LLM files from remote servers.
    ///
    /// - Parameters:
    ///   - llmDownloadUrl: The remote `URL` from where the LLM file should be downloaded.
    ///   - llmStorageUrl: The local `URL` where the LLM file should be stored.
    public init(
        llmDownloadUrl: URL = LLMUrlDefaults.llama2ChatModelUrl,
        llmStorageUrl: URL = .cachesDirectory.appending(path: "llm.gguf")
    ) {
        self.llmDownloadUrl = llmDownloadUrl
        self.llmStorageUrl = llmStorageUrl
    }
    
    
    /// Starts a `URLSessionDownloadTask` to download the specified model.
    public func startDownload() {
        downloadTask?.cancel()
        
        downloadDelegate = LLMLocalDownloadManagerDelegate(manager: self, storageUrl: llmStorageUrl)
        let session = URLSession(configuration: .default, delegate: downloadDelegate, delegateQueue: nil)
        downloadTask = session.downloadTask(with: llmDownloadUrl)
        
        downloadTask?.resume()
    }
}
