import Foundation
import UIKit

class ProductImageService: ObservableObject {
    static let shared = ProductImageService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        // Set up cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ProductImageCache")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Configure cache
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Product Image Generation
    func generateProductImage(for product: Product, completion: @escaping (UIImage?) -> Void) {
        let name = product.name ?? "Unknown Product"
        let description = product.productDescription ?? ""
        
        print("🖼️ Generating image for product: \(name)")
        
        // Get APIs for this specific product
        let apis = getProductImageAPIs(for: name, description: description)
        
        fetchFromMultipleAPIs(apis: apis, product: product) { image in
            if let image = image {
                print("✅ Successfully generated image for: \(name)")
                completion(image)
            } else {
                print("❌ Failed to generate image for: \(name)")
                completion(nil)
            }
        }
    }
    
    private func getProductImageAPIs(for name: String, description: String) -> [String] {
        // Extract general search terms
        let searchTerms = extractSearchTerms(from: name, description: description)
        
        // Generate unique seed for this product to ensure different images
        let productSeed = abs(name.hashValue) % 1000
        let category = searchTerms.primary ?? "product"
        
        // Generate multiple API URLs with different services
        var apis: [String] = []
        
        // Primary search with general category
        if let primary = searchTerms.primary {
            apis.append("https://source.unsplash.com/400x300/?\(primary)")
        }
        
        // Secondary search with broader term
        if let secondary = searchTerms.secondary {
            apis.append("https://source.unsplash.com/400x300/?\(secondary)")
        }
        
        // Fallback to general product
        apis.append("https://source.unsplash.com/400x300/?\(category)")
        
        // Backup APIs with unique seeds for each product
        apis.append("https://picsum.photos/400/300?random=\(productSeed)")
        apis.append("https://loremflickr.com/400/300/\(category)?random=\(productSeed)")
        apis.append("https://via.placeholder.com/400x300/4A90E2/FFFFFF?text=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category)")
        apis.append("https://dummyimage.com/400x300/4A90E2/FFFFFF&text=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category)")
        
        print("🔗 Generated \(apis.count) unique API URLs for product: \(name)")
        return apis
    }
    
    private func extractSearchTerms(from name: String, description: String) -> (primary: String?, secondary: String?, fallback: String?) {
        let text = "\(name) \(description)".lowercased()
        print("🔍 Analyzing text: \(text)")
        
        // Extract specific product keywords from the name and description
        let keywords = extractProductKeywords(from: text)
        print("🔑 Extracted keywords: \(keywords)")
        
        // Generate more specific search terms based on actual product content
        let primary = generateSpecificSearchTerm(keywords: keywords, name: name)
        let secondary = generateCategorySearchTerm(keywords: keywords)
        let fallback = generateFallbackSearchTerm(keywords: keywords, name: name)
        
        print("🎯 Primary search: \(primary ?? "none")")
        print("🎯 Secondary search: \(secondary ?? "none")")
        print("🎯 Fallback search: \(fallback ?? "none")")
        
        return (primary: primary, secondary: secondary, fallback: fallback)
    }
    
    private func extractProductKeywords(from text: String) -> [String] {
        // Remove common words that don't help with image search
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "can", "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them", "my", "your", "his", "her", "its", "our", "their", "mine", "yours", "his", "hers", "ours", "theirs"])
        
        // Split text into words and filter out stop words and short words
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { word in
                word.count > 2 && !stopWords.contains(word) && !word.isEmpty
            }
        
        // Remove duplicates and sort by frequency
        let wordCounts = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return Array(wordCounts.map { $0.key }.prefix(5)) // Take top 5 most frequent words
    }
    
    private func generateSpecificSearchTerm(keywords: [String], name: String) -> String? {
        guard !keywords.isEmpty else { return nil }
        
        // Use the most specific keywords from the product name and description
        let specificKeywords = keywords.prefix(3).joined(separator: ",")
        return specificKeywords.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    private func generateCategorySearchTerm(keywords: [String]) -> String? {
        guard !keywords.isEmpty else { return nil }
        
        // Map keywords to broader but still relevant categories
        let categoryMap: [String: String] = [
            // Flowers and plants
            "rose": "rose flower",
            "tulip": "tulip flower", 
            "orchid": "orchid flower",
            "succulent": "succulent plant",
            "flower": "flower bouquet",
            "plant": "indoor plant",
            
            // Home decor
            "lamp": "table lamp",
            "pillow": "decorative pillow",
            "cushion": "home cushion",
            "vase": "flower vase",
            "mirror": "wall mirror",
            "clock": "wall clock",
            "decor": "home decoration",
            
            // Electronics
            "wireless": "wireless device",
            "bluetooth": "bluetooth speaker",
            "usb": "usb charger",
            "charger": "phone charger",
            "headphones": "wireless headphones",
            "speaker": "portable speaker",
            
            // Beauty
            "makeup": "cosmetic makeup",
            "cream": "beauty cream",
            "nail": "nail polish",
            "hair": "hair care",
            "brush": "makeup brush",
            "cosmetic": "beauty product",
            
            // Fashion
            "wallet": "leather wallet",
            "scarf": "fashion scarf",
            "sunglasses": "designer sunglasses",
            "watch": "wrist watch",
            "jewelry": "fashion jewelry",
            "bag": "handbag purse",
            
            // Pet supplies
            "pet": "pet supplies",
            "dog": "dog toy",
            "cat": "cat toy",
            "bed": "pet bed",
            "toy": "pet toy",
            "leash": "dog leash",
            
            // Art and crafts
            "art": "artwork painting",
            "painting": "canvas painting",
            "drawing": "art drawing",
            "craft": "handmade craft",
            "handmade": "handcrafted item",
            
            // Food
            "food": "fresh food",
            "cake": "homemade cake",
            "bread": "fresh bread",
            "cooking": "cooked food",
            "baking": "baked goods",
            "honey": "natural honey",
            "coffee": "coffee beans"
        ]
        
        // Find the most specific category match
        for keyword in keywords {
            if let category = categoryMap[keyword] {
                return category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            }
        }
        
        // If no specific match, use the first keyword with a descriptive modifier
        if let firstKeyword = keywords.first {
            return "\(firstKeyword) product".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        
        return nil
    }
    
    private func generateFallbackSearchTerm(keywords: [String], name: String) -> String? {
        guard !keywords.isEmpty else { return nil }
        
        // Use the most distinctive keyword from the product name
        let distinctiveKeywords = keywords.filter { keyword in
            // Prefer longer, more specific words
            keyword.count > 4 && !["item", "product", "thing", "stuff"].contains(keyword)
        }
        
        if let bestKeyword = distinctiveKeywords.first {
            return bestKeyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        
        // Fallback to first keyword
        return keywords.first?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    private func detectProductCategory(from name: String, description: String) -> String {
        let text = "\(name) \(description)".lowercased()
        
        // More specific category detection based on actual product content
        if text.contains("rose") || text.contains("tulip") || text.contains("orchid") || text.contains("succulent") {
            return "flower"
        }
        if text.contains("lamp") || text.contains("pillow") || text.contains("cushion") || text.contains("vase") || text.contains("mirror") || text.contains("clock") {
            return "home decor"
        }
        if text.contains("wireless") || text.contains("bluetooth") || text.contains("usb") || text.contains("charger") || text.contains("headphones") || text.contains("speaker") {
            return "electronics"
        }
        if text.contains("makeup") || text.contains("cream") || text.contains("nail") || text.contains("hair") || text.contains("brush") {
            return "beauty"
        }
        if text.contains("wallet") || text.contains("scarf") || text.contains("sunglasses") || text.contains("watch") || text.contains("jewelry") || text.contains("bag") {
            return "fashion"
        }
        if text.contains("pet") || text.contains("dog") || text.contains("cat") || text.contains("bed") || text.contains("toy") || text.contains("leash") {
            return "pet supplies"
        }
        if text.contains("art") || text.contains("painting") || text.contains("drawing") || text.contains("craft") || text.contains("handmade") {
            return "art"
        }
        if text.contains("food") || text.contains("cake") || text.contains("bread") || text.contains("cooking") || text.contains("baking") || text.contains("honey") || text.contains("coffee") {
            return "food"
        }
        
        return "product"
    }
    
    private func getSecondaryTerm(for category: String) -> String {
        switch category {
        case "flower": return "plant"
        case "home decor": return "furniture"
        case "electronics": return "technology"
        case "beauty": return "cosmetics"
        case "fashion": return "accessories"
        case "pet": return "animal"
        case "art": return "creative"
        case "food": return "cooking"
        default: return "item"
        }
    }
    
    private func generatePrimarySearch(_ keywords: [String]) -> String? {
        guard !keywords.isEmpty else { return nil }
        
        // Use the most specific keywords for primary search
        let specificKeywords = keywords.prefix(3).joined(separator: ",")
        return specificKeywords.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    private func generateSecondarySearch(_ keywords: [String]) -> String? {
        guard keywords.count > 1 else { return nil }
        
        // Use broader category terms for secondary search
        let categoryKeywords = getCategoryKeywords(from: keywords)
        return categoryKeywords.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    private func generateFallbackSearch(_ keywords: [String]) -> String? {
        guard !keywords.isEmpty else { return nil }
        
        // Use the most common keyword for fallback
        let fallbackKeyword = keywords.first ?? "product"
        return fallbackKeyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    private func getCategoryKeywords(from keywords: [String]) -> String {
        // Map specific keywords to broader category terms
        let categoryMap: [String: String] = [
            "lamp": "lighting,home decor",
            "pillow": "cushion,home decor",
            "clock": "timepiece,home decor",
            "wireless": "electronics,technology",
            "bluetooth": "electronics,technology",
            "makeup": "beauty,cosmetics",
            "cream": "skincare,beauty",
            "wallet": "accessories,fashion",
            "scarf": "accessories,fashion",
            "pet": "animals,pet supplies",
            "dog": "animals,pet supplies",
            "flower": "plants,home decor",
            "bread": "baking,food",
            "honey": "natural,food",
            "coffee": "beverage,food"
        ]
        
        for keyword in keywords {
            if let category = categoryMap[keyword] {
                return category
            }
        }
        
        // Default category mapping
        if keywords.contains(where: { ["lamp", "pillow", "clock", "decor", "furniture"].contains($0) }) {
            return "home decor,furniture"
        } else if keywords.contains(where: { ["wireless", "bluetooth", "usb", "phone"].contains($0) }) {
            return "electronics,technology"
        } else if keywords.contains(where: { ["makeup", "cream", "nail", "hair"].contains($0) }) {
            return "beauty,cosmetics"
        } else if keywords.contains(where: { ["wallet", "scarf", "sunglasses", "watch"].contains($0) }) {
            return "fashion,accessories"
        } else if keywords.contains(where: { ["pet", "dog", "cat"].contains($0) }) {
            return "animals,pet supplies"
        } else if keywords.contains(where: { ["flower", "plant", "art"].contains($0) }) {
            return "plants,home decor"
        } else if keywords.contains(where: { ["bread", "honey", "coffee", "chocolate"].contains($0) }) {
            return "food,baking"
        }
        
        return "product"
    }
    
    private func categorizeProduct(name: String, description: String) -> String {
        let text = "\(name) \(description)".lowercased()
        
        if text.contains("home") || text.contains("garden") || text.contains("decor") || text.contains("lamp") || text.contains("pillow") || text.contains("clock") || text.contains("furniture") {
            return "home"
        } else if text.contains("tech") || text.contains("phone") || text.contains("wireless") || text.contains("bluetooth") || text.contains("usb") || text.contains("electronics") {
            return "tech"
        } else if text.contains("beauty") || text.contains("makeup") || text.contains("cream") || text.contains("nail") || text.contains("hair") || text.contains("cosmetic") {
            return "beauty"
        } else if text.contains("fashion") || text.contains("wallet") || text.contains("scarf") || text.contains("sunglasses") || text.contains("watch") || text.contains("accessory") {
            return "fashion"
        } else if text.contains("pet") || text.contains("dog") || text.contains("cat") || text.contains("animal") {
            return "pet"
        } else if text.contains("art") || text.contains("craft") || text.contains("flower") || text.contains("rose") || text.contains("succulent") || text.contains("tulip") || text.contains("orchid") {
            return "art"
        } else if text.contains("food") || text.contains("bread") || text.contains("honey") || text.contains("coffee") || text.contains("chocolate") || text.contains("cooking") || text.contains("baking") {
            return "food"
        } else {
            return "general"
        }
    }
    
    private func fetchFromMultipleAPIs(apis: [String], product: Product, completion: @escaping (UIImage?) -> Void) {
        print("🌐 Fetching from \(apis.count) APIs")
        
        // Try each API in sequence until one succeeds
        fetchFromAPIs(apis: apis, index: 0, product: product, completion: completion)
    }
    
    private func fetchFromAPIs(apis: [String], index: Int, product: Product, completion: @escaping (UIImage?) -> Void) {
        guard index < apis.count else {
            print("❌ All APIs failed, generating unique local fallback image for: \(product.name ?? "Unknown")")
            // Generate a unique local fallback image as ultimate backup
            let fallbackImage = generateLocalFallbackImage(for: product)
            completion(fallbackImage)
            return
        }
        
        let apiURL = apis[index]
        print("🌐 Trying API \(index + 1)/\(apis.count): \(apiURL)")
        
        guard let url = URL(string: apiURL) else {
            print("❌ Invalid URL: \(apiURL)")
            fetchFromAPIs(apis: apis, index: index + 1, product: product, completion: completion)
            return
        }
        
        // Create a URLSession task with timeout
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error for API \(index + 1): \(error.localizedDescription)")
                    self.fetchFromAPIs(apis: apis, index: index + 1, product: product, completion: completion)
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    print("❌ Invalid image data from API \(index + 1)")
                    self.fetchFromAPIs(apis: apis, index: index + 1, product: product, completion: completion)
                    return
                }
                
                print("✅ Successfully fetched image from API \(index + 1) for: \(product.name ?? "Unknown")")
                completion(image)
            }
        }
        
        task.resume()
    }
    
    private func generateLocalFallbackImage() -> UIImage {
        print("🎨 Generating local fallback image")
        
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Background gradient with more vibrant colors
            let colors = [
                UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor,
                UIColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1.0).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
            
            // Add subtle pattern overlay
            let patternColor = UIColor.white.withAlphaComponent(0.1)
            context.cgContext.setFillColor(patternColor.cgColor)
            
            for i in stride(from: 0, to: size.width, by: 20) {
                for j in stride(from: 0, to: size.height, by: 20) {
                    let rect = CGRect(x: i, y: j, width: 2, height: 2)
                    context.cgContext.fillEllipse(in: rect)
                }
            }
            
            // Product icon with better styling
            let iconSize: CGFloat = 100
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2 - 30,
                width: iconSize,
                height: iconSize
            )
            
            // Use a more appropriate icon
            let icon = UIImage(systemName: "cube.box.fill") ?? UIImage(systemName: "photo") ?? UIImage(systemName: "star.fill")!
            icon.withTintColor(.white, renderingMode: .alwaysOriginal)
                .draw(in: iconRect)
            
            // Add a subtle shadow effect
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.3).cgColor)
            
            // Text with better styling
            let text = "Product Image"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: iconRect.maxY + 20,
                width: textSize.width,
                height: textSize.height
            )
            
            // Remove shadow for text
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            text.draw(in: textRect, withAttributes: attributes)
            
            // Add a subtle border
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.stroke(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        return image
    }
    
    private func generateLocalFallbackImage(for product: Product) -> UIImage {
        print("🎨 Generating unique local fallback image for: \(product.name ?? "Unknown")")
        
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        // Generate unique colors based on product name
        let nameHash = abs((product.name ?? "Unknown").hashValue)
        let hue1 = CGFloat(nameHash % 360) / 360.0
        let hue2 = CGFloat((nameHash + 180) % 360) / 360.0
        
        let image = renderer.image { context in
            // Background gradient with unique colors based on product name
            let colors = [
                UIColor(hue: hue1, saturation: 0.7, brightness: 0.9, alpha: 1.0).cgColor,
                UIColor(hue: hue2, saturation: 0.8, brightness: 0.7, alpha: 1.0).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Add product name as text
            let productName = product.name ?? "Product"
            let text = "\(productName.prefix(15))"
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
            
            // Add a subtle pattern overlay
            let patternColor = UIColor.white.withAlphaComponent(0.1)
            patternColor.setFill()
            
            for i in stride(from: 0, to: size.width, by: 20) {
                for j in stride(from: 0, to: size.height, by: 20) {
                    let rect = CGRect(x: i, y: j, width: 2, height: 2)
                    context.cgContext.fillEllipse(in: rect)
                }
            }
        }
        
        return image
    }
    
    // MARK: - Cache Management
    func clearCache() {
        cache.removeAllObjects()
        
        // Clear file cache
        let fileURLs = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        fileURLs?.forEach { url in
            try? fileManager.removeItem(at: url)
        }
    }
    
    func getCacheSize() -> Int {
        let fileURLs = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
        return fileURLs?.reduce(0) { total, url in
            let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            return total + (size ?? 0)
        } ?? 0
    }
} 