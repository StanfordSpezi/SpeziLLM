//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension String {
    /// C++ String to Swift String from: https://github.com/apple/swift/blob/cf2a338afca54a787d59b83db6238b1568215b94/stdlib/public/Cxx/std/String.swift#L231-L239
    init(_ cxxString: std.string) {
        let buffer = UnsafeBufferPointer<CChar>(
            start: cxxString.__c_strUnsafe(),
            count: cxxString.size()
        )
        self = buffer.withMemoryRebound(to: UInt8.self) {
            String(decoding: $0, as: UTF8.self)
        }
        withExtendedLifetime(cxxString) {}
    }
}
