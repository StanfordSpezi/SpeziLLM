//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension LocalizedStringResource.BundleDescription {
    /// Convenience method to create a `BundleDescription.atURL()` from a given Bundle instance.
    /// - Parameter bundle: The Bundle instance to retrieve the Bundle URL from.
    public static func atURL(from bundle: Bundle) -> LocalizedStringResource.BundleDescription {
        .atURL(bundle.bundleURL)
    }
}
