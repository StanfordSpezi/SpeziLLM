//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Speech

// Speech recognizer class for enabling voice-based interaction
public class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine: AVAudioEngine?
    
    // If recording is in progress
    @Published public private(set) var isRecording = false
    // If speech recognition is available based on iOS
    @Published public private(set) var isAvailable: Bool
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    
    // Setup speech recognizer using user locale
    public init(locale: Locale = .current) {
        if let speechRecognizer = SFSpeechRecognizer(locale: locale) {
            self.speechRecognizer = speechRecognizer
            self.isAvailable = speechRecognizer.isAvailable
        } else {
            self.speechRecognizer = nil
            self.isAvailable = false
        }
        
        self.audioEngine = AVAudioEngine()
        
        super.init()
        
        speechRecognizer?.delegate = self
    }
    
    
    // Start recording functionality
    public func start() -> AsyncThrowingStream<SFSpeechRecognitionResult, Error> { // swiftlint:disable:this function_body_length
        // We allow a larger function and closure length as the function provides a clear encapsulated functionality and the closue is mainly the function
        // wrapped in a continuation.
        AsyncThrowingStream { continuation in // swiftlint:disable:this closure_body_length
            guard !isRecording else {
                print("You already having a recording session in progress, please cancel the first one using `stop` before starting a new session.")
                stop()
                continuation.finish()
                return
            }
            
            guard isAvailable, let audioEngine, let speechRecognizer else {
                print("The speechrecognizer is not available.")
                stop()
                continuation.finish()
                return
            }
            
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Error setting up the audio session: \(error.localizedDescription)")
                stop()
                continuation.finish(throwing: error)
            }
            
            let inputNode = audioEngine.inputNode
            
            let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest.shouldReportPartialResults = true
            self.recognitionRequest = recognitionRequest
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let error {
                    continuation.finish(throwing: error)
                }
                
                guard self.isRecording, let result else {
                    self.stop()
                    return
                }
                
                continuation.yield(result)
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            do {
                isRecording = true
                try audioEngine.start()
            } catch {
                print("Error setting up the audio session: \(error.localizedDescription)")
                stop()
                continuation.finish(throwing: error)
            }
            
            continuation.onTermination = { @Sendable _ in
                self.stop()
            }
        }
    }
    
    // Stop recording functionality
    public func stop() {
        guard isAvailable && isRecording else {
            return
        }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
    
    @_documentation(visibility: internal)
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        guard self.speechRecognizer == speechRecognizer else {
            return
        }
        
        self.isAvailable = available
    }
}
