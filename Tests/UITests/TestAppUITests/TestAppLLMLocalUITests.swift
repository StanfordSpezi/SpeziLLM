//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions


class TestAppLLMLocalUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--mockLocalLLM"]
        app.deleteAndLaunch(withSpringboardAppName: "TestApp")
    }
    
    func testSpeziLLMLocal() throws {
        let app = XCUIApplication()
        
        XCTAssert(app.buttons["LLMLocal"].waitForExistence(timeout: 2))
        app.buttons["LLMLocal"].tap()
        
        // Onboarding
        XCTAssert(app.staticTexts["Local LLM Execution"].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["LLMs on an iPhone"].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["Swift Package Manager"].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["The Stanford Spezi ecosystem"].waitForExistence(timeout: 2))
        
        XCTAssert(app.buttons["Next"].waitForExistence(timeout: 2))
        app.buttons["Next"].tap()
        
        // Chat
        XCTAssert(app.staticTexts["Hello! I'm a locally executed Llama 2 7B model, enabled by the Spezi ecosystem!"].waitForExistence(timeout: 2))
        
        try app.textViews["Message Input Textfield"].enter(value: "New Message!", dismissKeyboard: false)
        
        XCTAssert(app.buttons["Send Message"].waitForExistence(timeout: 2))
        app.buttons["Send Message"].tap()
        
        XCTAssert(app.staticTexts["New Message!"].waitForExistence(timeout: 5))
        
        sleep(3)
        
        XCTAssert(app.staticTexts["Mock Message from SpeziLLM!"].waitForExistence(timeout: 5))
    }
}
