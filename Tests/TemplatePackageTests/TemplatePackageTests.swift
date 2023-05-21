//
// This source file is part of the TemplatePackage open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import TemplatePackage
import XCTest


final class TemplatePackageTests: XCTestCase {
    func testTemplatePackage() throws {
        let templatePackage = TemplatePackage()
        XCTAssertEqual(templatePackage.stanford, "Stanford University")
    }
}
