//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

#if os(iOS)
import SpeziAccount
import SwiftUI


struct AccountSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @Environment(Account.self) private var account
    @Environment(\.accountRequired) var accountRequired
    
    @State var isInSetup = false
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                if account.signedIn && !isInSetup {
                    AccountOverview(close: .showCloseButton)
                } else {
                    AccountSetup { _ in
                        dismiss() // we just signed in, dismiss the account setup sheet
                    } header: {
                        AccountSetupHeader()
                    }
                }
            }
        }
    }
}
#endif
