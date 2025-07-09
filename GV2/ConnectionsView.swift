import SwiftUI
import CoreData
import Foundation

struct ConnectionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socialService = SocialService.shared
    @State private var connections: [User] = []
    @State private var showingInviteFriends = false
    
    var body: some View {
        NavigationView {
            VStack {
                if connections.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("No Connections Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Connect with friends to see their activity and reviews in your social feed.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button("Invite Friends") {
                            showingInviteFriends = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    // Connections list
                    List {
                        ForEach(connections, id: \.id) { user in
                            ConnectionRow(user: user) {
                                removeConnection(for: user)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Invite") {
                        showingInviteFriends = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingInviteFriends) {
            InviteFriendsView()
        }
        .onAppear {
            loadConnections()
        }
    }
    
    private func loadConnections() {
        // In a real app, this would fetch connected users from the backend
        // For now, we'll use mock data
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 5 // Mock: get first 5 users as connections
        
        if let users = try? viewContext.fetch(request) {
            connections = users
        }
    }
    
    private func removeConnection(for user: User) {
        if let userId = user.id?.uuidString {
            socialService.removeConnection(userId: userId, context: viewContext)
            connections.removeAll { $0.id == user.id }
        }
    }
}

struct ConnectionRow: View {
    let user: User
    let onRemove: () -> Void
    @State private var showingRemoveAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            if let avatarData = user.avatar, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(user.name?.prefix(1) ?? "U"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.name ?? "Unknown User")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text(user.location ?? "Location")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(user.totalReviews) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f ★", user.rating))
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            Button(action: { showingRemoveAlert = true }) {
                Image(systemName: "person.badge.minus")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .alert("Remove Connection", isPresented: $showingRemoveAlert) {
            Button("Remove", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove this connection?")
        }
    }
}

struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inviteMessage = "Join me on GV2! I'm using this awesome gig marketplace app. Check it out!"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Invite Friends")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Share GV2 with your friends and see their activity in your social feed.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Invite message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invite Message")
                        .font(.headline)
                    
                    TextField("Customize your invite message...", text: $inviteMessage, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...5)
                }
                .padding(.horizontal)
                
                // Share options
                VStack(spacing: 12) {
                    ShareButton(
                        title: "Share via Message",
                        icon: "message",
                        color: .green
                    ) {
                        shareViaMessage()
                    }
                    
                    ShareButton(
                        title: "Share via Email",
                        icon: "envelope",
                        color: .blue
                    ) {
                        shareViaEmail()
                    }
                    
                    ShareButton(
                        title: "Copy Link",
                        icon: "link",
                        color: .purple
                    ) {
                        copyLink()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Invite Friends")
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
    
    private func shareViaMessage() {
        // In a real app, this would open the Messages app
        print("Sharing via message: \(inviteMessage)")
    }
    
    private func shareViaEmail() {
        // In a real app, this would open the Mail app
        print("Sharing via email: \(inviteMessage)")
    }
    
    private func copyLink() {
        // In a real app, this would copy the app store link
        UIPasteboard.general.string = "https://apps.apple.com/app/gv2"
        print("Link copied to clipboard")
    }
}

struct ShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    ConnectionsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 