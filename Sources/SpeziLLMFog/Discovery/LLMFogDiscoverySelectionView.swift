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
/// Users can view details about the individually discovered resources via a detailed info button.
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
    private enum Completion {
        case required((NWBrowser.Result) async throws -> Void)
        case optional(((NWBrowser.Result?) async throws -> Void))
    }


    @Environment(LLMFogPlatform.self) private var fogPlatform

    /// Called when the user taps Next. Passed the selected service result, or `nil`.
    private let completion: Completion

    @State private var discoveredServices: [NWBrowser.Result] = []
    @State private var selectedService: NWBrowser.Result?
    @State private var viewState: ViewState = .idle

    // for showing the info sheet
    @State private var infoService: NWBrowser.Result?
    @State private var isShowingInfo = false

    private var allowEmptySelection: Bool {
        if case .optional = completion {
            return true
        } else {
            return false
        }
    }


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
                OnboardingActionsView(
                    (self.allowEmptySelection && self.selectedService == nil) ?
                    .init("FOG_DISCOVERY_SELECT_NEXT_BUTTON_ALLOW_EMPTY_SELECTION", bundle: .atURL(from: .module))
                    : .init("FOG_DISCOVERY_SELECT_NEXT_BUTTON", bundle: .atURL(from: .module))
                ) {
                    self.fogPlatform.preferredFogService = self.selectedService      // set preferred service on the `LLMFogPlatform`

                    switch self.completion {
                    case .required(let action):
                        guard let service = self.selectedService else {
                            return
                        }
                        try await action(service)

                    case .optional(let action):
                        try await action(self.selectedService)
                    }
                }
                    .disabled(
                        self.allowEmptySelection ?
                        false
                        : self.selectedService == nil
                    )
            }
        )
        .viewStateAlert(state: $viewState)
    }


    /// Initializes a discovery view where a service **must** be selected.
    ///
    /// - Parameter action: The action closure to call once the "next" button is hit, called with the chosen ``NWBrowser/Result``.
    public init(action: @escaping (NWBrowser.Result) async throws -> Void) {
        self.completion = .required(action)
    }

    /// Initializes a discovery view where selection is **optional**.
    ///
    /// - Parameter action: The action closure to call once the "next" button is hit, called with the chosen ``NWBrowser/Result`` or `nil` if skipped.
    public init(allowingEmptySelection action: @escaping (NWBrowser.Result?) async throws -> Void = { _ in }) {
        self.completion = .optional(action)
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

            if self.selectedService == service {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .accessibilityLabel("Selected service")
            }

            Button {
                self.infoService = service
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
            if self.selectedService == service {
                self.selectedService = nil
            } else {
                self.selectedService = service
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
            self.viewState = .error(AnyLocalizedError(error: error))     // only `LLMFogError` thrown here, mapped correctly
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
