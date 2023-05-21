//
// This source file is part of the TemplatePackage open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


class TestAppUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
    }
    
    
    func testTemplatePackage() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssert(app.staticTexts["Stanford University"].waitForExistence(timeout: 0.1))
    }
}
