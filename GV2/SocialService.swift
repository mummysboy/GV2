import Foundation
import CoreData
import SwiftUI

class SocialService: ObservableObject {
    static let shared = SocialService()
    
    @Published var currentUserConnections: [String] = []
    @Published var friendActivities: [FriendActivityItem] = []
    
    private init() {}
    
    // MARK: - User Connections Management
    
    func addConnection(userId: String, connectionType: String = "friend", context: NSManagedObjectContext) {
        guard let currentUser = getCurrentUser(in: context) else { return }
        
        // Add to User.connections array
        var connections = currentUser.connections as? [String] ?? []
        if !connections.contains(userId) {
            connections.append(userId)
            currentUser.connections = connections as NSObject
            
            // Create UserConnection entity
            let connection = UserConnection(context: context)
            connection.id = UUID()
            connection.connectedAt = Date()
            connection.connectionType = connectionType
            connection.user = currentUser
            
            // Find the connected user
            let request: NSFetchRequest<User> = User.fetchRequest()
            if let uuid = UUID(uuidString: userId) {
                request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            } else {
                request.predicate = NSPredicate(format: "id == %@", userId)
            }
            if let connectedUser = try? context.fetch(request).first {
                connection.connectedUser = connectedUser
            }
            
            try? context.save()
        }
    }
    
    func removeConnection(userId: String, context: NSManagedObjectContext) {
        guard let currentUser = getCurrentUser(in: context) else { return }
        
        // Remove from User.connections array
        var connections = currentUser.connections as? [String] ?? []
        connections.removeAll { $0 == userId }
        currentUser.connections = connections as NSObject
        
        // Remove UserConnection entities
        let request: NSFetchRequest<UserConnection> = UserConnection.fetchRequest()
        if let uuid = UUID(uuidString: userId) {
            request.predicate = NSPredicate(format: "user == %@ AND connectedUser.id == %@", currentUser, uuid as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "user == %@ AND connectedUser.id == %@", currentUser, userId)
        }
        
        if let connections = try? context.fetch(request) {
            for connection in connections {
                context.delete(connection)
            }
        }
        
        try? context.save()
    }
    
    func getConnections(for user: User) -> [String] {
        return user.connections as? [String] ?? []
    }
    
    func isConnected(to userId: String, context: NSManagedObjectContext) -> Bool {
        guard let currentUser = getCurrentUser(in: context) else { return false }
        let connections = currentUser.connections as? [String] ?? []
        return connections.contains(userId)
    }
    
    // MARK: - Friend Activity Management
    // FriendActivity = Core Data entity, FriendActivityItem = UI struct
    func logActivity(userId: String, action: String, gigId: String, gigTitle: String, context: NSManagedObjectContext) {
        // Find the user
        let request: NSFetchRequest<User> = User.fetchRequest()
        if let uuid = UUID(uuidString: userId) {
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "id == %@", userId)
        }
        
        guard let user = try? context.fetch(request).first else { return }
        
        // Create activity
        let activity = FriendActivity(context: context)
        activity.id = UUID()
        activity.user = user
        activity.action = action
        activity.gigId = gigId
        activity.gigTitle = gigTitle
        activity.createdAt = Date()
        activity.isRead = false
        
        try? context.save()
    }
    
    func getFriendActivities(for user: User, context: NSManagedObjectContext) -> [FriendActivityItem] {
        let request: NSFetchRequest<FriendActivity> = FriendActivity.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FriendActivity.createdAt, ascending: false)]
        let coreDataActivities = (try? context.fetch(request)) ?? []
        // Map Core Data FriendActivity to FriendActivityItem for UI
        return coreDataActivities.map { activity in
            FriendActivityItem(
                id: activity.id?.uuidString ?? UUID().uuidString,
                friendName: activity.user?.name ?? "Friend",
                friendAvatar: "person.circle.fill",
                action: activity.action ?? "did something",
                gigTitle: activity.gigTitle ?? "Gig",
                gigId: activity.gigId ?? "",
                timestamp: activity.createdAt ?? Date(),
                isFriend: true // You can add logic to check if this is a friend
            )
        }
    }
    
    // Use this for Core Data entity
    func markActivityAsRead(_ activity: FriendActivity, context: NSManagedObjectContext) {
        activity.isRead = true
        try? context.save()
    }
    // Use this for UI struct
    func markActivityItemAsRead(_ item: FriendActivityItem, context: NSManagedObjectContext) {
        let request: NSFetchRequest<FriendActivity> = FriendActivity.fetchRequest()
        if let uuid = UUID(uuidString: item.id) {
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "id == %@", item.id)
        }
        if let activity = try? context.fetch(request).first {
            activity.isRead = true
            try? context.save()
        }
    }
    
    // MARK: - Review Prioritization
    
    func getPrioritizedReviews(for gig: Gig, context: NSManagedObjectContext) -> [Review] {
        guard let currentUser = getCurrentUser(in: context) else { return (gig.reviews as? Set<Review>)?.compactMap { $0 } ?? [] }
        
        let allReviews = (gig.reviews as? Set<Review>)?.compactMap { $0 } ?? []
        let userConnections = currentUser.connections as? [String] ?? []
        
        return allReviews.sorted { review1, review2 in
            let isFriend1 = userConnections.contains(review1.reviewer?.id?.uuidString ?? "")
            let isFriend2 = userConnections.contains(review2.reviewer?.id?.uuidString ?? "")
            
            // Friends first
            if isFriend1 && !isFriend2 { return true }
            if !isFriend1 && isFriend2 { return false }
            
            // Then by date (newest first)
            return (review1.createdAt ?? Date()) > (review2.createdAt ?? Date())
        }
    }
    
    func getPrioritizedReviews(for user: User, context: NSManagedObjectContext) -> [Review] {
        guard let currentUser = getCurrentUser(in: context) else { return (user.reviews as? Set<Review>)?.compactMap { $0 } ?? [] }
        
        let allReviews = (user.reviews as? Set<Review>)?.compactMap { $0 } ?? []
        let userConnections = currentUser.connections as? [String] ?? []
        
        return allReviews.sorted { review1, review2 in
            let isFriend1 = userConnections.contains(review1.reviewer?.id?.uuidString ?? "")
            let isFriend2 = userConnections.contains(review2.reviewer?.id?.uuidString ?? "")
            
            // Friends first
            if isFriend1 && !isFriend2 { return true }
            if !isFriend1 && isFriend2 { return false }
            
            // Then by date (newest first)
            return (review1.createdAt ?? Date()) > (review2.createdAt ?? Date())
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUser(in context: NSManagedObjectContext) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    // MARK: - Mock Data for Development
    
    func loadMockData(context: NSManagedObjectContext) {
        guard let currentUser = getCurrentUser(in: context) else { return }
        
        // Add mock connections
        let mockConnections = ["friend1", "friend2", "friend3"]
        currentUser.connections = mockConnections as NSObject
        
        // Add mock activities
        let mockActivities = [
            ("friend1", "left a 5★ review for", "gig1", "Dog Walker"),
            ("friend2", "used", "gig2", "Home Cleaner"),
            ("friend3", "both reviewed", "gig3", "Guitar Lessons")
        ]
        
        for (userId, action, gigId, gigTitle) in mockActivities {
            logActivity(userId: userId, action: action, gigId: gigId, gigTitle: gigTitle, context: context)
        }
        
        try? context.save()
    }
}

// MARK: - Review Display Extensions

extension Review {
    var isFromFriend: Bool {
        // This would need to be implemented based on the current user's connections
        // For now, return false as a placeholder
        return false
    }
} 