//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import SwiftUI
import AVFoundation
import Speech


/// Displays a textfield to append a message to a chat.
public struct MessageInputView: View {
    let messagePlaceholder: String
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let audioEngine = AVAudioEngine()
    
    @Binding var chat: [Chat]
    @State var message: String = ""
    @State var messageViewHeight: CGFloat = 0
    @State private var isRecording = false
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    public var body: some View {
        HStack(alignment: .bottom) {
            TextField(messagePlaceholder, text: $message, axis: .vertical)
                .accessibilityLabel(String(localized: "MESSAGE_INPUT_TEXTFIELD", bundle: .module))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(UIColor.systemGray2), lineWidth: 0.2)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.2))
                        }
                        .padding(.trailing, -30)
                }
                .lineLimit(1...5)
            Button(
                action: {
                    audioEngine.stop()
                    recognitionRequest?.endAudio()
                    isRecording = false
                    chat.append(Chat(role: .user, content: message))
                    message = ""
                },
                label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .accessibilityLabel(String(localized: "SEND_MESSAGE", bundle: .module))
                        .font(.title)
                        .padding(.horizontal, -14)
                        .foregroundColor(
                            message.isEmpty ? Color(.systemGray5) : .accentColor
                        )
                }
            )
                .padding(.trailing, -38)
                .padding(.bottom, 3)
                .disabled(message.isEmpty)
            Button(action: {
                if isRecording {
                    audioEngine.stop()
                    recognitionRequest?.endAudio()
                    isRecording = false
                } else {
                    isRecording = true
                    do {
                        try startUpdatingMessage()
                    } catch {
                        
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .foregroundColor(isRecording ? Color.red : Color.blue)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "mic.fill")
                        .foregroundColor(.white)
                        .font(.title)
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                        .alignmentGuide(HorizontalAlignment.center, computeValue: { dimension in
                            dimension[HorizontalAlignment.center]
                        })
                        .alignmentGuide(VerticalAlignment.center, computeValue: { dimension in
                            dimension[VerticalAlignment.center]
                        })
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .opacity(isRecording ? 0.7 : 1.0)
                        .animation(
                            isRecording ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                            value: isRecording
                        )
                }
            }
            .padding(EdgeInsets(top: 5, leading: 20, bottom: 0, trailing: 0))
        }
            .padding(.trailing, 23)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.white.opacity(0.4))
            .background(.thinMaterial)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            messageViewHeight = proxy.size.height
                        }
                        .onChange(of: message) { _ in
                            messageViewHeight = proxy.size.height
                        }
                }
            }
            .messageInputViewHeight(messageViewHeight)
    }
    
    private func startUpdatingMessage() {
        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error setting up the audio session: \(error.localizedDescription)")
        }
        let inputNode = audioEngine.inputNode

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if isRecording {
                if let result = result {
                    
                    if result.bestTranscription.formattedString.contains("send") {
                        audioEngine.stop()
                        recognitionRequest.endAudio()
                        isRecording = false
                        chat.append(Chat(role: .user, content: message))
                        message = ""
                    } else {
                        message = result.bestTranscription.formattedString
                    }
                    
                    isFinal = result.isFinal
                    
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do { try audioEngine.start()
        } catch {
            print("Error setting up the audio session: \(error.localizedDescription)")
        }
    }
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            
        } else {
           
        }
    }

    /// - Parameters:
    ///   - chat: The chat that should be appended to.
    ///   - messagePlaceholder: Placeholder text that should be added in the input field
    public init(
        _ chat: Binding<[Chat]>,
        messagePlaceholder: String? = nil
    ) {
        self._chat = chat
        self.messagePlaceholder = messagePlaceholder ?? "Message"
    }
}


struct MessageInputView_Previews: PreviewProvider {
    @State static var chat = [
        Chat(role: .system, content: "System Message!"),
        Chat(role: .system, content: "System Message (hidden)!"),
        Chat(role: .function, content: "Function Message!"),
        Chat(role: .user, content: "User Message!"),
        Chat(role: .assistant, content: "Assistant Message!")
    ]
    
    
    static var previews: some View {
        ZStack {
            Color(.secondarySystemBackground)
                .ignoresSafeArea()
            VStack {
                MessagesView($chat)
                MessageInputView($chat)
            }
                .onPreferenceChange(MessageInputViewHeightKey.self) { newValue in
                    print("New MessageView height: \(newValue)")
                }
        }
    }
}
