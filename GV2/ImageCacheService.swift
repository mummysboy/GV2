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
    
    private init() {
        // Configure memory cache
        cache.countLimit = 100 // Maximum number of images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Setup disk cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Clean up old cache files on app launch
        cleanupOldCache()
    }
    
    // MARK: - Public Methods
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = NSString(string: url.absoluteString)
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: key) {
            completion(cachedImage)
            return
        }
        
        // Check disk cache
        if let diskImage = loadFromDisk(url: url) {
            cache.setObject(diskImage, forKey: key)
            completion(diskImage)
            return
        }
        
        // Download and cache
        downloadImage(from: url) { [weak self] image in
            guard let self = self, let image = image else {
                completion(nil)
                return
            }
            
            // Store in memory and disk cache
            self.cache.setObject(image, forKey: key)
            self.saveToDisk(image: image, url: url)
            completion(image)
        }
    }
    
    func preloadImages(from urls: [URL]) {
        for url in urls {
            loadImage(from: url) { _ in }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Private Methods
    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, let image = UIImage(data: data) else {
                    completion(nil)
                    return
                }
                completion(image)
            }
        }.resume()
    }
    
    private func saveToDisk(image: UIImage, url: URL) {
        let filename = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "unknown"
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        DispatchQueue.global(qos: .background).async {
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: fileURL)
            }
        }
    }
    
    private func loadFromDisk(url: URL) -> UIImage? {
        let filename = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "unknown"
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func cleanupOldCache() {
        DispatchQueue.global(qos: .background).async {
            let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
            let now = Date()
            
            guard let contents = try? self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
                return
            }
            
            for fileURL in contents {
                if let attributes = try? self.fileManager.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   now.timeIntervalSince(creationDate) > maxAge {
                    try? self.fileManager.removeItem(at: fileURL)
                }
            }
        }
    }
}

// MARK: - Cached Async Image
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @StateObject private var imageLoader = ImageLoader()
    
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            if let url = url {
                imageLoader.load(url: url)
            }
        }
        .onChange(of: url) { _, newURL in
            if let url = newURL {
                imageLoader.load(url: url)
            }
        }
    }
}

// MARK: - Image Loader
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let cache = ImageCacheService.shared
    
    func load(url: URL) {
        cache.loadImage(from: url) { [weak self] image in
            DispatchQueue.main.async {
                self?.image = image
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func cachedAsyncImage(url: URL?, @ViewBuilder content: @escaping (Image) -> some View) -> some View {
        CachedAsyncImage(url: url, content: content) {
            ProgressView()
        }
    }
    
    func cachedAsyncImage(url: URL?, @ViewBuilder content: @escaping (Image) -> some View, @ViewBuilder placeholder: @escaping () -> some View) -> some View {
        CachedAsyncImage(url: url, content: content, placeholder: placeholder)
    }
} 