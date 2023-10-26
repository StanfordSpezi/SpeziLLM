//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import BackgroundAssets


final class LocalLLMDownloadManager: NSObject, ObservableObject, Sendable, URLSessionDownloadDelegate {
    enum DownloadState: Equatable {
        case idle
        case downloading(progress: Double)
        case downloaded
        case error(Error)
        
        
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
    
    
    @MainActor @Published var state: DownloadState = .idle
    
    
    func startDownload(url: URL) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
        Task { @MainActor in
            self.state = .downloading(progress: progress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            _ = try FileManager.default.replaceItemAt(.applicationDirectory.appending(path: "llm.gguf"), withItemAt: location)
        } catch {
            print(String(describing: error))
            return
        }
        
        Task { @MainActor in
            self.state = .downloaded
        }
    }
}
