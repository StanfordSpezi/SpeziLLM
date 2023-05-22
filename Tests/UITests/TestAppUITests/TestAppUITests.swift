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
    
    
    func testSpeziMLOnboarding() throws {
        let app = XCUIApplication()
        
        
        let elementsQuery = XCUIApplication().scrollViews.otherElements
        elementsQuery.staticTexts["User Message!"].tap()
        elementsQuery.staticTexts["Assistant Message!"].tap()
        
        
        app.buttons["Onboarding"].tap()
        
        try app.textFields["OpenAI API Key"].enter(value: "New Token")
        app.buttons["Next"].tap()
        
        app.pickers["modelPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "GPT 4")
        XCTAssert(app.pickerWheels["GPT 4"].waitForExistence(timeout: 2))
        
        app.buttons["Next"].tap()
        XCTAssert(app.textFields["New Token"].waitForExistence(timeout: 2))
        
        app.terminate()
        app.launch()
        
        app.buttons["Onboarding"].tap()
        
        XCTAssert(app.textFields["New Token"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        XCTAssert(app.pickerWheels["GPT 4"].waitForExistence(timeout: 2))
        
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        app.buttons["Onboarding"].tap()
        
        XCTAssert(app.textFields["OpenAI API Key"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        XCTAssert(app.pickerWheels["GPT 3.5 Turbo"].waitForExistence(timeout: 2))
    }
    
    func testSpeziMLChat() throws {
        let app = XCUIApplication()
        
        XCTAssert(app.staticTexts["User Message!"].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["Assistant Message!"].waitForExistence(timeout: 2))
                
        app.textFields["Ask LLM on FHIR ..."].tap()
        typeText("New Message!")
        app.buttons["Arrow Up Circle"].tap()
                
        XCTAssert(app.staticTexts["New Message!"].waitForExistence(timeout: 2))
    }
}
