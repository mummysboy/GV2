import SwiftUI

struct LeaveReviewView: View {
    let gigId: String
    let reviewerId: String
    let revieweeId: String
    let revieweeRole: AppReview.ReviewerRole
    let revieweeName: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var reviewScheduler: ReviewScheduler
    @StateObject private var conversationMonitor = ConversationMonitor()
    
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    
    init(gigId: String, reviewerId: String, revieweeId: String, revieweeRole: AppReview.ReviewerRole, revieweeName: String) {
        self.gigId = gigId
        self.reviewerId = reviewerId
        self.revieweeId = revieweeId
        self.revieweeRole = revieweeRole
        self.revieweeName = revieweeName
        
        let monitor = ConversationMonitor()
        self._reviewScheduler = StateObject(wrappedValue: ReviewScheduler(conversationMonitor: monitor))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Rate your experience")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("How was your experience with \(revieweeName)?")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Star Rating
                VStack(spacing: 12) {
                    Text("Rating")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                rating = star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                        }
                    }
                    
                    if rating > 0 {
                        Text(ratingText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Comment
                VStack(spacing: 12) {
                    Text("Comment (Optional)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("Share your experience...", text: $comment, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(4...6)
                }
                
                Spacer()
                
                // Submit Button
                Button(action: submitReview) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        
                        Text(isSubmitting ? "Submitting..." : "Submit Review")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(rating > 0 ? Color.purple : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(rating == 0 || isSubmitting)
            }
            .padding()
            .navigationTitle("Leave Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Review Submitted", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your review! It has been submitted successfully.")
        }
    }
    
    private var ratingText: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
    
    private func submitReview() {
        guard rating > 0 else { return }
        
        isSubmitting = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.reviewScheduler.submitReview(
                gigId: self.gigId,
                reviewerId: self.reviewerId,
                revieweeId: self.revieweeId,
                revieweeRole: self.revieweeRole,
                rating: self.rating,
                comment: self.comment.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            self.isSubmitting = false
            self.showingSuccessAlert = true
        }
    }
}

#Preview {
    LeaveReviewView(
        gigId: "gig123",
        reviewerId: "user123",
        revieweeId: "provider123",
        revieweeRole: AppReview.ReviewerRole.provider,
        revieweeName: "John Doe"
    )
} 