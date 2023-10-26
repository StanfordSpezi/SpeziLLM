//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Manages the download of the LLM to the local device.
final class LocalLLMDownloadManager: NSObject, ObservableObject, Sendable, URLSessionDownloadDelegate {
    /// An enum containing all possible states of the ``LocalLLMDownloadManager``.
    enum DownloadState: Equatable {
        case idle
        case downloading(progress: Double)
        case downloaded
        case error(Error?)
        
        
        static func == (lhs: LocalLLMDownloadManager.DownloadState, rhs: LocalLLMDownloadManager.DownloadState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): true
            case (.downloading, .downloading): true
            case (.downloaded, .downloaded): true
            case (.error, .error): true
            default: false
            }
        }
    }
    
    /// `URL` where the downloaded model is stored
    static let downloadModelLocation: URL = .cachesDirectory.appending(path: "llm.gguf")
    /// Indicates the current state of the ``LocalLLMDownloadManager``.
    @MainActor @Published var state: DownloadState = .idle
    
    
    /// Starts a `URLSessionDownloadTask` to download the model.
    func startDownload(url: URL) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    // MARK: URLSessionDownloadDelegate
    /// Indicates the progress of the current model download.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
        Task { @MainActor in
            self.state = .downloading(progress: progress)
        }
    }
    
    /// Indicates the completion of the model download including the downloaded file `URL`.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            _ = try FileManager.default.replaceItemAt(Self.downloadModelLocation, withItemAt: location)
        } catch {
            Task { @MainActor in
                self.state = .error(error)
            }
            print(String(describing: error))
            return
        }
        
        Task { @MainActor in
            self.state = .downloaded
        }
    }
    
    /// Indicates an error during the model download
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            self.state = .error(error)
        }
        print(String(describing: error))
    }
}
