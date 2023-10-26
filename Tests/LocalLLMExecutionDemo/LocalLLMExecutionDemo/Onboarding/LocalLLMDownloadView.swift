//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import SpeziOnboarding
import SpeziViews


struct LocalLLMDownloadView: View {
    enum Defaults {
        static var Llama2ChatModelUrl: URL {
            // Regular LLama (~3.5GB)
            URL(string: "https://huggingface.co/TheBloke/Llama-2-7b-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_0.gguf")!
        }
        
        // Tiny LLama2 (~700MB)
        static var TinyLLama2ModelUrl: URL {
            URL(string: "https://huggingface.co/TheBloke/Tinyllama-2-1b-miniguanaco-GGUF/resolve/main/tinyllama-2-1b-miniguanaco.Q4_0.gguf")!
        }
    }
    
    
    @EnvironmentObject private var onboardingNavigationPath: OnboardingNavigationPath
    @StateObject var downloadManager = LocalLLMDownloadManager()
    @State private var isButtonDisabled = false
    
    
    var body: some View {
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
                    
                    if !modelAlreadyExists {
                        Button("LLM_DOWNLOAD_BUTTON") {
                            isButtonDisabled = true
                            Task {
                                withAnimation {
                                    downloadManager.startDownload(url: Defaults.TinyLLama2ModelUrl)
                                }
                            }
                        }
                            .buttonStyle(.borderedProminent)
                            .disabled(isButtonDisabled)
                            .padding()
                        
                        if isDownloading {
                            VStack {
                                ProgressView("Downloading...", value: downloadProgress, total: 100)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .padding()
                                
                                Text("Downloaded \(String(format: "%.2f", downloadProgress))% of 100%")
                                    .padding(.top, 5)
                            }
                                .transition(.opacity)
                                .animation(.easeInOut, value: isDownloading)
                        }
                    } else {
                        Text("LLM_ALREADY_DOWNLOAD_DESCRIPTION")
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .padding(.top, 16)
                            .bold()
                            .italic()
                    }
                    
                    
                    Spacer()
                }
            }, actionView: {
                OnboardingActionsView("LLM_DOWNLOAD_NEXT_BUTTON") {
                    onboardingNavigationPath.nextStep()
                }
                    .disabled(downloadManager.state != .downloaded || modelAlreadyExists)
            }
        )
            .navigationBarBackButtonHidden(isDownloading)
    }
    
    private var isDownloading: Bool {
        if case .downloading(_) = self.downloadManager.state {
            return true
        }
        
        return false
    }
    
    private var downloadProgress: Double {
        if case .downloading(let progress) = self.downloadManager.state {
            return progress
        } else if case .downloaded = self.downloadManager.state {
            return 100.0
        }
        
        return 0.0
    }
    
    private var modelAlreadyExists: Bool {
        FileManager.default.fileExists(atPath: URL.applicationDirectory.appending(path: "llm.gguf").path())
    }
}


#Preview {
    OnboardingStack {
        LocalLLMDownloadView()
    }
}
