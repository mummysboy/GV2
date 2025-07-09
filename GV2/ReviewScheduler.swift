import Foundation
import Combine

// New Review struct as requested by user
struct SimpleReview: Identifiable {
    let id: String
    let reviewerName: String
    let rating: Double
    let comment: String
    let date: Date
}

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
    
    // Sample data for the new Review struct
    @Published var gigReviews: [SimpleReview] = []
    @Published var allProviderReviews: [SimpleReview] = []
    
    private var timer: Timer?
    private let conversationMonitor: ConversationMonitor
    
    init(conversationMonitor: ConversationMonitor) {
        self.conversationMonitor = conversationMonitor
        loadSampleData()
        startScheduler()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func loadSampleData() {
        // Sample gig reviews
        gigReviews = [
            SimpleReview(id: "1", reviewerName: "Sarah Johnson", rating: 4.5, comment: "Excellent service! Very professional and completed the work on time.", date: Date().addingTimeInterval(-86400)),
            SimpleReview(id: "2", reviewerName: "Mike Chen", rating: 5.0, comment: "Amazing quality and great communication throughout the project.", date: Date().addingTimeInterval(-172800)),
            SimpleReview(id: "3", reviewerName: "Emily Davis", rating: 4.0, comment: "Good work, would recommend to others.", date: Date().addingTimeInterval(-259200))
        ]
        
        // Sample provider reviews
        allProviderReviews = [
            SimpleReview(id: "1", reviewerName: "Sarah Johnson", rating: 4.5, comment: "Excellent service! Very professional and completed the work on time.", date: Date().addingTimeInterval(-86400)),
            SimpleReview(id: "2", reviewerName: "Mike Chen", rating: 5.0, comment: "Amazing quality and great communication throughout the project.", date: Date().addingTimeInterval(-172800)),
            SimpleReview(id: "3", reviewerName: "Emily Davis", rating: 4.0, comment: "Good work, would recommend to others.", date: Date().addingTimeInterval(-259200)),
            SimpleReview(id: "4", reviewerName: "Alex Thompson", rating: 4.8, comment: "Very satisfied with the results. Highly recommend!", date: Date().addingTimeInterval(-345600)),
            SimpleReview(id: "5", reviewerName: "Lisa Wang", rating: 4.2, comment: "Professional and reliable service provider.", date: Date().addingTimeInterval(-432000))
        ]
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
    
    // Load functions as requested by user
    func loadGigReviews(for gigId: String) {
        // In a real app, this would fetch from API
        // For now, we'll use the sample data
        print("Loading reviews for gig: \(gigId)")
        // The sample data is already loaded in loadSampleData()
    }
    
    func loadProviderReviews(for providerId: String) {
        // In a real app, this would fetch from API
        // For now, we'll use the sample data
        print("Loading reviews for provider: \(providerId)")
        // The sample data is already loaded in loadSampleData()
    }
} 