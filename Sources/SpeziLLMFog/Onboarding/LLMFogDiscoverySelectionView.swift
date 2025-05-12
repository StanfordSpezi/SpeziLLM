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


/// Enables users to select a preferred fog service to use.
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
            contentView: {
                VStack(alignment: .leading, spacing: 16) {
                    Text("FOG_DISCOVERY_SELECT_TITLE", bundle: .module)
                        .font(.title2).bold()
                    Text("FOG_DISCOVERY_SELECT_SUBTITLE", bundle: .module)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    List(discoveredServices, id: \.endpoint) { service in
                        serviceRow(service)
                            .padding(.vertical, 6)
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 300)
                }
                .padding()
                .task {
                    await discoverFogServices()
                }
                .sheet(isPresented: $isShowingInfo) {
                    if let infoService {
                        ServiceDetailView(service: infoService)
                    }
                }
            },
            actionView: {
                AsyncButton(state: $viewState) {
                    guard let service = selectedService else {
                        fatalError("Inconsistent `LLMFogDiscoverySelectionView` state")
                    }
                    
                    self.fogPlatform.preferredFogService = service      // set preferred service on the `LLMFogPlatform`
                    try await action(service)
                } label: {
                    Text("FOG_DISCOVERY_SELECT_NEXT_BUTTON", bundle: .module)
                        .frame(maxWidth: .infinity)
                }
                .disabled(selectedService == nil)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
        )
        .viewStateAlert(state: $viewState)
    }


    public init(action: @escaping (NWBrowser.Result) async throws -> Void) {
        self.action = action
    }


    @ViewBuilder
    private func serviceRow(_ service: NWBrowser.Result) -> some View {     // swiftlint:disable:this function_body_length
        HStack {    // swiftlint:disable:this closure_body_length
            VStack(alignment: .leading, spacing: 4) {   // swiftlint:disable:this closure_body_length
                // Endpoint info
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

                // Metadata preview (up to two entries)
                switch service.metadata {
                case .bonjour(let txt):
                    if txt.dictionary.isEmpty {
                        Text("No TXT records")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(txt.dictionary.sorted(by: { $0.key < $1.key }).prefix(2)), id: \.key) { key, value in
                            HStack(spacing: 4) {
                                Text(key)
                                    .font(.caption2)
                                    .bold()
                                Text(value)
                                    .font(.caption2)
                            }
                        }
                    }
                case .none:
                    Text("No metadata")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                @unknown default:
                    fatalError("Unknown Service metadata")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedService = service
            }

            Spacer()

            if selectedService == service {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .accessibilityLabel(Text("Selected service"))
            }

            Button(action: {
                infoService = service
                isShowingInfo = true
            }) {
                Image(systemName: "info.circle")
                    .accessibilityLabel(Text("More information about service"))
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
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
            viewState = .error(AnyLocalizedError(error: error))     // todo: better error
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
