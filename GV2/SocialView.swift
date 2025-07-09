import SwiftUI
import CoreData

// Enhanced SocialActivity struct with review content
struct SocialActivity: Identifiable {
    let id: String
    let friendName: String
    let isFriend: Bool
    let action: String // "reviewed", "used"
    let gigTitle: String
    let rating: Double?
    let reviewSnippet: String?
    let fullReview: String?
    let timestamp: Date
    let gigId: String
    let gigImage: String? // For future use
    let gigPrice: String? // For future use
}

struct SocialView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingSyncContacts = false
    @State private var showingConnectSocials = false
    @State private var showingConnections = false
    @State private var selectedFilter: ActivityFilter = .all
    @State private var selectedActivity: SocialActivity?
    @State private var showingReviewPreview = false
    
    enum ActivityFilter: String, CaseIterable {
        case all = "All"
        case friends = "Friends"
        case recent = "Recent"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ActivityFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Enhanced Social Activity Feed
                SocialActivityFeed(filter: selectedFilter, selectedActivity: $selectedActivity, showingReviewPreview: $showingReviewPreview)
            }
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Sync Contacts") {
                            showingSyncContacts = true
                        }
                        Button("Connect Socials") {
                            showingConnectSocials = true
                        }
                        Button("Manage Connections") {
                            showingConnections = true
                        }
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingSyncContacts) {
                SyncContactsView()
            }
            .sheet(isPresented: $showingConnectSocials) {
                ConnectSocialsView()
            }
            .sheet(isPresented: $showingConnections) {
                ConnectionsView()
            }
            .sheet(item: $selectedActivity) { activity in
                ReviewPreviewModal(activity: activity)
            }
        }
    }
}

struct SocialActivityFeed: View {
    let filter: SocialView.ActivityFilter
    @Binding var selectedActivity: SocialActivity?
    @Binding var showingReviewPreview: Bool
    @State private var activities: [SocialActivity] = []
    
    var body: some View {
        List {
            ForEach(activities) { activity in
                SocialActivityCard(activity: activity) {
                    selectedActivity = activity
                    showingReviewPreview = true
                }
            }
        }
        .onAppear {
            loadActivities()
        }
        .refreshable {
            loadActivities()
        }
    }
    
    private func loadActivities() {
        // Enhanced mock data with review content
        activities = [
            SocialActivity(
                id: "1",
                friendName: "Jake",
                isFriend: true,
                action: "reviewed",
                gigTitle: "Dog Walker",
                rating: 5.0,
                reviewSnippet: "Amazing service, my dog loved it! Very professional and reliable.",
                fullReview: "Amazing service, my dog loved it! Very professional and reliable. The walker was punctual and sent me updates throughout the walk. My dog came back happy and tired. Highly recommend!",
                timestamp: Date().addingTimeInterval(-3600),
                gigId: "gig1",
                gigImage: nil,
                gigPrice: "$25/hour"
            ),
            SocialActivity(
                id: "2",
                friendName: "Emily",
                isFriend: true,
                action: "used",
                gigTitle: "Home Cleaner",
                rating: nil,
                reviewSnippet: nil,
                fullReview: nil,
                timestamp: Date().addingTimeInterval(-7200),
                gigId: "gig2",
                gigImage: nil,
                gigPrice: "$80/visit"
            ),
            SocialActivity(
                id: "3",
                friendName: "Michael",
                isFriend: true,
                action: "reviewed",
                gigTitle: "Guitar Lessons",
                rating: 4.5,
                reviewSnippet: "Great teacher, learned so much in just a few sessions.",
                fullReview: "Great teacher, learned so much in just a few sessions. Very patient and explains things clearly. The lessons are well-structured and I can see my progress. Would definitely recommend!",
                timestamp: Date().addingTimeInterval(-10800),
                gigId: "gig3",
                gigImage: nil,
                gigPrice: "$60/hour"
            ),
            SocialActivity(
                id: "4",
                friendName: "Sarah",
                isFriend: false,
                action: "reviewed",
                gigTitle: "Photography",
                rating: 4.0,
                reviewSnippet: "Beautiful photos, captured the moment perfectly.",
                fullReview: "Beautiful photos, captured the moment perfectly. The photographer was creative and made us feel comfortable. The final images exceeded our expectations.",
                timestamp: Date().addingTimeInterval(-14400),
                gigId: "gig4",
                gigImage: nil,
                gigPrice: "$200/session"
            ),
            SocialActivity(
                id: "5",
                friendName: "Alex",
                isFriend: true,
                action: "reviewed",
                gigTitle: "Tutoring",
                rating: 5.0,
                reviewSnippet: nil, // No written review, just rating
                fullReview: nil,
                timestamp: Date().addingTimeInterval(-18000),
                gigId: "gig5",
                gigImage: nil,
                gigPrice: "$45/hour"
            )
        ]
        
        // Apply filter
        switch filter {
        case .friends:
            activities = activities.filter { $0.isFriend }
        case .recent:
            activities = activities.filter { $0.timestamp > Date().addingTimeInterval(-86400) } // Last 24 hours
        case .all:
            break
        }
    }
}

struct SocialActivityCard: View {
    let activity: SocialActivity
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Friend Avatar
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(activity.friendName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if activity.isFriend {
                            Text("👤 Friend")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Text(activity.timestamp.timeAgoDisplay())
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    // Action line with rating if available
                    HStack {
                        if let rating = activity.rating {
                            Text("left a \(rating, specifier: "%.1f")★ review for \(activity.gigTitle)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(activity.action) \(activity.gigTitle)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Tappable indicator
                        Image(systemName: "eye")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .opacity(0.7)
                    }
                }
            }
            
            // Review snippet if available
            if let snippet = activity.reviewSnippet {
                Text("\"\(snippet)\"")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 52) // Align with text above
            } else if activity.rating != nil {
                // Dimmed state for rating-only reviews
                Text("No written review")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))
                    .italic()
                    .padding(.leading, 52)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct ReviewPreviewModal: View {
    let activity: SocialActivity
    @Environment(\.dismiss) private var dismiss
    @State private var showingGigDetails = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Gig Title
                Text(activity.gigTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Review by line
                HStack {
                    Text("Review by \(activity.friendName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if activity.isFriend {
                        Text("👤 Friend")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Rating if available
                if let rating = activity.rating {
                    HStack {
                        Text("Rating: \(rating, specifier: "%.1f")★")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Full review content
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let fullReview = activity.fullReview {
                            Text(fullReview)
                                .font(.body)
                                .lineSpacing(4)
                        } else {
                            Text("No written review provided.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("View Full Service") {
                        showingGigDetails = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Review Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingGigDetails) {
            // Navigate to gig detail view
            GigDetailPreviewView(gigId: activity.gigId, gigTitle: activity.gigTitle)
        }
    }
}

struct GigDetailPreviewView: View {
    let gigId: String
    let gigTitle: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Gig Details for: \(gigTitle)")
                    .font(.title2)
                    .padding()
                
                Text("This would show the full gig details view")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle(gigTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Extension for time ago display
extension Date {
    func timeAgoDisplay() -> String {
        let interval = Date().timeIntervalSince(self)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

#Preview {
    SocialView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 