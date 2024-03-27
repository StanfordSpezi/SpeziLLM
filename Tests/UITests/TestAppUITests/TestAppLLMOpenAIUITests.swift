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
        app.launchArguments = ["--mockMode", "--resetSecureStorage", "--testMode"]
        #if !os(macOS)
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        #else
        app.launch()
        #endif
    }
    
    
    func testSpeziLLMOpenAIOnboarding() throws {    // swiftlint:disable:this function_body_length
        let app = XCUIApplication()
        
        XCTAssert(app.buttons["LLMOpenAI"].waitForExistence(timeout: 2))
        app.buttons["LLMOpenAI"].tap()
        
        XCTAssert(app.buttons["Onboarding"].firstMatch.waitForExistence(timeout: 2))
        app.buttons["Onboarding"].firstMatch.tap()
        
        try app.textFields["OpenAI API Key"].enter(value: "New Token")
        sleep(1)
        
        XCTAssert(app.buttons["Next"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        
        #if os(macOS)
        XCTAssert(app.popUpButtons["modelPicker"].waitForExistence(timeout: 2))
        app.popUpButtons["modelPicker"].tap()
        XCTAssert(app.menuItems["GPT 4 Turbo Preview"].waitForExistence(timeout: 2))
        app.menuItems["GPT 4 Turbo Preview"].tap()
        XCTAssert(app.popUpButtons["GPT 4 Turbo Preview"].waitForExistence(timeout: 2))
        #elseif os(visionOS)
        app.pickers["modelPicker"].pickerWheels.element(boundBy: 0).swipeUp()
        XCTAssert(app.pickerWheels["GPT 4 Turbo Preview"].waitForExistence(timeout: 2))
        #else
        app.pickers["modelPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "GPT 4 Turbo Preview")
        XCTAssert(app.pickerWheels["GPT 4 Turbo Preview"].waitForExistence(timeout: 2))
        #endif
        
        sleep(1)
        
        XCTAssert(app.buttons["Next"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        
        #if !os(macOS)
        let alert = app.alerts["Model Selected"]
        
        XCTAssertTrue(alert.waitForExistence(timeout: 2), "The `Model Selected` alert did not appear.")
        XCTAssertTrue(alert.staticTexts["gpt-4-turbo-preview"].exists, "The correct model was not registered.")
        
        let okButton = alert.buttons["OK"]
        XCTAssertTrue(okButton.exists, "The OK button on the alert was not found.")
        okButton.tap()
        #else
        XCTAssertTrue(app.staticTexts["Model Selected"].waitForExistence(timeout: 2), "The `Model Selected` alert did not appear.")
        XCTAssertTrue(app.staticTexts["gpt-4-turbo-preview"].exists, "The correct model was not registered.")
        XCTAssert(app.buttons["OK"].firstMatch.waitForExistence(timeout: 2))
        app.buttons["OK"].firstMatch.tap()
        #endif
        
        XCTAssert(app.textFields["New Token"].waitForExistence(timeout: 2))
        
        app.terminate()
        app.launch()
        
        XCTAssert(app.buttons["LLMOpenAI"].waitForExistence(timeout: 2))
        app.buttons["LLMOpenAI"].tap()
        
        XCTAssert(app.buttons["Onboarding"].waitForExistence(timeout: 2))
        app.buttons["Onboarding"].firstMatch.tap()
        
        XCTAssert(app.textFields["New Token"].waitForExistence(timeout: 2))
        sleep(1)
        app.buttons["Next"].tap()
        
        #if !os(macOS)
        XCTAssert(app.pickerWheels["GPT 3.5 Turbo"].waitForExistence(timeout: 2))
        #else
        XCTAssert(app.popUpButtons["GPT 3.5 Turbo"].waitForExistence(timeout: 2))
        #endif
        app.buttons["Next"].tap()
        
        #if !os(macOS)
        let alert2 = app.alerts["Model Selected"]

        XCTAssertTrue(alert2.waitForExistence(timeout: 2), "The `Model Selected` alert did not appear.")
        XCTAssertTrue(alert2.staticTexts["gpt-3.5-turbo"].exists, "The correct model was not registered.")

        let okButton2 = alert.buttons["OK"]
        XCTAssertTrue(okButton2.exists, "The OK button on the alert was not found.")
        okButton.tap()
        #else
        XCTAssertTrue(app.staticTexts["Model Selected"].waitForExistence(timeout: 2), "The `Model Selected` alert did not appear.")
        XCTAssertTrue(app.staticTexts["gpt-3.5-turbo"].exists, "The correct model was not registered.")
        XCTAssert(app.buttons["OK"].firstMatch.waitForExistence(timeout: 2))
        app.buttons["OK"].firstMatch.tap()
        #endif
        
        #if !os(macOS)
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
        #else
        app.terminate()
        app.launch()
        #endif
        
        XCTAssert(app.buttons["LLMOpenAI"].waitForExistence(timeout: 2))
        app.buttons["LLMOpenAI"].tap()
        
        app.buttons["Onboarding"].firstMatch.tap()
        
        XCTAssert(app.textFields["OpenAI API Key"].waitForExistence(timeout: 2))
        
        XCTAssert(app.buttons["Next"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        
        #if !os(macOS)
        XCTAssert(app.pickerWheels["GPT 3.5 Turbo"].waitForExistence(timeout: 2))
        #else
        XCTAssert(app.popUpButtons["GPT 3.5 Turbo"].waitForExistence(timeout: 2))
        #endif
    }
    
    func testSpeziLLMOpenAIChat() throws {
        let app = XCUIApplication()
        
        XCTAssert(app.buttons["LLMOpenAI"].waitForExistence(timeout: 2))
        app.buttons["LLMOpenAI"].tap()
        
        XCTAssert(app.buttons["Record Message"].waitForExistence(timeout: 2))
        
        XCTAssertFalse(app.staticTexts["You're a helpful assistant that answers questions from users."].waitForExistence(timeout: 2))
        
        XCTAssert(app.buttons["Record Message"].isEnabled)
        
        #if !os(macOS)
        try app.textViews["Message Input Textfield"].enter(value: "New Message!", dismissKeyboard: false)
        #else
        try app.textFields["Message Input Textfield"].enter(value: "New Message!", dismissKeyboard: false)
        #endif
        
        XCTAssert(app.buttons["Send Message"].waitForExistence(timeout: 2))
        app.buttons["Send Message"].tap()
        
        sleep(3)
        
        XCTAssert(app.staticTexts["Mock Message from SpeziLLM!"].waitForExistence(timeout: 5))
    }
}
