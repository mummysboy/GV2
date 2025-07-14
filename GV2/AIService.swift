//
//  AIService.swift
//  Gig
//
//  Created by Isaac Hirsch on 7/9/25.
//

import Foundation
import CoreData

class AIService: ObservableObject {
    @Published var isProcessing = false
    
    // Service categories and their keywords
    private let categoryKeywords: [String: [String]] = [
        "Creative": ["design", "art", "creative", "logo", "graphic", "photography", "drawing", "painting", "illustration", "branding", "visual", "aesthetic"],
        "Fitness": ["fitness", "workout", "training", "exercise", "gym", "personal trainer", "yoga", "pilates", "nutrition", "health", "wellness", "coaching"],
        "Home": ["home", "house", "cleaning", "repair", "maintenance", "handyman", "plumbing", "electrical", "gardening", "landscaping", "organizing"],
        "Pet Care": ["pet", "dog", "cat", "animal", "walking", "training", "sitting", "grooming", "veterinary", "care", "puppy", "kitten"],
        "Tutoring": ["tutor", "teaching", "education", "learning", "academic", "math", "science", "language", "music", "lesson", "school", "study"],
        "Beauty": ["beauty", "makeup", "hair", "styling", "cosmetic", "spa", "facial", "manicure", "pedicure", "glam", "fashion"],
        "Food": ["food", "cooking", "chef", "meal", "catering", "baking", "recipe", "diet", "nutrition", "culinary", "kitchen"],
        "Tech": ["tech", "computer", "programming", "web", "app", "software", "IT", "support", "coding", "development", "digital"],
        "Sports": ["sport", "surfing", "swimming", "tennis", "golf", "soccer", "basketball", "coaching", "athletic", "training", "fitness"],
        "Music": ["music", "guitar", "piano", "singing", "instrument", "lesson", "recording", "production", "band", "concert", "performance"],
        "Professional": ["resume", "career", "business", "consulting", "coaching", "writing", "editing", "translation", "legal", "accounting", "marketing"]
    ]
    
    // Price ranges
    private let priceRanges: [String: (min: Double, max: Double)] = [
        "budget": (0, 50),
        "affordable": (25, 100),
        "moderate": (75, 200),
        "premium": (150, 500),
        "luxury": (400, 1000)
    ]
    
    func processUserQuery(_ query: String, context: NSManagedObjectContext) async -> AIResponse {
        isProcessing = true
        defer { isProcessing = false }
        
        let lowercasedQuery = query.lowercased()
        
        // Extract intent and preferences
        let intent = extractIntent(from: lowercasedQuery)
        let categories = extractCategories(from: lowercasedQuery)
        let pricePreference = extractPricePreference(from: lowercasedQuery)
        let location = extractLocation(from: lowercasedQuery)
        
        // Find matching gigs
        let matchingGigs = await findMatchingGigs(
            categories: categories,
            priceRange: pricePreference,
            location: location,
            context: context
        )
        
        // Generate response
        let response = generateResponse(
            intent: intent,
            categories: categories,
            matchingGigs: matchingGigs,
            originalQuery: query
        )
        
        return response
    }
    
    private func extractIntent(from query: String) -> String {
        if query.contains("find") || query.contains("looking for") || query.contains("need") {
            return "search"
        } else if query.contains("recommend") || query.contains("suggest") {
            return "recommend"
        } else if query.contains("help") || query.contains("assist") {
            return "help"
        } else {
            return "general"
        }
    }
    
    private func extractCategories(from query: String) -> [String] {
        var foundCategories: [String] = []
        
        for (category, keywords) in categoryKeywords {
            for keyword in keywords {
                if query.contains(keyword) {
                    foundCategories.append(category)
                    break
                }
            }
        }
        
        return foundCategories.isEmpty ? ["Creative", "Fitness", "Home"] : foundCategories
    }
    
    private func extractPricePreference(from query: String) -> (min: Double, max: Double)? {
        for (range, (min, max)) in priceRanges {
            if query.contains(range) {
                return (min, max)
            }
        }
        
        // Extract specific price mentions
        let pricePattern = #"\$(\d+)"#
        if let regex = try? NSRegularExpression(pattern: pricePattern),
           let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) {
            if let range = Range(match.range(at: 1), in: query),
               let price = Double(query[range]) {
                return (price * 0.5, price * 1.5)
            }
        }
        
        return nil
    }
    
    private func extractLocation(from query: String) -> String? {
        let locationPattern = #"in\s+([A-Za-z\s,]+)"#
        if let regex = try? NSRegularExpression(pattern: locationPattern),
           let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) {
            if let range = Range(match.range(at: 1), in: query) {
                return String(query[range]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    private func findMatchingGigs(
        categories: [String],
        priceRange: (min: Double, max: Double)?,
        location: String?,
        context: NSManagedObjectContext
    ) async -> [Gig] {
        let request: NSFetchRequest<Gig> = Gig.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // Category filter
        if !categories.isEmpty {
            predicates.append(NSPredicate(format: "category IN %@", categories))
        }
        
        // Price filter
        if let priceRange = priceRange {
            predicates.append(NSPredicate(format: "price >= %f AND price <= %f", priceRange.min, priceRange.max))
        }
        
        // Location filter
        if let location = location {
            predicates.append(NSPredicate(format: "location CONTAINS[cd] %@", location))
        }
        
        // Active gigs only
        predicates.append(NSPredicate(format: "isActive == true"))
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Gig.provider?.rating, ascending: false),
            NSSortDescriptor(keyPath: \Gig.createdAt, ascending: false)
        ]
        
        request.fetchLimit = 10
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching matching gigs: \(error)")
            return []
        }
    }
    
    private func generateResponse(
        intent: String,
        categories: [String],
        matchingGigs: [Gig],
        originalQuery: String
    ) -> AIResponse {
        let categoryText = categories.joined(separator: ", ")
        
        if matchingGigs.isEmpty {
            return AIResponse(
                message: "I couldn't find any services matching your request. Try broadening your search or check back later for new listings!",
                suggestions: ["Try different keywords", "Browse all categories", "Check back later"],
                gigs: []
            )
        }
        
        let gigCount = matchingGigs.count
        let topGigs = Array(matchingGigs.prefix(3))
        
        var message = ""
        
        switch intent {
        case "search":
            message = "I found \(gigCount) services that match your request for \(categoryText.lowercased()) services. Here are the top recommendations:"
        case "recommend":
            message = "Based on your request, I'd recommend these \(categoryText.lowercased()) services:"
        case "help":
            message = "I'm here to help! Here are some great \(categoryText.lowercased()) services I found:"
        default:
            message = "Here are some \(categoryText.lowercased()) services that might interest you:"
        }
        
        let suggestions = generateSuggestions(for: categories, gigs: matchingGigs)
        
        return AIResponse(
            message: message,
            suggestions: suggestions,
            gigs: topGigs
        )
    }
    
    private func generateSuggestions(for categories: [String], gigs: [Gig]) -> [String] {
        var suggestions: [String] = []
        
        // Add category-specific suggestions
        for category in categories {
            switch category {
            case "Creative":
                suggestions.append("Try 'logo design' or 'photography'")
            case "Fitness":
                suggestions.append("Search for 'personal training' or 'yoga'")
            case "Home":
                suggestions.append("Look for 'cleaning' or 'repair' services")
            case "Pet Care":
                suggestions.append("Find 'dog walking' or 'pet training'")
            default:
                suggestions.append("Browse more \(category.lowercased()) services")
            }
        }
        
        // Add general suggestions
        if suggestions.count < 3 {
            suggestions.append("Try different price ranges")
            suggestions.append("Search by location")
        }
        
        return Array(suggestions.prefix(3))
    }
}

struct AIResponse {
    let message: String
    let suggestions: [String]
    let gigs: [Gig]
}

// MARK: - Text Enhancement
extension AIService {
    static func enhance(text: String, completion: @escaping (String) -> Void) {
        let prompt = "Rewrite this service description to make it more appealing and professional while maintaining the original meaning and details:\n\n\(text)"
        
        // For now, we'll use a simple enhancement algorithm
        // In a real app, this would call an OpenAI API endpoint
        let enhanced = enhanceTextLocally(text)
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(enhanced)
        }
    }
    
    private static func enhanceTextLocally(_ text: String) -> String {
        var enhanced = text
        
        // Basic enhancements
        enhanced = enhanced.replacingOccurrences(of: "i ", with: "I ")
        enhanced = enhanced.replacingOccurrences(of: "i'm", with: "I'm")
        enhanced = enhanced.replacingOccurrences(of: "i'll", with: "I'll")
        enhanced = enhanced.replacingOccurrences(of: "i've", with: "I've")
        
        // Add professional phrases if not present
        if !enhanced.lowercased().contains("professional") && !enhanced.lowercased().contains("expert") {
            enhanced = "Professional and experienced service provider. " + enhanced
        }
        
        // Improve sentence structure
        if !enhanced.hasSuffix(".") && !enhanced.hasSuffix("!") && !enhanced.hasSuffix("?") {
            enhanced += "."
        }
        
        // Add call to action if not present
        if !enhanced.lowercased().contains("contact") && !enhanced.lowercased().contains("reach out") {
            enhanced += " Feel free to reach out for more details!"
        }
        
        return enhanced
    }
} 