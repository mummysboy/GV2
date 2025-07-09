import SwiftUI
import CoreData

struct ChatView: View {
    let partner: User
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var chatService: ChatService
    @StateObject private var moderationService = ModerationService()
    
    @State private var messageText = ""
    @State private var showingModerationAlert = false
    @State private var moderationResult: ModerationResult?
    
    init(partner: User) {
        self.partner = partner
        // Initialize chat service with current user ID
        let currentUserId = "current_user" // In a real app, get from auth service
        self._chatService = StateObject(wrappedValue: ChatService(currentUserId: currentUserId))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatService.currentMessages) { message in
                                UserChatMessageBubble(
                                    message: message,
                                    isFromCurrentUser: message.senderId == "current_user"
                                )
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatService.currentMessages.count) { _ in
                        if let lastMessage = chatService.currentMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(moderationService.isProcessing)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(messageText.isEmpty || moderationService.isProcessing ? .gray : .purple)
                            .font(.title3)
                    }
                    .disabled(messageText.isEmpty || moderationService.isProcessing)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle(partner.name ?? "Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "phone")
                            .foregroundColor(.purple)
                    }
                }
            }
            .onAppear {
                // Load messages for this conversation
                let thread = chatService.createOrGetThread(with: partner.id?.uuidString ?? "unknown")
                chatService.loadMessages(for: thread.id)
            }
        }
        .alert("Content Moderation", isPresented: $showingModerationAlert) {
            Button("OK") {
                showingModerationAlert = false
            }
        } message: {
            if let result = moderationResult {
                Text(moderationAlertMessage(for: result))
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        // Moderate the message before sending
        Task {
            let result = await moderationService.moderateMessage(content, senderId: chatService.currentUserId)
            
            await MainActor.run {
                moderationResult = result
                
                switch result.action {
                case .allow:
                    // Send the message
                    chatService.sendMessage(content, to: partner.id?.uuidString ?? "unknown")
                    
                case .warn:
                    // Show warning but allow message
                    showingModerationAlert = true
                    chatService.sendMessage(content, to: partner.id?.uuidString ?? "unknown")
                    
                case .block:
                    // Block the message
                    showingModerationAlert = true
                    
                case .report:
                    // Report and block
                    showingModerationAlert = true
                    // In a real app, this would trigger additional reporting logic
                    
                case .endCall:
                    // Not applicable for messages
                    break
                }
            }
        }
    }
    
    private func moderationAlertMessage(for result: ModerationResult) -> String {
        switch result.level {
        case .safe:
            return "Message sent successfully."
        case .warning:
            return "Warning: Your message contains potentially inappropriate content. Please be respectful."
        case .violation:
            return "Your message has been blocked due to inappropriate content. Please review our community guidelines."
        case .severe:
            return "Your message has been blocked and reported due to severe violations. This incident has been logged."
        }
    }
}

struct UserChatMessageBubble: View {
    let message: UserChatMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? Color.purple : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

 