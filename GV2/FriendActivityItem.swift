import Foundation

struct FriendActivityItem: Identifiable {
    let id: String
    let friendName: String
    let friendAvatar: String
    let action: String
    let gigTitle: String
    let gigId: String
    let timestamp: Date
    let isFriend: Bool
} 