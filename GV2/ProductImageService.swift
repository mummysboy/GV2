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
        // Categorize product and return appropriate image APIs
        let category = categorizeProduct(name: name, description: description)
        
        switch category {
        case "home":
            return [
                "https://source.unsplash.com/400x300/?home,decor,furniture",
                "https://source.unsplash.com/400x300/?interior,design",
                "https://picsum.photos/400/300?random=\(name.hashValue)"
            ]
        case "tech":
            return [
                "https://source.unsplash.com/400x300/?technology,gadgets",
                "https://source.unsplash.com/400x300/?electronics,devices",
                "https://picsum.photos/400/300?random=\(name.hashValue + 1)"
            ]
        case "beauty":
            return [
                "https://source.unsplash.com/400x300/?beauty,cosmetics",
                "https://source.unsplash.com/400x300/?makeup,skincare",
                "https://picsum.photos/400/300?random=\(name.hashValue + 2)"
            ]
        case "fashion":
            return [
                "https://source.unsplash.com/400x300/?fashion,clothing",
                "https://source.unsplash.com/400x300/?accessories,style",
                "https://picsum.photos/400/300?random=\(name.hashValue + 3)"
            ]
        case "pet":
            return [
                "https://source.unsplash.com/400x300/?pet,animals",
                "https://source.unsplash.com/400x300/?dogs,cats",
                "https://picsum.photos/400/300?random=\(name.hashValue + 4)"
            ]
        case "art":
            return [
                "https://source.unsplash.com/400x300/?art,crafts",
                "https://source.unsplash.com/400x300/?flowers,plants",
                "https://picsum.photos/400/300?random=\(name.hashValue + 5)"
            ]
        case "food":
            return [
                "https://source.unsplash.com/400x300/?food,cooking",
                "https://source.unsplash.com/400x300/?baking,ingredients",
                "https://picsum.photos/400/300?random=\(name.hashValue + 6)"
            ]
        default:
            return [
                "https://source.unsplash.com/400x300/?product",
                "https://picsum.photos/400/300?random=\(name.hashValue + 7)"
            ]
        }
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