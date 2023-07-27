//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import AVFoundation
import OpenAI
import SwiftUI


/// Displays a textfield to append a message to a chat.
public struct MessageInputView: View {
    
    let messagePlaceholder: String
    @State var synthesizer = AVSpeechSynthesizer()
    
    @Binding var chat: [Chat]
    @State var message: String = ""
    @State var messageViewHeight: CGFloat = 0
    @State private var isRecording = false

    @StateObject var speechRecognizer = SpeechRecognizer()
    
    public var body: some View {
        HStack(alignment: .bottom) {
            TextField(messagePlaceholder, text: $message, axis: .vertical)
                .accessibilityLabel("Message Input Textfield")
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
                        .padding(.trailing, -10)
                }
                .lineLimit(1...5)
            Button(
                action: {
                    chat.append(Chat(role: .user, content: message))
                    speechRecognizer.resetTranscript()
                    speechRecognizer.resetText()
                    isRecording = false
                    message = ""
                },
                label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .padding(.horizontal, 16)
                        .foregroundColor(
                            message.isEmpty ? Color(.systemGray5) : .accentColor
                        )
                }
            )
            .padding(.trailing, -20)
            .padding(.bottom, 3)
            .disabled(message.isEmpty)
            Button(
                action: {
                    speechRecognizer.resetText()
                    isRecording.toggle()
                    if isRecording {
                        speechRecognizer.resetTranscript()
                        speechRecognizer.startTranscribing()
                        isRecording = true
                        startUpdatingMessage()
                    } else {
                        isRecording = false
                        speechRecognizer.stopTranscribing()
                    }
                },
                label: {
                    if isRecording {
                        Text("Stop Record")
                            .font(.system(size: 16)) // Reduce font size to title3
                    } else {
                        Text("Start Record")
                            .font(.system(size: 16)) // Reduce font size to title3
                    }
                }
            )
            .padding(.trailing, -20)
            .padding(.bottom, 6)
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
        message = ""
        DispatchQueue.global(qos: .default).async {
            while isRecording {
                message = speechRecognizer.transcript
                if message.contains("send") {
                    isRecording = false
                    if let range = message.range(of: "send") {
                        message.removeSubrange(range)
                    }
                    chat.append(Chat(role: .user, content: message))
                    speechRecognizer.stopTranscribing()
                    speechRecognizer.resetTranscript()
                    message = ""
                    speechRecognizer.resetText()
                }
            }
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
