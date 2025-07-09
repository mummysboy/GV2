import Foundation
import Combine

struct AppReview: Identifiable, Codable {
    let id: UUID
    let gigId: String
    let reviewerId: String
    let revieweeId: String
    let revieweeRole: ReviewerRole
    let rating: Int
    let comment: String
    let timestamp: Date
    
    enum ReviewerRole: String, Codable {
        case provider
        case customer
    }
}

class ReviewScheduler: ObservableObject {
    @Published var reviews: [AppReview] = []
    @Published var pendingReviewPrompts: [ServiceSession] = []
    
    private var timer: Timer?
    private let conversationMonitor: ConversationMonitor
    
    init(conversationMonitor: ConversationMonitor) {
        self.conversationMonitor = conversationMonitor
        startScheduler()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func startScheduler() {
        // Run every hour
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.checkForReviewPrompts()
        }
        
        // Run immediately on start
        checkForReviewPrompts()
    }
    
    func checkForReviewPrompts() {
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 3600)
        
        let sessionsNeedingPrompts = conversationMonitor.serviceSessions.filter { session in
            session.timestamp < twentyFourHoursAgo &&
            session.status == .pending_review
        }
        
        for session in sessionsNeedingPrompts {
            // Trigger review prompts
            triggerReviewPrompt(for: session)
        }
        
        // Update pending review prompts for UI
        pendingReviewPrompts = conversationMonitor.serviceSessions.filter { session in
            session.status == .review_prompted
        }
    }
    
    private func triggerReviewPrompt(for session: ServiceSession) {
        // In a real app, this would send push notifications or in-app notifications
        // For now, we'll just update the session status
        
        if !session.hasPromptedCustomer {
            conversationMonitor.markSessionAsPrompted(session.id, for: session.customerId)
        }
        
        if !session.hasPromptedProvider {
            conversationMonitor.markSessionAsPrompted(session.id, for: session.providerId)
        }
        
        print("Review prompts triggered for session: \(session.id)")
    }
    
    func submitReview(gigId: String, reviewerId: String, revieweeId: String, revieweeRole: AppReview.ReviewerRole, rating: Int, comment: String) {
        let review = AppReview(
            id: UUID(),
            gigId: gigId,
            reviewerId: reviewerId,
            revieweeId: revieweeId,
            revieweeRole: revieweeRole,
            rating: rating,
            comment: comment,
            timestamp: Date()
        )
        
        reviews.append(review)
        
        // In a real app, this would save to a backend service
        print("Review submitted: \(review)")
    }
    
    func getReviewsForGig(_ gigId: String) -> [AppReview] {
        return reviews.filter { $0.gigId == gigId }
    }
    
    func getReviewsForProvider(_ providerId: String) -> [AppReview] {
        return reviews.filter { 
            $0.revieweeId == providerId && $0.revieweeRole == .provider 
        }
    }
    
    func getAverageRatingForProvider(_ providerId: String) -> Double {
        let providerReviews = getReviewsForProvider(providerId)
        guard !providerReviews.isEmpty else { return 0.0 }
        
        let totalRating = providerReviews.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(providerReviews.count)
    }
    
    func getPendingReviewsForUser(_ userId: String) -> [ServiceSession] {
        return conversationMonitor.serviceSessions.filter { session in
            (session.customerId == userId || session.providerId == userId) &&
            session.status == .review_prompted
        }
    }
} 