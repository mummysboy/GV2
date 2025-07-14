//
//  Persistence.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import CoreData
import CloudKit
import UIKit

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for preview
        createSampleData(in: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            // Log error for debugging but don't crash in production
            print("Preview data creation failed: \(error.localizedDescription)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "GV2")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit for production
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve a persistent store description.")
            }
            
            // Enable CloudKit sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Configure CloudKit container
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.yourcompany.GV2"
            )
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Production error handling - log and notify user instead of crashing
                print("Core Data store failed to load: \(error.localizedDescription)")
                print("Error details: \(error.userInfo)")
                
                // Post notification for UI to handle gracefully
                NotificationCenter.default.post(
                    name: .coreDataLoadFailed,
                    object: nil,
                    userInfo: ["error": error]
                )
            } else {
                print("Core Data store loaded successfully")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Create sample data if this is the first launch and not in memory
        if !inMemory && !hasSampleData() {
            PersistenceController.createSampleData(in: container.viewContext)
            do {
                try container.viewContext.save()
                print("✅ Sample data created successfully with profile pictures")
            } catch {
                print("Failed to save sample data: \(error.localizedDescription)")
            }
        }
    }
    
    private func hasSampleData() -> Bool {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        return (try? container.viewContext.count(for: request)) ?? 0 > 0
    }
    
    // MARK: - Error Handling
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Production error handling
                print("Failed to save context: \(error.localizedDescription)")
                NotificationCenter.default.post(
                    name: .coreDataSaveFailed,
                    object: nil,
                    userInfo: ["error": error]
                )
            }
        }
    }
    
    // MARK: - Profile Picture Generation
    static func generateProfilePicture(for name: String, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        print("🎨 Generating real profile picture for: \(name)")
        
        // Use the ImageCacheService to fetch real profile pictures
        let semaphore = DispatchSemaphore(value: 0)
        var resultData: Data?
        
        ImageCacheService.shared.fetchProfilePicture(for: name) { image in
            if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
                resultData = data
                print("📸 Real profile picture generated for \(name): \(data.count) bytes")
            } else {
                print("❌ Failed to fetch real profile picture for \(name)")
                // Fallback to generated avatar
                resultData = generateFallbackAvatar(for: name, size: size)
            }
            semaphore.signal()
        }
        
        // Wait for the async operation to complete
        _ = semaphore.wait(timeout: .now() + 10.0) // 10 second timeout
        
        return resultData
    }
    
    // MARK: - Fallback Avatar Generation
    private static func generateFallbackAvatar(for name: String, size: CGSize = CGSize(width: 200, height: 200)) -> Data? {
        print("🔄 Using fallback avatar for: \(name)")
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Generate a consistent color based on the name
            let colors: [UIColor] = [
                UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0), // Blue
                UIColor(red: 0.9, green: 0.4, blue: 0.6, alpha: 1.0), // Pink
                UIColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1.0), // Green
                UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0), // Orange
                UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0), // Purple
                UIColor(red: 0.9, green: 0.2, blue: 0.3, alpha: 1.0), // Red
                UIColor(red: 0.3, green: 0.7, blue: 0.8, alpha: 1.0), // Teal
                UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0)  // Brown
            ]
            
            let colorIndex = abs(name.hashValue) % colors.count
            let backgroundColor = colors[colorIndex]
            
            // Fill background
            backgroundColor.setFill()
            context.fill(rect)
            
            // Create a subtle gradient overlay
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = rect
            gradientLayer.colors = [
                backgroundColor.cgColor,
                backgroundColor.withAlphaComponent(0.8).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            
            if let gradientImage = gradientLayer.renderAsImage() {
                gradientImage.draw(in: rect)
            }
            
            // Add initials
            let initials = name.components(separatedBy: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.3, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = initials.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            // Add a subtle shadow
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.3).cgColor)
            
            initials.draw(in: textRect, withAttributes: attributes)
            
            // Add a subtle border
            context.cgContext.setLineWidth(2)
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            context.cgContext.addEllipse(in: rect.insetBy(dx: 1, dy: 1))
            context.cgContext.strokePath()
        }
        
        let imageData = image.jpegData(compressionQuality: 0.8)
        print("📸 Fallback avatar generated for \(name): \(imageData?.count ?? 0) bytes")
        return imageData
    }
    
    // MARK: - Sample Data (Development Only)
    static func createSampleData(in context: NSManagedObjectContext) {
        print("🔄 Creating sample data with profile pictures...")
        #if DEBUG
        // Create sample users with profile pictures
        let users = [
            ("Sarah Chen", "San Francisco, CA", "Professional photographer with 5+ years experience", true, 4.8, 127),
            ("Mike Rodriguez", "Los Angeles, CA", "Certified personal trainer and nutrition coach", true, 4.9, 89),
            ("Emma Thompson", "Austin, TX", "Creative graphic designer and illustrator", false, 4.7, 56),
            ("David Kim", "Seattle, WA", "Experienced dog trainer and pet sitter", true, 4.6, 203),
            ("Lisa Park", "Miami, FL", "Professional makeup artist for events", true, 4.9, 78),
            ("Alex Johnson", "Portland, OR", "Skilled handyman and home repair expert", false, 4.5, 45),
            ("Maria Garcia", "Denver, CO", "Certified yoga instructor and wellness coach", true, 4.8, 112),
            ("Tom Wilson", "Chicago, IL", "Professional resume writer and career coach", true, 4.7, 67)
        ]
        
        var createdUsers: [User] = []
        
        for (name, location, bio, verified, rating, reviews) in users {
            let user = User(context: context)
            user.id = UUID()
            user.name = name
            user.location = location
            user.bio = bio
            user.isVerified = verified
            user.rating = rating
            user.totalReviews = Int32(reviews)
            user.createdAt = Date()
            user.updatedAt = Date()
            
            // Generate and assign profile picture
            if let profileImageData = generateProfilePicture(for: name) {
                user.avatar = profileImageData
                print("📸 Generated profile picture for \(name)")
            }
            
            createdUsers.append(user)
        }
        
        // Create sample gigs
        let gigs = [
            ("Professional Photography Session", "Capture your special moments with professional photography. I specialize in portraits, events, and lifestyle photography.", "Creative", 150.0, "per session", ["photography", "portraits", "events"], "San Francisco, CA"),
            ("Personal Training & Nutrition", "Transform your fitness journey with personalized training plans and nutrition guidance. Certified trainer with proven results.", "Fitness", 75.0, "per hour", ["fitness", "training", "nutrition"], "Los Angeles, CA"),
            ("Custom Logo Design", "Create a unique brand identity with custom logo design. Professional graphic design services for businesses and individuals.", "Creative", 200.0, "per logo", ["design", "logo", "branding"], "Austin, TX"),
            ("Dog Training & Walking", "Professional dog training and daily walking services. Certified trainer specializing in obedience and behavior modification.", "Pet Care", 45.0, "per session", ["dogs", "training", "walking"], "Seattle, WA"),
            ("Event Makeup & Styling", "Professional makeup and styling for special events. Bridal, prom, and party makeup with premium products.", "Beauty", 120.0, "per event", ["makeup", "styling", "events"], "Miami, FL"),
            ("Home Repair & Maintenance", "Reliable handyman services for all your home repair needs. From plumbing to electrical, I handle it all.", "Home", 65.0, "per hour", ["repair", "maintenance", "handyman"], "Portland, OR"),
            ("Yoga & Wellness Coaching", "Transform your mind and body with personalized yoga sessions and wellness coaching. Certified instructor.", "Fitness", 60.0, "per session", ["yoga", "wellness", "meditation"], "Denver, CO"),
            ("Resume Writing & Career Coaching", "Professional resume writing and career coaching services. Help you land your dream job with expert guidance.", "Professional", 100.0, "per resume", ["resume", "career", "coaching"], "Chicago, IL"),
            ("Surf Lessons", "Learn to surf with experienced instructor. Private and group lessons available for all skill levels.", "Sports", 80.0, "per lesson", ["surfing", "lessons", "ocean"], "San Diego, CA"),
            ("Home Cleaning Service", "Professional home cleaning service. Deep cleaning, regular maintenance, and move-in/out cleaning available.", "Home", 120.0, "per cleaning", ["cleaning", "home", "maintenance"], "Phoenix, AZ"),
            ("Guitar Lessons", "Learn to play guitar with personalized lessons. All skill levels welcome, from beginner to advanced.", "Music", 50.0, "per lesson", ["guitar", "music", "lessons"], "Nashville, TN"),
            ("Pet Photography", "Capture your furry friends with professional pet photography. Indoor and outdoor sessions available.", "Creative", 95.0, "per session", ["pets", "photography", "portraits"], "Dallas, TX")
        ]
        
        for (title, description, category, price, priceType, tags, location) in gigs {
            let gig = Gig(context: context)
            gig.id = UUID()
            gig.title = title
            gig.gigDescription = description
            gig.category = category
            gig.price = price
            gig.priceType = priceType
            gig.tags = tags as NSObject
            gig.location = location
            gig.isActive = true
            gig.createdAt = Date().addingTimeInterval(-Double.random(in: 0...86400*30)) // Random date within last 30 days
            gig.updatedAt = Date()
            gig.provider = createdUsers.randomElement()
        }
        
        // Create sample reviews
        let reviewComments = [
            "Amazing service! Highly recommend.",
            "Professional and reliable. Will book again!",
            "Exceeded my expectations. Great communication.",
            "Very skilled and friendly. Perfect for my needs.",
            "Outstanding quality and attention to detail.",
            "Prompt, professional, and reasonably priced.",
            "Couldn't be happier with the results!",
            "Excellent work ethic and great personality.",
            "Highly skilled and very accommodating.",
            "Fantastic experience from start to finish."
        ]
        
        for _ in 0..<50 {
            let review = Review(context: context)
            review.id = UUID()
            review.comment = reviewComments.randomElement() ?? "Great service!"
            review.rating = Int16.random(in: 4...5)
            review.createdAt = Date().addingTimeInterval(-Double.random(in: 0...86400*90)) // Random date within last 90 days
            review.gig = context.registeredObjects.compactMap { $0 as? Gig }.randomElement()
            review.reviewer = createdUsers.randomElement()
        }
        #endif
    }
    
    // MARK: - Development Helper Functions
    #if DEBUG
    static func forceRegenerateSampleData() {
        let context = shared.container.viewContext
        
        // Delete all existing data
        let fetchRequests: [NSFetchRequest<NSFetchRequestResult>] = [
            User.fetchRequest(),
            Gig.fetchRequest(),
            Review.fetchRequest(),
            Product.fetchRequest()
        ]
        
        for fetchRequest in fetchRequests {
            do {
                let existingData = try context.fetch(fetchRequest)
                for object in existingData {
                    context.delete(object as! NSManagedObject)
                }
                print("🗑️ Cleared existing data")
            } catch {
                print("Error clearing data: \(error)")
            }
        }
        
        // Create new sample data
        createSampleData(in: context)
        
        do {
            try context.save()
            print("✅ Sample data regenerated successfully with profile pictures!")
        } catch {
            print("Failed to save regenerated sample data: \(error)")
        }
    }
    
    static func debugCheckProfilePictures() {
        let context = shared.container.viewContext
        let request: NSFetchRequest<User> = User.fetchRequest()
        
        do {
            let users = try context.fetch(request)
            print("🔍 Found \(users.count) users in database")
            
            for user in users {
                let hasAvatar = user.avatar != nil
                let avatarSize = user.avatar?.count ?? 0
                print("👤 \(user.name ?? "Unknown"): Avatar = \(hasAvatar ? "YES" : "NO"), Size = \(avatarSize) bytes")
            }
            
            // Test profile picture generation
            if let testImageData = generateProfilePicture(for: "Test User") {
                print("✅ Test profile picture generated: \(testImageData.count) bytes")
            } else {
                print("❌ Failed to generate test profile picture")
            }
        } catch {
            print("❌ Error fetching users: \(error)")
        }
    }
    #endif
}

// MARK: - Notification Names
extension Notification.Name {
    static let coreDataLoadFailed = Notification.Name("coreDataLoadFailed")
    static let coreDataSaveFailed = Notification.Name("coreDataSaveFailed")
}

// MARK: - CAGradientLayer Extension
extension CAGradientLayer {
    func renderAsImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            render(in: context.cgContext)
        }
    }
}
