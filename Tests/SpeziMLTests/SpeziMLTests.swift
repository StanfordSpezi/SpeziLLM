//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import SpeziML
import XCTest


final class SpeziMLTests: XCTestCase {
    func testSpeziML() throws {
        let speziML = SpeziML()
        XCTAssertEqual(speziML.stanford, "Stanford University")
    }
}
