//
// This source file is part of the TemplatePackage open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import TemplatePackage


@main
struct UITestsApp: App {
    var body: some Scene {
        WindowGroup {
            Text(TemplatePackage().stanford)
        }
    }
}
