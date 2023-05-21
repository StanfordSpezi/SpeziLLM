//
// This source file is part of the SpeziML open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions


class TestAppUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
    }
    
    
    func testSpeziML() throws {
        let app = XCUIApplication()
        
        XCTAssert(app.staticTexts["Your token is: "].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["Your choice of model is: gpt-3.5-turbo"].waitForExistence(timeout: 2))
        
        app.buttons["Test Token Change"].tap()
        XCTAssert(app.staticTexts["Your token is: New Token"].waitForExistence(timeout: 2))
        
        app.buttons["Test Model Change"].tap()
        XCTAssert(app.staticTexts["Your choice of model is: gpt-4"].waitForExistence(timeout: 2))
        
        app.terminate()
        app.launch()
        
        XCTAssert(app.staticTexts["Your token is: New Token"].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["Your choice of model is: gpt-4"].waitForExistence(timeout: 2))
        
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        XCTAssert(app.staticTexts["Your token is: New Token"].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["Your choice of model is: gpt-3.5-turbo"].waitForExistence(timeout: 2))
    }
}
