import SwiftUI
import UserNotifications
import CoreData

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var notifications: [AppNotification] = []
    
    private init() {
        requestNotificationPermissions()
    }
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func addNotification(_ notification: AppNotification) {
        DispatchQueue.main.async {
            self.notifications.insert(notification, at: 0)
        }
        
        // Schedule local notification
        scheduleNotification(title: notification.title, body: notification.message)
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }
    
    func clearNotifications() {
        notifications.removeAll()
    }
    
    // Notification types
    func notifyGigLike(gig: Gig) {
        let notification = AppNotification(
            id: UUID(),
            title: "New Like!",
            message: "Someone liked your gig '\(gig.title ?? "Untitled")'",
            type: .gigLike,
            timestamp: Date(),
            isRead: false,
            relatedGigId: gig.id
        )
        addNotification(notification)
    }
    
    func notifyNewMessage(senderName: String, gigTitle: String) {
        let notification = AppNotification(
            id: UUID(),
            title: "New Message",
            message: "\(senderName) sent you a message about '\(gigTitle)'",
            type: .message,
            timestamp: Date(),
            isRead: false
        )
        addNotification(notification)
    }
    
    func notifyNewReview(reviewerName: String, gigTitle: String, rating: Int16) {
        let notification = AppNotification(
            id: UUID(),
            title: "New Review",
            message: "\(reviewerName) gave you a \(rating)-star review for '\(gigTitle)'",
            type: .review,
            timestamp: Date(),
            isRead: false
        )
        addNotification(notification)
    }
    
    func notifyBookingRequest(clientName: String, gigTitle: String) {
        let notification = AppNotification(
            id: UUID(),
            title: "Booking Request",
            message: "\(clientName) wants to book your gig '\(gigTitle)'",
            type: .booking,
            timestamp: Date(),
            isRead: false
        )
        addNotification(notification)
    }
    
    func notifyGigExpiring(gigTitle: String, daysLeft: Int) {
        let notification = AppNotification(
            id: UUID(),
            title: "Gig Expiring Soon",
            message: "Your gig '\(gigTitle)' expires in \(daysLeft) days",
            type: .gigExpiring,
            timestamp: Date(),
            isRead: false
        )
        addNotification(notification)
    }
    
    func notifyLowEngagement(gigTitle: String) {
        let notification = AppNotification(
            id: UUID(),
            title: "Low Engagement Alert",
            message: "Your gig '\(gigTitle)' has low engagement. Consider updating it!",
            type: .lowEngagement,
            timestamp: Date(),
            isRead: false
        )
        addNotification(notification)
    }
    
    func notifyPromotionEnding(gigTitle: String) {
        let notification = AppNotification(
            id: UUID(),
            title: "Promotion Ending",
            message: "Your promotion for '\(gigTitle)' is ending soon",
            type: .promotionEnding,
            timestamp: Date(),
            isRead: false
        )
        addNotification(notification)
    }
    
    func notifyVerificationStatus(isApproved: Bool) {
        let title = isApproved ? "Verification Approved!" : "Verification Update"
        let message = isApproved ? 
            "Congratulations! Your account has been verified." :
            "Your verification is under review. We'll notify you soon."
        
        let notification = AppNotification(
            id: UUID(),
            title: title,
            message: message,
            type: .verification,
            timestamp: Date(),
            isRead: false
        )
        addNotification(notification)
    }
}

struct AppNotification: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool
    var relatedGigId: UUID?
    
    enum NotificationType {
        case gigLike
        case message
        case review
        case booking
        case gigExpiring
        case lowEngagement
        case promotionEnding
        case verification
        
        var icon: String {
            switch self {
            case .gigLike:
                return "heart.fill"
            case .message:
                return "message.fill"
            case .review:
                return "star.fill"
            case .booking:
                return "calendar.badge.plus"
            case .gigExpiring:
                return "clock.fill"
            case .lowEngagement:
                return "chart.line.downtrend.xyaxis"
            case .promotionEnding:
                return "star.circle.fill"
            case .verification:
                return "checkmark.seal.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .gigLike:
                return .red
            case .message:
                return .blue
            case .review:
                return .yellow
            case .booking:
                return .green
            case .gigExpiring:
                return .orange
            case .lowEngagement:
                return .red
            case .promotionEnding:
                return .purple
            case .verification:
                return .blue
            }
        }
    }
}

struct NotificationView: View {
    @StateObject private var notificationService = NotificationService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if notificationService.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No notifications")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("You're all caught up!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(notificationService.notifications) { notification in
                            NotificationRow(notification: notification) {
                                notificationService.markAsRead(notification)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                notificationService.notifications.remove(at: index)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Mark All as Read") {
                            notificationService.markAllAsRead()
                        }
                        
                        Button("Clear All", role: .destructive) {
                            notificationService.clearNotifications()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.purple)
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: notification.type.icon)
                    .font(.title2)
                    .foregroundColor(notification.type.color)
                    .frame(width: 30)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(notification.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(formatTimestamp(notification.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(notification.isRead ? 0.7 : 1.0)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

 