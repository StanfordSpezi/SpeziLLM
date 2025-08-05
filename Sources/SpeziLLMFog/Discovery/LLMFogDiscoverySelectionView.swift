//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Network
import SpeziOnboarding
import SpeziViews
import SwiftUI


/// Select a preferred fog service to use.
///
/// The ``LLMFogDiscoverySelectionView`` enables users to discover and select a fog service within the local network.
/// During the `View`s display, the local network is continuously browsed for mDNS services and the result list is displayed to the user.
/// The user then selects a preferred fog resource to use. This resource is set on the ``LLMFogPlatform`` and provided as an action closure argument.
///
/// Users can view details about the individually discovered resources via a detailed info botton.
/// Once the `View` is discarded, the browsing of the local network finishes.
///
/// ### Usage
///
/// An example usage of the ``LLMFogDiscoverySelectionView`` within an onboarding flow can be found below:
///
/// ```swift
/// struct LLMFogDiscoverySelectionOnboardingView: View {
///     @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
///
///     var body: some View {
///         LLMFogDiscoverySelectionView { _ in
///             onboardingNavigationPath.nextStep()
///         }
///     }
/// }
/// ```
public struct LLMFogDiscoverySelectionView: View {
    @Environment(LLMFogPlatform.self) private var fogPlatform

    /// Called when the user taps Next. Passed the selected service result.
    private let action: (NWBrowser.Result) async throws -> Void

    @State private var discoveredServices: [NWBrowser.Result] = []
    @State private var selectedService: NWBrowser.Result?
    @State private var viewState: ViewState = .idle

    // for showing the info sheet
    @State private var infoService: NWBrowser.Result?
    @State private var isShowingInfo = false


    public var body: some View {
        OnboardingView(
            header: {
                OnboardingTitleView(
                    title: .init("FOG_DISCOVERY_SELECT_TITLE", bundle: .atURL(from: .module)),
                    subtitle: .init("FOG_DISCOVERY_SELECT_SUBTITLE", bundle: .atURL(from: .module))
                )
            },
            content: {
                List {
                    Section(
                        header: HStack {
                            Text("Available fog nodes")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            // As long as View is shown, continuously discover fog nodes
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.75, anchor: .center)
                                .accessibilityLabel("Searching for available fog nodes")
                        }
                    ) {
                        ForEach(discoveredServices, id: \.endpoint) { service in
                            self.serviceRow(service)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .task {
                    await discoverFogServices()
                }
                .sheet(item: $infoService) { service in
                    ServiceDetailView(service: service)
                        .id(service.endpoint.debugDescription)
                }
            },
            footer: {
                OnboardingActionsView(.init("FOG_DISCOVERY_SELECT_NEXT_BUTTON", bundle: .atURL(from: .module))) {
                    guard let service = selectedService else {
                        return
                    }

                    self.fogPlatform.preferredFogService = service      // set preferred service on the `LLMFogPlatform`
                    try await action(service)
                }
                    .disabled(self.selectedService == nil)
            }
        )
        .viewStateAlert(state: $viewState)
    }


    public init(action: @escaping (NWBrowser.Result) async throws -> Void) {
        self.action = action
    }


    @ViewBuilder
    private func serviceRow(_ service: NWBrowser.Result) -> some View {     // swiftlint:disable:this function_body_length
        HStack(spacing: 16) {       // swiftlint:disable:this closure_body_length
            VStack(alignment: .leading, spacing: 4) {       // swiftlint:disable:this closure_body_length
                switch service.endpoint {
                case let .service(name, type, domain, _):
                    Text(name)
                        .font(.body)
                        .bold()
                    Text("\(type).\(domain)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                default:
                    Text(service.endpoint.debugDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // metadata preview (up to two entries)
                switch service.metadata {
                case .bonjour(let txt) where !txt.dictionary.isEmpty:
                    ForEach(
                        Array(
                            txt.dictionary
                            .sorted(by: { $0.key < $1.key })
                            .prefix(2)      // limit to two metadata keys in preview
                        ), id: \.key
                    ) { key, value in
                        HStack(spacing: 4) {
                            Text(key)
                                .font(.caption2)
                                .bold()
                            Text(value)
                                .font(.caption2)
                        }
                    }
                default:
                    Text("No metadata")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 0)

            if selectedService == service {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .accessibilityLabel("Selected service")
            }

            Button {
                infoService = service
            } label: {
                Image(systemName: "info.circle")
                    .accessibilityLabel("More information about service")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            // toggle selection
            if selectedService == service {
                selectedService = nil
            } else {
                selectedService = service
            }
        }
    }

    private func discoverFogServices() async {
        let discoverySequence = ServiceDiscoverySequence(
            serviceType: fogPlatform.configuration.connectionType.mDnsServiceType,
            host: fogPlatform.configuration.host
        )

        do {
            for try await snapshot in discoverySequence {
                let sorted = snapshot.sorted { lhs, rhs in
                    let lhsName: String
                    let rhsName: String

                    switch (lhs.endpoint, rhs.endpoint) {
                    case let (.service(nameL, typeL, domainL, _), .service(nameR, typeR, domainR, _)):
                        lhsName = nameL + "." + typeL + "." + domainL
                        rhsName = nameR + "." + typeR + "." + domainR
                    default:
                        lhsName = String(describing: lhs.endpoint)
                        rhsName = String(describing: rhs.endpoint)
                    }

                    return lhsName < rhsName
                }

                self.discoveredServices = sorted
            }
        } catch {
            viewState = .error(AnyLocalizedError(error: error))     // only `LLMFogError` thrown here, mapped correctly
        }
    }
}

#if DEBUG
#Preview {
    LLMFogDiscoverySelectionView { _ in }
        .previewWith {
            LLMFogPlatform(configuration: .init(connectionType: .http, authToken: .none))
        }
}
#endif

extension NWBrowser.Result: @retroactive Identifiable {
    public var id: Int { self.hashValue }
}
