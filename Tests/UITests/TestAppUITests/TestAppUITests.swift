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
        
        try app.textFields["OpenAI API Key"].enter(value: "New Token")
        app.buttons["Next"].tap()
        
        app.pickers["modelPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "GPT 4")
        XCTAssert(app.pickerWheels["GPT 4"].waitForExistence(timeout: 2))
        
        app.buttons["Next"].tap()
        XCTAssert(app.textFields["New Token"].waitForExistence(timeout: 2))
        
        app.terminate()
        app.launch()
        
        XCTAssert(app.textFields["New Token"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        XCTAssert(app.pickerWheels["GPT 4"].waitForExistence(timeout: 2))
        
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        XCTAssert(app.textFields["OpenAI API Key"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        XCTAssert(app.pickerWheels["GPT 4"].waitForExistence(timeout: 2))
    }
}
