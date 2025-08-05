//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SpeziViews
import SwiftUI


/// Informs users about the required local network access of ``SpeziLLMFog`` and provides a button to start the request for authorization.
///
/// The view displays information to users why ``SpeziLLMFog`` requires local network access to dynamically discover fog resources within the network.
/// Upon the click of the "request access" button, ``LLMFogDiscoveryAuthorizationView`` spins up a local network listener and browser checking for OS authorization for the required Bonjour service.
/// In case authorization has not yet been given to the consuming application, the OS prompts the user with a popup asking for local network access.
/// Once authorization is given, users can skip to the next step
///
/// ### Info
///
/// The local network authorization dance with the ``LLMFogDiscoveryAuthorizationView`` is only required from iOS 18 / macOS 15 onwards.
/// Previously, the OS immediately granted access to common Bonjour service types, such as the ones we're using in ``SpeziLLMFog``.
///
/// ### Usage
///
/// An example usage of the ``LLMFogDiscoveryAuthorizationView`` within an onboarding flow managed by `SpeziOnboarding` can be seen below.
///
/// ```swift
/// // Example onboarding flow of `SpeziLLMFog`
/// struct LLMFogOnboardingFlow: View {
///     @AppStorage(StorageKeys.fogOnboardingFlowComplete) private var completedOnboardingFlow = false
///
///
///     var body: some View {
///         OnboardingStack(onboardingFlowComplete: $completedOnboardingFlow) {
///             // Request authorization for local network access
///             LLMFogOnboardingDiscoveryAuthorizationView()
///         }
///             .interactiveDismissDisabled(!completedOnboardingFlow)
///     }
/// }
///
/// // Onboarding view for authorizing local network access
/// struct LLMFogOnboardingDiscoveryAuthorizationView: View {
///     @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
///
///
///     var body: some View {
///         // Usage of the SpeziLLMFog `LLMFogDiscoveryAuthorizationView`
///         LLMFogDiscoveryAuthorizationView {
///             onboardingNavigationPath.nextStep()
///         }
///     }
/// }
/// ```
public struct LLMFogDiscoveryAuthorizationView: View {
    @Environment(LLMFogPlatform.self) var fogPlatform

    /// The action that should be performed when pressing the primary button of the view.
    private let action: () async throws -> Void

    /// Indicates if the authorization has been granted.
    @State private var authorizationGranted = false
    /// The current state of the view, can show an error.
    @State private var viewState: ViewState = .idle


    public var body: some View {
        OnboardingView(
            header: {
                OnboardingTitleView(
                    title: .init("FOG_DISCOVERY_AUTH_TITLE", bundle: .atURL(from: .module)),
                    subtitle: .init("FOG_DISCOVERY_AUTH_SUBTITLE", bundle: .atURL(from: .module))
                )
            },
            content: {
                VStack {
                    informationView
                    
                    if !authorizationGranted {
                        requestAuthButton
                    } else {
                        Text("FOG_DISCOVERY_AUTH_GRANTED_DESCRIPTION", bundle: .module)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .bold()
                            .italic()
                    }
                    
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: self.viewState == .processing)
            }, footer: {
                OnboardingActionsView(.init("FOG_DISCOVERY_AUTH_GRANTED_NEXT_BUTTON", bundle: .atURL(from: .module))) {
                    try await self.action()
                }
                    .disabled(!self.authorizationGranted)
            }
        )
            .viewStateAlert(state: $viewState)
    }

    /// Presents information about the authorization of local network access.
    @ViewBuilder private var informationView: some View {
        Image(systemName: "network")
            .font(.system(size: 130))
            .foregroundColor(.accentColor)
            .accessibilityHidden(true)
        Text("FOG_DISCOVERY_REQUEST_AUTH_INFO", bundle: .module)
            .multilineTextAlignment(.center)
            .padding(.vertical, 16)
    }

    /// Button which requests the authorization to access the local network.
    @ViewBuilder private var requestAuthButton: some View {
        AsyncButton(state: $viewState) {
            // authorization check only works on real devices, stubbing behavior on simulator
            #if targetEnvironment(simulator)
            self.authorizationGranted = true
            return
            #endif

            let authGranted: Bool

            do {
                authGranted = try await self.requestLocalNetworkAuthorization()
            } catch {
                throw LLMFogDiscoveryAuthorizationError.authorizationFailed
            }
            
            if authGranted {
                self.authorizationGranted = true
            } else {
                throw LLMFogDiscoveryAuthorizationError.authorizationDenied
            }
        } label: {
            Text("FOG_DISCOVERY_REQUEST_AUTH_BUTTON", bundle: .module)
                .padding(.horizontal)
                .padding(.vertical, 6)
        }
            .buttonStyle(.borderedProminent)
            .padding()
    }


    /// Creates a ``LLMFogDiscoveryAuthorizationView`` that presents an onboarding view enabling users to grant permission
    /// to access the local network and discover fog resources in it.
    ///
    /// - Parameters:
    ///   - action: The action that should be performed when pressing the primary button of the view.
    public init(action: @escaping () async throws -> Void) {
        self.action = action
    }
}


#if DEBUG
#Preview {
    LLMFogDiscoveryAuthorizationView(
        action: {}
    )
        .previewWith {
            LLMFogPlatform(configuration: .init(connectionType: .http, authToken: .none))
        }
}
#endif
