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
    let reviewId: String? // ID of the specific review for highlighting
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
    @State private var showingGigDetail = false
    
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
                SocialActivityFeed(filter: selectedFilter, selectedActivity: $selectedActivity, showingGigDetail: $showingGigDetail)
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
            .sheet(isPresented: $showingGigDetail) {
                if let activity = selectedActivity, let gig = getGig(for: activity.gigId) {
                    // Navigate to gig detail view with highlighted review
                    GigDetailView(gig: gig, highlightedReviewId: activity.reviewId)
                } else {
                    Text("Gig not found or unavailable.")
                        .font(.title2)
                        .padding()
                }
            }
        }
    }
    
    // Helper function to get Gig from gigId
    private func getGig(for gigId: String) -> Gig? {
        let request: NSFetchRequest<Gig> = Gig.fetchRequest()
        if let uuid = UUID(uuidString: gigId) {
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            return try? viewContext.fetch(request).first
        }
        return nil
    }
}

struct SocialActivityFeed: View {
    let filter: SocialView.ActivityFilter
    @Binding var selectedActivity: SocialActivity?
    @Binding var showingGigDetail: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var activities: [SocialActivity] = []
    
    var body: some View {
        List {
            ForEach(activities) { activity in
                SocialActivityCard(activity: activity) {
                    selectedActivity = activity
                    showingGigDetail = true
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
        let gigs = (try? viewContext.fetch(Gig.fetchRequest())) as? [Gig] ?? []
        activities = []
        if !gigs.isEmpty {
            // Use up to 5 real gigs for the mock feed
            for (i, gig) in gigs.prefix(5).enumerated() {
                activities.append(
                    SocialActivity(
                        id: "mock-\(i)",
                        friendName: ["Jake", "Emily", "Michael", "Sarah", "Alex"][i % 5],
                        isFriend: i % 2 == 0,
                        action: i % 2 == 0 ? "reviewed" : "used",
                        gigTitle: gig.title ?? "Untitled Gig",
                        rating: i % 2 == 0 ? Double(4 + i % 2) : nil,
                        reviewSnippet: i % 2 == 0 ? "Sample review for \(gig.title ?? "Gig")" : nil,
                        fullReview: i % 2 == 0 ? "This is a sample full review for \(gig.title ?? "Gig")." : nil,
                        timestamp: Date().addingTimeInterval(Double(-3600 * (i + 1))),
                        gigId: gig.id?.uuidString ?? "",
                        reviewId: nil, // You can link to a real review if desired
                        gigImage: nil,
                        gigPrice: gig.priceType
                    )
                )
            }
        }
        
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
                ProfilePictureView(name: activity.friendName, size: 40, showBorder: false)
                
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