//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions


class TestAppLLMOpenAIUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--mockMode", "--resetKeychain"]
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
    }
    
    
    func testSpeziLLMOpenAIOnboarding() throws {
        let app = XCUIApplication()
        
        XCTAssert(app.buttons["LLMOpenAI"].waitForExistence(timeout: 2))
        app.buttons["LLMOpenAI"].tap()
        
        app.buttons["Onboarding"].tap()
        
        try app.textFields["OpenAI API Key"].enter(value: "New Token")
        sleep(1)
        
        XCTAssert(app.buttons["Next"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        
        app.pickers["modelPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "GPT 4 Turbo Preview")
        XCTAssert(app.pickerWheels["GPT 4 Turbo Preview"].waitForExistence(timeout: 2))
        sleep(1)
        
        XCTAssert(app.buttons["Next"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        
        let alert = app.alerts["Model Selected"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2), "The `Model Selected` alert did not appear.")
        XCTAssertTrue(alert.staticTexts["gpt-4-turbo-preview"].exists, "The correct model was not registered.")
        
        let okButton = alert.buttons["OK"]
        XCTAssertTrue(okButton.exists, "The OK button on the alert was not found.")
        okButton.tap()
        
        XCTAssert(app.textFields["New Token"].waitForExistence(timeout: 2))
        
        app.terminate()
        app.launch()
        
        XCTAssert(app.buttons["LLMOpenAI"].waitForExistence(timeout: 2))
        app.buttons["LLMOpenAI"].tap()
        
        XCTAssert(app.buttons["Onboarding"].waitForExistence(timeout: 2))
        app.buttons["Onboarding"].tap()
        
        XCTAssert(app.textFields["New Token"].waitForExistence(timeout: 2))
        sleep(1)
        app.buttons["Next"].tap()
        
        XCTAssert(app.pickerWheels["GPT 3.5 Turbo"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        
        let alert2 = app.alerts["Model Selected"]
        XCTAssertTrue(alert2.waitForExistence(timeout: 2), "The `Model Selected` alert did not appear.")
        XCTAssertTrue(alert2.staticTexts["gpt-3.5-turbo"].exists, "The alert message is not correct.")
        
        let okButton2 = alert2.buttons["OK"]
        XCTAssertTrue(okButton2.exists, "The OK button on the alert was not found.")
        okButton2.tap()
        
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        
        XCTAssert(app.buttons["LLMOpenAI"].waitForExistence(timeout: 2))
        app.buttons["LLMOpenAI"].tap()
        
        app.buttons["Onboarding"].tap()
        
        XCTAssert(app.textFields["OpenAI API Key"].waitForExistence(timeout: 2))
        
        XCTAssert(app.buttons["Next"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        
        XCTAssert(app.pickerWheels["GPT 3.5 Turbo"].waitForExistence(timeout: 2))
    }
    
    func testSpeziLLMOpenAIChat() throws {
        let app = XCUIApplication()
        
        XCTAssert(app.buttons["LLMOpenAI"].waitForExistence(timeout: 2))
        app.buttons["LLMOpenAI"].tap()
        
        XCTAssert(app.buttons["Record Message"].waitForExistence(timeout: 2))
        
        XCTAssertFalse(app.staticTexts["You're a helpful assistant that answers questions from users."].waitForExistence(timeout: 2))
        
        XCTAssert(app.buttons["Record Message"].isEnabled)
        
        try app.textViews["Message Input Textfield"].enter(value: "New Message!", dismissKeyboard: false)
        
        XCTAssert(app.buttons["Send Message"].waitForExistence(timeout: 2))
        app.buttons["Send Message"].tap()
        
        sleep(3)
        
        XCTAssert(app.staticTexts["Mock Message from SpeziLLM!"].waitForExistence(timeout: 5))
    }
}
