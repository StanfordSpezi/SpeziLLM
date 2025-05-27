//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Network
import SwiftUI


extension LLMFogDiscoverySelectionView {
    /// A simple detail view showing all endpoint fields and the full TXT record.
    struct ServiceDetailView: View {
        let service: NWBrowser.Result
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {   // swiftlint:disable:this closure_body_length
                Form {
                    Section("Service") {
                        switch service.endpoint {
                        case let .service(name, type, domain, interface):
                            Text("Name: \(name)")
                            Text("Type: \(type)")
                            Text("Domain: \(domain)")
                            Text("Interface: \(interface.map(\.debugDescription) ?? "any")")
                        default:
                            Text(service.endpoint.debugDescription)
                        }
                    }

                    Section("Metadata") {
                        switch service.metadata {
                        case .bonjour(let txt) where !txt.dictionary.isEmpty:
                            ForEach(txt.dictionary.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key).bold()
                                    Spacer()
                                    Text(value)
                                }
                            }
                        default:
                            Text("No metadata")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Service Info")
#if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
