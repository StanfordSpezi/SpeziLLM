//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

extension _LLMFunctionParameterWrapper {
    /// Represents the `format` property of the JSON schema used of OpenAI Function calling.
    public enum Format: String {
        /// A string instance is valid against this attribute if it is a valid date representation as defined by RFC 3339, section 5.6 [RFC3339].
        case datetime
        /// A string instance is valid against this attribute if it is a valid Internet email address as defined by RFC 5322, section 3.4.1 [RFC5322].
        case email
        /// A string instance is valid against this attribute if it is a valid representation for an Internet host name, as defined by RFC 1034, section 3.1 [RFC1034].
        case hostname
        /// A string instance is valid against this attribute if it is a valid representation of an IPv4 address according to the "dotted-quad" ABNF syntax as defined in RFC 2673, section 3.2 [RFC2673].
        case ipv4
        /// A string instance is valid against this attribute if it is a valid representation of an IPv6 address as defined in RFC 2373, section 2.2 [RFC2373].
        case ipv6
        /// A string instance is valid against this attribute if it is a valid URI, according to [RFC3986].
        case uri
        
        
        /// Encoded value in the JSON schema.
        public var rawValue: String {
            switch self {
            case .datetime: "date-time"
            case .email: "email"
            case .hostname: "hostname"
            case .ipv4: "ipv4"
            case .ipv6: "ipv6"
            case .uri: "uri"
            }
        }
    }
}
