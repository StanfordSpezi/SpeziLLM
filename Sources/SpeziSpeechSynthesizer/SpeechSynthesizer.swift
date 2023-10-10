//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import AVFoundation


/// An object that produces synthesized speech from text utterances.
///
/// Encapsulates the functionality of the `AVSpeechSynthesizer`.
public class SpeechSynthesizer: ObservableObject {
    private lazy var avSpeechSynthesizer = AVSpeechSynthesizer()
    
    
    public init() { }
    
    
    /// Adds the text to the speech synthesizer’s queue.
    /// - Parameters:
    ///   - text: A string that contains the text to speak.
    ///   - language: Optional BCP 47 code that identifies the language and locale for a voice.
    public func speak(_ text: String, language: String? = nil) {
        let utterance = AVSpeechUtterance(string: text)
        
        if let language {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }

        speak(utterance)
    }
    
    /// Adds the utterance to the speech synthesizer’s queue.
    /// - Parameter utterance: An `AVSpeechUtterance` instance that contains text to speak.
    public func speak(_ utterance: AVSpeechUtterance) {
        avSpeechSynthesizer.speak(utterance)
    }
}
