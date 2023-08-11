import OpenAI
import SwiftUI

/// Displays the content of a `Chat` message in a message bubble
public struct MessageView: View {
    let chat: Chat
    let hideMessagesWithRoles: Set<Chat.Role>
    
    public enum Defaults {
        static let hideMessagesWithRoles: Set<Chat.Role> = [.system, .function]
    }
    
    private var foregroundColor: Color {
        chat.allignment == .leading ? .primary : .white
    }
    
    private var backgroundColor: Color {
        chat.allignment == .leading ? Color(.secondarySystemBackground) : .accentColor
    }
    
    private var multilineTextAllignment: TextAlignment {
        chat.allignment == .leading ? .leading : .trailing
    }
    
    private var arrowRotation: Angle {
        .degrees(chat.allignment == .leading ? -50 : -130)
    }
    
    private var arrowAllignment: CGFloat {
        chat.allignment == .leading ? -7 : 7
    }
    
    public var body: some View {
        if !hideMessagesWithRoles.contains(chat.role), let content = chat.content {
            HStack {
                if chat.allignment == .trailing {
                    Spacer(minLength: 32)
                }
                Text(content)
                    .multilineTextAlignment(multilineTextAllignment)
                    .frame(idealWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .foregroundColor(foregroundColor)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        Image(systemName: "arrowtriangle.left.fill")
                            .foregroundColor(backgroundColor)
                            .rotationEffect(arrowRotation)
                            .offset(x: arrowAllignment),
                        alignment: chat.allignment == .leading ? .bottomLeading : .bottomTrailing
                    )
                    .padding(.horizontal, 4)
                if chat.allignment == .leading {
                    Spacer(minLength: 32)
                }
            }
        }
    }
    
    public init(_ chat: Chat, hideMessageWithRoles: Set<Chat.Role>) {
        self.chat = chat
        self.hideMessagesWithRoles = MessageView.Defaults.hideMessagesWithRoles
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                MessageView(Chat(role: .system, content: "System Message!"), hideMessageWithRoles: MessageView.Defaults.hideMessagesWithRoles)
                MessageView(Chat(role: .system, content: "System Message (hidden)!"), hideMessageWithRoles: MessageView.Defaults.hideMessagesWithRoles)
                MessageView(Chat(role: .function, content: "Function Message!"), hideMessageWithRoles: MessageView.Defaults.hideMessagesWithRoles)
                MessageView(Chat(role: .user, content: "User Message!"), hideMessageWithRoles: MessageView.Defaults.hideMessagesWithRoles)
                MessageView(Chat(role: .assistant, content: "User Message!"), hideMessageWithRoles: MessageView.Defaults.hideMessagesWithRoles)
            }
            .padding()
        }
    }
}
