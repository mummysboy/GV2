//
//  Persistence.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import CoreData

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
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GV2")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Create sample data if this is the first launch
        if !hasSampleData() {
            PersistenceController.createSampleData(in: container.viewContext)
            try? container.viewContext.save()
        }
    }
    
    private func hasSampleData() -> Bool {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        return (try? container.viewContext.count(for: request)) ?? 0 > 0
    }
    
    static func createSampleData(in context: NSManagedObjectContext) {
        // Create sample users
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
    }
}
