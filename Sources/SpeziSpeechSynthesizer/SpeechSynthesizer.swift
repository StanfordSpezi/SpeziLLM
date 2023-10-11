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
public class SpeechSynthesizer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let avSpeechSynthesizer = AVSpeechSynthesizer()
    
    
    /// A Boolean value that indicates whether the speech synthesizer is speaking or is in a paused state and has utterances to speak.
    @Published public private(set) var isSpeaking = false
    /// A Boolean value that indicates whether a speech synthesizer is in a paused state.
    @Published public private(set) var isPaused = false
    
    
    override public init() {
        super.init()
        avSpeechSynthesizer.delegate = self
    }
    
    
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
    
    
    // MARK: - AVSpeechSynthesizerDelegate
    @_documentation(visibility: internal)
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
        isPaused = false
    }
    
    @_documentation(visibility: internal)
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = true
    }
    
    @_documentation(visibility: internal)
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isSpeaking = true
        isPaused = false
    }
    
    @_documentation(visibility: internal)
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
    }
    
    @_documentation(visibility: internal)
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
    }
}
