//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SpeziViews
import SwiftUI


/// Onboarding LLM Download view
public struct LLMLocalDownloadView: View {
    @StateObject private var downloadManager: LLMLocalDownloadManager
    private let action: () async throws -> Void
    

    public var body: some View {
        OnboardingView(
            contentView: {
                VStack {
                    OnboardingTitleView(
                        title: .init("LLM_DOWNLOAD_TITLE", bundle: .atURL(from: .module)),
                        subtitle: .init("LLM_DOWNLOAD_SUBTITLE", bundle: .atURL(from: .module))
                    )
                    Spacer()
                    Image(systemName: "shippingbox")
                        .font(.system(size: 100))
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                    Text("LLM_DOWNLOAD_DESCRIPTION", bundle: .module)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                    
                    if !modelExists {
                        downloadButton
                        
                        if isDownloading {
                            downloadProgressView
                        }
                    } else {
                        Group {
                            if downloadManager.state != .downloaded {
                                Text("LLM_ALREADY_DOWNLOADED_DESCRIPTION", bundle: .module)
                            } else if downloadManager.state == .downloaded {
                                Text("LLM_DOWNLOADED_DESCRIPTION", bundle: .module)
                            }
                        }
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .bold()
                            .italic()
                    }
                    
                    Spacer()
                }
                    .transition(.opacity)
                    .animation(.easeInOut, value: isDownloading || modelExists)
            }, actionView: {
                OnboardingActionsView(.init("LLM_DOWNLOAD_NEXT_BUTTON", bundle: .atURL(from: .module))) {
                    try await self.action()
                }
                    .disabled(!modelExists)
            }
        )
            .navigationBarBackButtonHidden(isDownloading)
    }
    
    private var downloadButton: some View {
        Button(action: downloadManager.startDownload) {
            Text("LLM_DOWNLOAD_BUTTON", bundle: .module)
                .padding(.horizontal)
                .padding(.vertical, 6)
        }
            .buttonStyle(.borderedProminent)
            .disabled(isDownloading)
            .padding()
    }
    
    private var downloadProgressView: some View {
        VStack {
            ProgressView(value: downloadProgress, total: 100.0) {
                Text("LLM_DOWNLOADING_PROGRESS_TEXT", bundle: .module)
            }
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
            
            Text("Downloaded \(String(format: "%.2f", downloadProgress))% of 100%.", bundle: .module)
                .padding(.top, 5)
        }
    }
    
    /// A `Bool` flag indicating if the model is currently being downloaded
    private var isDownloading: Bool {
        if case .downloading = self.downloadManager.state {
            return true
        }
        
        return false
    }
    
    /// Represents the download progress of the model in percent (from 0 to 100)
    private var downloadProgress: Double {
        if case .downloading(let progress) = self.downloadManager.state {
            return progress
        } else if case .downloaded = self.downloadManager.state {
            return 100.0
        }
        
        return 0.0
    }
    
    /// A `Bool` flag indicating if the model already exists on the device
    private var modelExists: Bool {
        FileManager.default.fileExists(
            atPath: self.downloadManager.llmStorageUrl.path()
        )
    }
    
    
    /// Creates a ``LLMLocalDownloadView`` that presents an onboarding view that helps with downloading the necessary LLM files from remote servers.
    ///
    /// - Parameters:
    ///   - llmDownloadUrl: The remote `URL` from where the LLM file should be downloaded.
    ///   - llmDownloadLocation: The local `URL` where the LLM file should be stored.
    ///   - action: The action that should be performed when pressing the primary button of the view.
    public init(
        llmDownloadUrl: URL = LLMLocalDownloadManager.LLMUrlDefaults.llama2ChatModelUrl,
        llmStorageUrl: URL = .cachesDirectory.appending(path: "llm.gguf"),
        action: @escaping () async throws -> Void
    ) {
        self._downloadManager = StateObject(
            wrappedValue: LLMLocalDownloadManager(
                llmDownloadUrl: llmDownloadUrl,
                llmStorageUrl: llmStorageUrl
            )
        )
        self.action = action
    }
}


#Preview {
    LLMLocalDownloadView(action: {})
}
