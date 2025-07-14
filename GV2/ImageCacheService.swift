//
//  ImageCacheService.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Image Cache Service
class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        // Set up cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Configure cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Profile Picture Service
    func fetchProfilePicture(for name: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = "profile_\(name)" as NSString
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        if let diskImage = loadFromDisk(cacheKey: cacheKey) {
            cache.setObject(diskImage, forKey: cacheKey)
            completion(diskImage)
            return
        }
        
        // Fetch from API
        fetchFromAPI(for: name) { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    self?.cache.setObject(image, forKey: cacheKey)
                    self?.saveToDisk(image: image, cacheKey: cacheKey)
                }
                completion(image)
            }
        }
    }
    
    private func fetchFromAPI(for name: String, completion: @escaping (UIImage?) -> Void) {
        // Use Pravatar (realistic human faces) as the primary source
        let apis = [
            // Pravatar - Realistic human faces
            "https://i.pravatar.cc/200?u=\(name.replacingOccurrences(of: " ", with: ""))",

            // RoboHash - Robot avatars (fallback, less realistic)
            "https://robohash.org/\(name.replacingOccurrences(of: " ", with: ""))?size=200x200&set=set4",

            // Dicebear Avataaars - Cartoon avatars (fallback)
            "https://api.dicebear.com/7.x/avataaars/png?seed=\(name.replacingOccurrences(of: " ", with: ""))&size=200&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf"
        ]
        
        fetchFromAPIs(apis: apis, completion: completion)
    }
    
    private func fetchFromAPIs(apis: [String], index: Int = 0, completion: @escaping (UIImage?) -> Void) {
        guard index < apis.count else {
            // All APIs failed, use fallback
            completion(generateFallbackAvatar(for: "User"))
            return
        }
        
        let apiURL = apis[index]
        guard let url = URL(string: apiURL) else {
            fetchFromAPIs(apis: apis, index: index + 1, completion: completion)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                // Try next API
                self.fetchFromAPIs(apis: apis, index: index + 1, completion: completion)
            }
        }.resume()
    }
    
    private func generateFallbackAvatar(for name: String) -> UIImage? {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
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
            
            initials.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - Disk Cache Management
    private func saveToDisk(image: UIImage, cacheKey: NSString) {
        let filename = cacheKey.replacingOccurrences(of: "/", with: "_")
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    private func loadFromDisk(cacheKey: NSString) -> UIImage? {
        let filename = cacheKey.replacingOccurrences(of: "/", with: "_")
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
    
    // MARK: - Cache Management
    func clearCache() {
        cache.removeAllObjects()
        
        // Clear disk cache
        let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        contents?.forEach { url in
            try? fileManager.removeItem(at: url)
        }
    }
    
    func getCacheSize() -> String {
        let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
        let totalSize = contents?.reduce(0) { sum, url in
            let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            return sum + (size ?? 0)
        } ?? 0
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalSize))
    }
} 