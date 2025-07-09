import Foundation
import CoreData

struct ServiceSession: Identifiable, Codable {
    let id: UUID
    let gigId: String
    let providerId: String
    let customerId: String
    let timestamp: Date
    let source: SessionSource
    let status: SessionStatus
    let hasPromptedCustomer: Bool
    let hasPromptedProvider: Bool
    
    enum SessionSource: String, Codable {
        case message
        case voice
    }
    
    enum SessionStatus: String, Codable {
        case pending_review
        case review_prompted
        case completed
        case cancelled
    }
}

class ConversationMonitor: ObservableObject {
    @Published var serviceSessions: [ServiceSession] = []
    
    // Phrases that indicate service completion
    private let completionPhrases = [
        "thanks again",
        "all done",
        "that was great",
        "just finished",
        "service completed",
        "work is done",
        "finished up",
        "completed the job",
        "all set",
        "good to go",
        "wrapped up",
        "done with",
        "finished the",
        "completed the",
        "job is done",
        "work completed",
        "service finished",
        "task completed",
        "project finished",
        "everything is done"
    ]
    
    func process(message: String, from: User, to: User, gigId: String) {
        let lowercasedMessage = message.lowercased()
        
        // Check if message contains completion phrases
        let containsCompletionPhrase = completionPhrases.contains { phrase in
            lowercasedMessage.contains(phrase)
        }
        
        if containsCompletionPhrase {
            logServiceSession(
                gigId: gigId,
                providerId: from.id?.uuidString ?? "unknown",
                customerId: to.id?.uuidString ?? "unknown",
                source: .message
            )
        }
    }
    
    func processCallTranscript(_ transcript: String, from: User, to: User, gigId: String) {
        let lowercasedTranscript = transcript.lowercased()
        
        // Check if transcript contains completion phrases
        let containsCompletionPhrase = completionPhrases.contains { phrase in
            lowercasedTranscript.contains(phrase)
        }
        
        if containsCompletionPhrase {
            logServiceSession(
                gigId: gigId,
                providerId: from.id?.uuidString ?? "unknown",
                customerId: to.id?.uuidString ?? "unknown",
                source: .voice
            )
        }
    }
    
    private func logServiceSession(gigId: String, providerId: String, customerId: String, source: ServiceSession.SessionSource) {
        // Check if session already exists for this gig
        let existingSession = serviceSessions.first { session in
            session.gigId == gigId && session.status == .pending_review
        }
        
        if existingSession == nil {
            let newSession = ServiceSession(
                id: UUID(),
                gigId: gigId,
                providerId: providerId,
                customerId: customerId,
                timestamp: Date(),
                source: source,
                status: .pending_review,
                hasPromptedCustomer: false,
                hasPromptedProvider: false
            )
            
            serviceSessions.append(newSession)
            
            // In a real app, this would save to a backend service
            print("Service session logged: \(newSession)")
        }
    }
    
    func getPendingReviewSessions(for userId: String) -> [ServiceSession] {
        return serviceSessions.filter { session in
            (session.customerId == userId || session.providerId == userId) &&
            session.status == .pending_review
        }
    }
    
    func markSessionAsPrompted(_ sessionId: UUID, for userId: String) {
        if let index = serviceSessions.firstIndex(where: { $0.id == sessionId }) {
            var updatedSession = serviceSessions[index]
            
            if updatedSession.customerId == userId {
                updatedSession = ServiceSession(
                    id: updatedSession.id,
                    gigId: updatedSession.gigId,
                    providerId: updatedSession.providerId,
                    customerId: updatedSession.customerId,
                    timestamp: updatedSession.timestamp,
                    source: updatedSession.source,
                    status: .review_prompted,
                    hasPromptedCustomer: true,
                    hasPromptedProvider: updatedSession.hasPromptedProvider
                )
            } else if updatedSession.providerId == userId {
                updatedSession = ServiceSession(
                    id: updatedSession.id,
                    gigId: updatedSession.gigId,
                    providerId: updatedSession.providerId,
                    customerId: updatedSession.customerId,
                    timestamp: updatedSession.timestamp,
                    source: updatedSession.source,
                    status: .review_prompted,
                    hasPromptedCustomer: updatedSession.hasPromptedCustomer,
                    hasPromptedProvider: true
                )
            }
            
            serviceSessions[index] = updatedSession
        }
    }
} 