import SwiftUI
import CoreData

struct ProviderProfileView: View {
    let provider: User
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingChat = false
    @State private var showingCall = false
    @State private var showingReport = false
    @State private var showingAllReviews = false
    @StateObject private var reviewScheduler: ReviewScheduler
    @StateObject private var conversationMonitor = ConversationMonitor()
    
    init(provider: User) {
        self.provider = provider
        let monitor = ConversationMonitor()
        self._reviewScheduler = StateObject(wrappedValue: ReviewScheduler(conversationMonitor: monitor))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with profile info
                    VStack(spacing: 16) {
                        // Profile image and basic info
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(String(provider.name?.prefix(1) ?? "U"))
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(provider.name ?? "Unknown Provider")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if provider.isVerified == true {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                    }
                                }
                                
                                Text(provider.location ?? "Location not specified")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 16) {
                                    VStack {
                                        Text(String(format: "%.1f", provider.rating))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text("Rating")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack {
                                        Text("\(provider.totalReviews)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text("Reviews")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack {
                                        Text("\(provider.gigs?.count ?? 0)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text("Gigs")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: { showingChat = true }) {
                                HStack {
                                    Image(systemName: "message")
                                    Text("Message")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(12)
                            }
                            
                            Button(action: { showingCall = true }) {
                                HStack {
                                    Image(systemName: "phone")
                                    Text("Call")
                                }
                                .font(.headline)
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    
                    // About section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(provider.bio ?? "No bio available")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    
                    // Contact preferences
                    if let contactPreferences = provider.contactPreferences as? [String], !contactPreferences.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact Preferences")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(contactPreferences, id: \.self) { preference in
                                    HStack {
                                        Image(systemName: preferenceIcon(for: preference))
                                            .foregroundColor(.purple)
                                        Text(preference)
                                            .font(.body)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    
                    // Social media links
                    if let socialLinks = provider.socialLinks as? [String: String], !socialLinks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Social Media")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(socialLinks.keys.sorted()), id: \.self) { platform in
                                    if let link = socialLinks[platform] {
                                        HStack {
                                            Image(systemName: socialIcon(for: platform))
                                                .foregroundColor(.purple)
                                                .frame(width: 20)
                                            
                                            Text(platform.capitalized)
                                                .font(.body)
                                            
                                            Spacer()
                                            
                                            Button("Visit") {
                                                // In a real app, this would open the URL
                                                print("Opening \(link)")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    
                    // Reviews Section
                    allReviewsSection
                    
                    // Provider's gigs
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Services Offered")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let gigs = provider.gigs?.allObjects as? [Gig], !gigs.isEmpty {
                            LazyVStack(spacing: 12) {
                                ForEach(gigs.prefix(3)) { gig in
                                    GigPreviewCard(gig: gig)
                                }
                            }
                        } else {
                            Text("No services available")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("Provider Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingReport = true }) {
                        Image(systemName: "flag")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingChat) {
            ChatView(partner: provider)
        }
        .fullScreenCover(isPresented: $showingCall) {
            InAppCallView(provider: provider)
        }
        .alert("Report Provider", isPresented: $showingReport) {
            Button("Report", role: .destructive) {
                // Handle report action
                print("Reporting provider: \(provider.name ?? "Unknown")")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to report this provider? This action will be reviewed by our team.")
        }
        .onAppear {
            reviewScheduler.loadProviderReviews(for: provider.id?.uuidString ?? "")
        }
    }
    
    private var allReviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reviews for \(provider.name ?? "Provider")")
                .font(.headline)

            if reviewScheduler.allProviderReviews.isEmpty {
                Text("This provider hasn't been reviewed yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(reviewScheduler.allProviderReviews) { review in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(review.reviewerName)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(String(format: "%.1f ★", review.rating))
                                .foregroundColor(.yellow)
                        }
                        Text(review.comment)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 6)
                }
            }
        }
        .padding(.top, 20)
    }
    
    private func preferenceIcon(for preference: String) -> String {
        switch preference.lowercased() {
        case "message":
            return "message"
        case "call":
            return "phone"
        case "email":
            return "envelope"
        case "video call":
            return "video"
        default:
            return "questionmark"
        }
    }
    
    private func socialIcon(for platform: String) -> String {
        switch platform.lowercased() {
        case "instagram":
            return "camera"
        case "twitter":
            return "bird"
        case "facebook":
            return "person.2"
        case "linkedin":
            return "briefcase"
        case "website":
            return "globe"
        default:
            return "link"
        }
    }
}

struct GigPreviewCard: View {
    let gig: Gig
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.purple.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(gig.category?.prefix(1) ?? "G"))
                        .font(.headline)
                        .foregroundColor(.purple)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gig.title ?? "Untitled Gig")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(gig.category ?? "Category")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.0f", gig.price))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text(gig.priceType ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ReviewCardView: View {
    let review: AppReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reviewer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(star <= review.rating ? .yellow : .gray)
                        }
                    }
                }
                
                Spacer()
                
                Text(formatDate(review.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
} 