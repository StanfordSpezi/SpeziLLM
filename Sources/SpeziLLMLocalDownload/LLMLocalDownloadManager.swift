//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Observation
import SpeziViews


/// The ``LLMLocalDownloadManager`` manages the download and storage of Large Language Models (LLM) to the local device.
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
    /// Defaults of possible LLMs to download via the ``LLMLocalDownloadManager``.
    public enum LLMUrlDefaults {
        /// LLama 2 7B model in its chat variation (~3.5GB)
        public static var llama2ChatModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/Llama-2-7b-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_0.gguf") else {
                preconditionFailure("""
                    SpeziLLM: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
        
        /// LLama 2 13B model in its chat variation (~7GB)
        public static var llama2Chat13BModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/Llama-2-13B-chat-GGML/resolve/main/llama-2-13b-chat.ggmlv3.q4_0.bin") else {
                preconditionFailure("""
                    SpeziLLM: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
        
        /// Tiny LLama2 1B model (~700MB)
        public static var tinyLLama2ModelUrl: URL {
            guard let url = URL(string: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v0.3-GGUF/resolve/main/tinyllama-1.1b-chat-v0.3.Q4_0.gguf") else {
                preconditionFailure("""
                    SpeziLLM: Invalid LLMUrlDefaults LLM download URL.
                """)
            }
            
            return url
        }
    }
    
    /// An enum containing all possible states of the ``LLMLocalDownloadManager``.
    public enum DownloadState: Equatable {
        case idle
        case downloading(progress: Double)
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
    
    /// The delegate handling the download manager tasks.
    @ObservationIgnored private var downloadDelegate: LLMLocalDownloadManagerDelegate?  // swiftlint:disable:this weak_delegate
    /// The `URLSessionDownloadTask` that handles the download of the model.
    @ObservationIgnored private var downloadTask: URLSessionDownloadTask?
    /// Remote `URL` from where the LLM file should be downloaded.
    private let llmDownloadUrl: URL
    /// Local `URL` where the downloaded model is stored.
    let llmStorageUrl: URL
    /// Indicates the current state of the ``LLMLocalDownloadManager``.
    @MainActor public var state: DownloadState = .idle
    
    
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
    
    /// Cancels the download of a specified model via a `URLSessionDownloadTask`.
    public func cancelDownload() {
        downloadTask?.cancel()
    }
}
