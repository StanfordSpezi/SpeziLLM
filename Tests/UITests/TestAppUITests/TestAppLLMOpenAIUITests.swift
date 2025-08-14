//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions


@MainActor
class TestAppLLMOpenAIUITests: XCTestCase {
    override func setUp() async throws {
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
        
        #if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .pad {
            throw XCTSkip("Skipped on iPad, see: https://github.com/StanfordBDHG/XCTestExtensions/issues/27")
        }
        #endif
        
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
        XCTAssert(app.menuItems["gpt-4o"].waitForExistence(timeout: 2))
        app.menuItems["gpt-4o"].tap()
        XCTAssert(app.popUpButtons["gpt-4o"].waitForExistence(timeout: 2))
        #elseif os(visionOS)
        app.pickers["modelPicker"].pickerWheels.element(boundBy: 0).swipeUp()
        XCTAssert(app.pickerWheels["o1-mini"].waitForExistence(timeout: 2))     // swipe down to the o1-mini model
        #else
        app.pickers["modelPicker"].pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "gpt-4o")
        XCTAssert(app.pickerWheels["gpt-4o"].waitForExistence(timeout: 2))
        #endif
        
        sleep(1)
        
        XCTAssert(app.buttons["Next"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        
        #if !os(macOS)
        let alert = app.alerts["Model Selected"]
        
        XCTAssertTrue(alert.waitForExistence(timeout: 2), "The `Model Selected` alert did not appear.")
        #if os(visionOS)
        XCTAssertTrue(alert.staticTexts["o1-mini"].exists, "The correct model was not registered.")
        #else
        XCTAssertTrue(alert.staticTexts["gpt-4o"].exists, "The correct model was not registered.")
        #endif

        let okButton = alert.buttons["OK"]
        XCTAssertTrue(okButton.exists, "The OK button on the alert was not found.")
        okButton.tap()
        #else
        XCTAssertTrue(app.staticTexts["Model Selected"].waitForExistence(timeout: 2), "The `Model Selected` alert did not appear.")
        XCTAssertTrue(app.staticTexts["gpt-4o"].exists, "The correct model was not registered.")
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
        XCTAssert(app.pickerWheels["gpt-3.5-turbo"].waitForExistence(timeout: 2))
        #else
        XCTAssert(app.popUpButtons["gpt-3.5-turbo"].waitForExistence(timeout: 2))
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
        XCTAssert(app.pickerWheels["gpt-3.5-turbo"].waitForExistence(timeout: 2))
        #else
        XCTAssert(app.popUpButtons["gpt-3.5-turbo"].waitForExistence(timeout: 2))
        #endif
    }
    
    func testSpeziLLMOpenAIChat() throws {
        let app = XCUIApplication()
        
        #if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .pad {
            throw XCTSkip("Skipped on iPad, see: https://github.com/StanfordBDHG/XCTestExtensions/issues/27")
        }
        #endif
        
        XCTAssert(app.buttons["LLMOpenAI"].waitForExistence(timeout: 2))
        app.buttons["LLMOpenAI"].tap()
        
        XCTAssert(app.buttons["Record Message"].waitForExistence(timeout: 2))
        
        XCTAssertFalse(app.staticTexts["You're a helpful assistant that answers questions from users."].waitForExistence(timeout: 2))

        sleep(1)

        XCTAssert(app.buttons["Record Message"].isEnabled)
        
        try app.textFields["Message Input Textfield"].enter(value: "New Message!", options: [.disableKeyboardDismiss])
        
        XCTAssert(app.buttons["Send Message"].waitForExistence(timeout: 2))
        app.buttons["Send Message"].tap()
        
        sleep(3)
        
        XCTAssert(app.staticTexts["Mock Message from SpeziLLM!"].waitForExistence(timeout: 5))
    }
}
