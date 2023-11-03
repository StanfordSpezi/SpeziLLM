//
// This source file is part of the SpeziML open-source project
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
                        title: "LLM_DOWNLOAD_TITLE",
                        subtitle: "LLM_DOWNLOAD_SUBTITLE"
                    )
                    Spacer()
                    Image(systemName: "shippingbox")
                        .font(.system(size: 100))
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                    Text("LLM_DOWNLOAD_DESCRIPTION")
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                    
                    if !modelExists {
                        downloadButton
                        
                        if isDownloading {
                            downloadProgressView
                        }
                    } else if modelExists && downloadManager.state != .downloaded {
                        Text("LLM_ALREADY_DOWNLOAD_DESCRIPTION")
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .padding(.top, 16)
                            .bold()
                            .italic()
                    }
                    
                    
                    Spacer()
                }
                    .transition(.opacity)
                    .animation(.easeInOut, value: isDownloading || modelExists)
            }, actionView: {
                OnboardingActionsView("LLM_DOWNLOAD_NEXT_BUTTON") {
                    try await self.action()
                }
                    .disabled(!modelExists)
            }
        )
            .navigationBarBackButtonHidden(isDownloading)
    }
    
    private var downloadButton: some View {
        Button("LLM_DOWNLOAD_BUTTON") {
            Task {
                withAnimation {
                    downloadManager.startDownload()
                }
            }
        }
            .buttonStyle(.borderedProminent)
            .disabled(isDownloading)
            .padding()
    }
    
    private var downloadProgressView: some View {
        VStack {
            ProgressView("LLM_DOWNLOADING_PROGRESS_TEXT", value: downloadProgress, total: 100.0)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
            
            Group {
                Text("LLM_DOWNLOADING_PROGRESS_STATE_START") + Text(" \(String(format: "%.2f", downloadProgress))") + Text("LLM_DOWNLOADING_PROGRESS_STATE_END")
            }
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
        llmDownloadUrl: URL = LLMLocalDownloadManager.LLMUrlsDefaults.Llama2ChatModelUrl,
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
    OnboardingStack {
        LLMLocalDownloadView(action: {})
    }
}
