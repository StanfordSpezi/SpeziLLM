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


/// The ``LLMLocalDownloadView`` provides an out-of-the-box onboarding view for downloading locally executed Spezi `LLM`s to the device.
/// It can be combined with the SpeziOnboarding `OnboardingStack` to create an easy onboarding flow within the application.
///
/// The ``LLMLocalDownloadView/init(llmDownloadUrl:llmStorageUrl:action:)`` initializer accepts the remote download `URL` of the LLM, the local storage `URL` of the downloaded model, as well as an action closure to move onto the next (onboarding) step.
///
/// The heavy lifting of downloading and storing the model is done by the ``LLMLocalDownloadManager`` which exposes the current downloading state view the ``LLMLocalDownloadManager/state`` property of type ``LLMLocalDownloadManager/DownloadState``.
///
/// ### Usage
///
/// ```swift
/// struct LLMLocalDownloadApp: View {
///     @State private var path = NavigationPath()
///
///     var body: some View {
///         NavigationStack(path: $path) {
///             LLMLocalOnboardingDownloadView()
///         }
///     }
/// }
///
/// struct LLMLocalOnboardingDownloadView: View {
///     @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
///
///     var body: some View {
///         LLMLocalDownloadView(
///             llmDownloadUrl: LLMLocalDownloadManager.LLMUrlDefaults.llama2ChatModelUrl, // Download the Llama2 7B model
///             llmStorageUrl: .cachesDirectory.appending(path: "llm.gguf") // Store the downloaded LLM in the caches directory
///         ) {
///             onboardingNavigationPath.nextStep()
///         }
///     }
/// }
/// ```
public struct LLMLocalDownloadView: View {
    /// The ``LLMLocalDownloadManager`` manages the download and storage of the models.
    @State private var downloadManager: LLMLocalDownloadManager
    /// The action that should be performed when pressing the primary button of the view.
    private let action: () async throws -> Void
    
    /// Indicates the state of the view, get's derived from the ``LLMLocalDownloadManager/state``.
    @State private var viewState: ViewState = .idle

    
    public var body: some View {
        OnboardingView(
            contentView: {
                VStack {
                    informationView
                    
                    if !modelExists {
                        downloadButton
                        
                        if isDownloading {
                            downloadProgressView
                        }
                    } else {
                        Group {
                            switch downloadManager.state {
                            case .downloaded:
                                Text("LLM_DOWNLOADED_DESCRIPTION", bundle: .module)
                            default:
                                Text("LLM_ALREADY_DOWNLOADED_DESCRIPTION", bundle: .module)
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
            .map(state: downloadManager.state, to: $viewState)
            .viewStateAlert(state: $viewState)
            .navigationBarBackButtonHidden(isDownloading)
    }
    
    /// Presents information about the model download.
    @MainActor @ViewBuilder private var informationView: some View {
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
    }
    
    /// Button which starts the download of the model.
    @MainActor private var downloadButton: some View {
        Button(action: downloadManager.startDownload) {
            Text("LLM_DOWNLOAD_BUTTON", bundle: .module)
                .padding(.horizontal)
                .padding(.vertical, 6)
        }
            .buttonStyle(.borderedProminent)
            .disabled(isDownloading)
            .padding()
    }
    
    /// A progress view indicating the state of the download
    @MainActor private var downloadProgressView: some View {
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
    @MainActor private var isDownloading: Bool {
        if case .downloading = self.downloadManager.state {
            return true
        }
        
        return false
    }
    
    /// Represents the download progress of the model in percent (from 0 to 100)
    @MainActor private var downloadProgress: Double {
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
        self._downloadManager = State(
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
