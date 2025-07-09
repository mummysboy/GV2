import Foundation
import CoreData

struct UserChatMessage: Identifiable, Codable {
    let id: UUID
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Date
    let messageType: MessageType
    let isRead: Bool
    
    enum MessageType: String, Codable {
        case text
        case image
        case audio
        case file
    }
}

struct ChatThread: Identifiable, Codable {
    let id: UUID
    let participants: [String] // User IDs
    let lastMessage: UserChatMessage?
    let lastActivity: Date
    let unreadCount: Int
}

class ChatService: ObservableObject {
    @Published var chatThreads: [ChatThread] = []
    @Published var currentMessages: [UserChatMessage] = []
    @Published var isLoading = false
    
    private let userId: String
    public var currentUserId: String { userId }
    
    init(currentUserId: String) {
        self.userId = currentUserId
        loadChatThreads()
    }
    
    func loadChatThreads() {
        // In a real app, this would fetch from a backend service
        // For now, we'll create mock data
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.chatThreads = self.createMockThreads()
            self.isLoading = false
        }
    }
    
    func loadMessages(for threadId: UUID) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentMessages = self.createMockMessages(for: threadId)
            self.isLoading = false
        }
    }
    
    func sendMessage(_ content: String, to receiverId: String, gigId: String? = nil) {
        let message = UserChatMessage(
            id: UUID(),
            senderId: userId,
            receiverId: receiverId,
            content: content,
            timestamp: Date(),
            messageType: .text,
            isRead: false
        )
        
        currentMessages.append(message)
        
        // In a real app, this would send to a backend service
        // and update the chat thread
        
        // Process for service completion detection
        if let gigId = gigId {
            // In a real app, you would get the actual User objects from the context
            // For now, we'll skip the conversation monitoring to avoid Core Data context issues
            // conversationMonitor.process(message: content, from: sender, to: receiver, gigId: gigId)
        }
    }
    
    func createOrGetThread(with userId: String) -> ChatThread {
        // Check if thread already exists
        if let existingThread = chatThreads.first(where: { thread in
            thread.participants.contains(userId) && thread.participants.contains(userId)
        }) {
            return existingThread
        }
        
        // Create new thread
        let newThread = ChatThread(
            id: UUID(),
            participants: [userId, userId],
            lastMessage: nil,
            lastActivity: Date(),
            unreadCount: 0
        )
        
        chatThreads.append(newThread)
        return newThread
    }
    
    private func createMockThreads() -> [ChatThread] {
        return [
            ChatThread(
                id: UUID(),
                participants: [userId, "user1"],
                lastMessage: UserChatMessage(
                    id: UUID(),
                    senderId: "user1",
                    receiverId: userId,
                    content: "Hi! I'm interested in your photography services",
                    timestamp: Date().addingTimeInterval(-3600),
                    messageType: .text,
                    isRead: false
                ),
                lastActivity: Date().addingTimeInterval(-3600),
                unreadCount: 1
            ),
            ChatThread(
                id: UUID(),
                participants: [userId, "user2"],
                lastMessage: UserChatMessage(
                    id: UUID(),
                    senderId: userId,
                    receiverId: "user2",
                    content: "Great! When would you like to schedule?",
                    timestamp: Date().addingTimeInterval(-7200),
                    messageType: .text,
                    isRead: true
                ),
                lastActivity: Date().addingTimeInterval(-7200),
                unreadCount: 0
            )
        ]
    }
    
    private func createMockMessages(for threadId: UUID) -> [UserChatMessage] {
        return [
            UserChatMessage(
                id: UUID(),
                senderId: "user1",
                receiverId: userId,
                content: "Hi! I'm interested in your photography services",
                timestamp: Date().addingTimeInterval(-3600),
                messageType: .text,
                isRead: true
            ),
            UserChatMessage(
                id: UUID(),
                senderId: userId,
                receiverId: "user1",
                content: "Hello! Thank you for your interest. I'd be happy to help with your photography needs.",
                timestamp: Date().addingTimeInterval(-3500),
                messageType: .text,
                isRead: true
            ),
            UserChatMessage(
                id: UUID(),
                senderId: "user1",
                receiverId: userId,
                content: "What packages do you offer and what are your rates?",
                timestamp: Date().addingTimeInterval(-3400),
                messageType: .text,
                isRead: false
            )
        ]
    }
} 