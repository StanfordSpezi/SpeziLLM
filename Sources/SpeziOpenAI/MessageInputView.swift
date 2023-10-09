//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import AVFoundation
import OpenAI
import Speech
import SpeziSpeechRecognizer
import SwiftUI


/// Displays a textfield to append a message to a chat.
public struct MessageInputView: View {
    private let messagePlaceholder: String
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @Binding private var chat: [Chat]
    @State private var message: String = ""
    @State private var messageViewHeight: CGFloat = 0
    
    
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
                    sendMessageButtonPressed()
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
            if speechRecognizer.isAvailable {
                customButton
            }
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
    
    private var customButton: some View {
        Button(
            action: {
                microphoneButtonPressed()
            }
        ) {
            ZStack {
                Circle()
                    .foregroundColor(speechRecognizer.isRecording ? Color.red : Color.blue)
                    .frame(width: 44, height: 44)
                Image(systemName: "mic.fill")
                    .accessibilityLabel(String(localized: "MICROPHONE_BUTTON", bundle: .module))
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
                    .scaleEffect(speechRecognizer.isRecording ? 1.2 : 1.0)
                    .opacity(speechRecognizer.isRecording ? 0.7 : 1.0)
                    .animation(
                        speechRecognizer.isRecording ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                        value: speechRecognizer.isRecording
                    )
            }
        }
        .padding(EdgeInsets(top: 5, leading: 20, bottom: 0, trailing: 0))
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
    
    
    private func sendMessageButtonPressed() {
        speechRecognizer.stop()
        chat.append(Chat(role: .user, content: message))
        message = ""
    }
    
    private func microphoneButtonPressed() {
        if speechRecognizer.isRecording {
            speechRecognizer.stop()
        } else {
            Task {
                do {
                    for try await result in speechRecognizer.start() {
                        if result.bestTranscription.formattedString.contains("send") {
                            sendMessageButtonPressed()
                        } else {
                            message = result.bestTranscription.formattedString
                        }
                    }
                } catch {
                    let alert = Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
                }
            }
        }
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
