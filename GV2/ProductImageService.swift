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
        let productName = product.name?.lowercased() ?? ""
        let productDescription = product.productDescription?.lowercased() ?? ""
        
        // Generate a unique key for this product
        let productKey = "\(productName)_\(productDescription)".replacingOccurrences(of: " ", with: "_")
        
        // Check cache first
        if let cachedImage = cache.object(forKey: productKey as NSString) {
            completion(cachedImage)
            return
        }
        
        // Check file cache
        let cacheKey = productKey.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? productKey
        let cacheURL = cacheDirectory.appendingPathComponent("\(cacheKey).jpg")
        
        if let imageData = try? Data(contentsOf: cacheURL),
           let cachedImage = UIImage(data: imageData) {
            cache.setObject(cachedImage, forKey: productKey as NSString)
            completion(cachedImage)
            return
        }
        
        // Fetch from API based on product category
        fetchProductImage(for: productName, description: productDescription) { [weak self] image in
            guard let self = self, let image = image else {
                completion(nil)
                return
            }
            
            // Cache the image
            self.cache.setObject(image, forKey: productKey as NSString)
            
            // Save to file cache
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try? imageData.write(to: cacheURL)
            }
            
            completion(image)
        }
    }
    
    private func fetchProductImage(for name: String, description: String, completion: @escaping (UIImage?) -> Void) {
        // Determine the best API based on product type
        let apis = getProductImageAPIs(for: name, description: description)
        
        fetchFromAPIs(apis: apis) { image in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    private func getProductImageAPIs(for name: String, description: String) -> [String] {
        // Extract specific keywords from product name and description
        let searchTerms = extractSearchTerms(from: name, description: description)
        
        // Generate multiple API URLs with different search term combinations
        var apis: [String] = []
        
        // Primary search with specific product terms
        if let primarySearch = searchTerms.primary {
            apis.append("https://source.unsplash.com/400x300/?\(primarySearch)")
        }
        
        // Secondary search with broader category terms
        if let secondarySearch = searchTerms.secondary {
            apis.append("https://source.unsplash.com/400x300/?\(secondarySearch)")
        }
        
        // Fallback with general product terms
        if let fallbackSearch = searchTerms.fallback {
            apis.append("https://source.unsplash.com/400x300/?\(fallbackSearch)")
        }
        
        // Final fallback with category
        let category = categorizeProduct(name: name, description: description)
        apis.append("https://source.unsplash.com/400x300/?\(category)")
        
        return apis
    }
    
    private func extractSearchTerms(from name: String, description: String) -> (primary: String?, secondary: String?, fallback: String?) {
        let text = "\(name) \(description)".lowercased()
        
        // Extract specific product keywords
        let productKeywords = extractProductKeywords(from: text)
        
        // Generate search term combinations
        let primary = generatePrimarySearch(productKeywords)
        let secondary = generateSecondarySearch(productKeywords)
        let fallback = generateFallbackSearch(productKeywords)
        
        return (primary: primary, secondary: secondary, fallback: fallback)
    }
    
    private func extractProductKeywords(from text: String) -> [String] {
        var keywords: [String] = []
        
        // Extract specific product types
        let productTypes = [
            "lamp", "pillow", "clock", "decor", "furniture", "cushion", "vase", "mirror",
            "wireless", "bluetooth", "usb", "charger", "headphones", "speaker", "phone",
            "makeup", "cream", "nail", "hair", "brush", "cosmetic", "skincare", "lotion",
            "wallet", "scarf", "sunglasses", "watch", "jewelry", "bag", "shoes", "dress",
            "pet", "dog", "cat", "bed", "toy", "food", "leash", "collar", "bowl",
            "flower", "rose", "succulent", "tulip", "orchid", "plant", "art", "craft",
            "bread", "honey", "coffee", "chocolate", "cake", "cooking", "baking", "food"
        ]
        
        for type in productTypes {
            if text.contains(type) {
                keywords.append(type)
            }
        }
        
        // Extract materials and features
        let materials = [
            "leather", "silk", "cotton", "wood", "metal", "glass", "ceramic", "plastic",
            "memory foam", "stainless steel", "organic", "natural", "premium", "handcrafted"
        ]
        
        for material in materials {
            if text.contains(material) {
                keywords.append(material)
            }
        }
        
        // Extract colors if mentioned
        let colors = [
            "black", "white", "red", "blue", "green", "yellow", "pink", "purple", "brown", "gray"
        ]
        
        for color in colors {
            if text.contains(color) {
                keywords.append(color)
            }
        }
        
        // Specific product matching for better accuracy
        let specificMatches = getSpecificProductMatches(from: text)
        keywords.append(contentsOf: specificMatches)
        
        return keywords
    }
    
    private func getSpecificProductMatches(from text: String) -> [String] {
        var matches: [String] = []
        
        // Home & Garden specific matches
        if text.contains("table lamp") || text.contains("desk lamp") {
            matches.append("table lamp")
        }
        if text.contains("floor lamp") {
            matches.append("floor lamp")
        }
        if text.contains("throw pillow") || text.contains("cushion") {
            matches.append("throw pillow")
        }
        if text.contains("wall clock") {
            matches.append("wall clock")
        }
        if text.contains("vase") {
            matches.append("vase")
        }
        if text.contains("mirror") {
            matches.append("mirror")
        }
        
        // Tech specific matches
        if text.contains("wireless charger") {
            matches.append("wireless charger")
        }
        if text.contains("bluetooth speaker") {
            matches.append("bluetooth speaker")
        }
        if text.contains("usb cable") {
            matches.append("usb cable")
        }
        if text.contains("phone case") {
            matches.append("phone case")
        }
        
        // Beauty specific matches
        if text.contains("face cream") {
            matches.append("face cream")
        }
        if text.contains("makeup brush") {
            matches.append("makeup brush")
        }
        if text.contains("nail polish") {
            matches.append("nail polish")
        }
        if text.contains("hair dryer") {
            matches.append("hair dryer")
        }
        
        // Fashion specific matches
        if text.contains("leather wallet") {
            matches.append("leather wallet")
        }
        if text.contains("silk scarf") {
            matches.append("silk scarf")
        }
        if text.contains("sunglasses") {
            matches.append("sunglasses")
        }
        if text.contains("watch") {
            matches.append("watch")
        }
        
        // Pet specific matches
        if text.contains("pet bed") {
            matches.append("pet bed")
        }
        if text.contains("cat tree") {
            matches.append("cat tree")
        }
        if text.contains("dog leash") {
            matches.append("dog leash")
        }
        if text.contains("pet food bowl") {
            matches.append("pet food bowl")
        }
        
        // Art & Crafts specific matches
        if text.contains("artificial flower") {
            matches.append("artificial flower")
        }
        if text.contains("succulent plant") {
            matches.append("succulent plant")
        }
        if text.contains("rose bouquet") {
            matches.append("rose bouquet")
        }
        if text.contains("tulip") {
            matches.append("tulip")
        }
        if text.contains("orchid") {
            matches.append("orchid")
        }
        
        // Food specific matches
        if text.contains("sourdough bread") {
            matches.append("sourdough bread")
        }
        if text.contains("raw honey") {
            matches.append("raw honey")
        }
        if text.contains("coffee beans") {
            matches.append("coffee beans")
        }
        if text.contains("chocolate truffles") {
            matches.append("chocolate truffles")
        }
        
        return matches
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
    
    private func fetchFromAPIs(apis: [String], completion: @escaping (UIImage?) -> Void) {
        guard !apis.isEmpty else {
            completion(nil)
            return
        }
        
        let currentAPI = apis[0]
        let remainingAPIs = Array(apis.dropFirst())
        
        guard let url = URL(string: currentAPI) else {
            if !remainingAPIs.isEmpty {
                fetchFromAPIs(apis: remainingAPIs, completion: completion)
            } else {
                completion(nil)
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                // Try next API if available
                if !remainingAPIs.isEmpty {
                    self.fetchFromAPIs(apis: remainingAPIs, completion: completion)
                } else {
                    completion(nil)
                }
            }
        }.resume()
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