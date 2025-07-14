import SwiftUI

struct ProductImageView: View {
    let product: Product
    let size: CGSize
    let cornerRadius: CGFloat
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasError = false
    
    init(product: Product, size: CGSize = CGSize(width: 200, height: 150), cornerRadius: CGFloat = 12) {
        self.product = product
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(cornerRadius)
                    .shadow(color: .appShadow, radius: 4, x: 0, y: 2)
            } else if isLoading {
                // Loading placeholder
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.appSurfaceSecondary)
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .appAccent))
                            
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                    )
                    .shadow(color: .appShadow, radius: 4, x: 0, y: 2)
            } else if hasError {
                // Error placeholder
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.appSurfaceSecondary)
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.appTextSecondary)
                            
                            Text("No Image")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                    )
                    .shadow(color: .appShadow, radius: 4, x: 0, y: 2)
            }
        }
        .onAppear {
            loadProductImage()
        }
    }
    
    private func loadProductImage() {
        print("🖼️ Loading image for product: \(product.name ?? "Unknown")")
        
        // Check if product.images contains valid, non-empty image data
        if let imagesData = product.images as? [Data],
           let firstImageData = imagesData.first,
           !firstImageData.isEmpty,
           let uiImage = UIImage(data: firstImageData) {
            print("✅ Found existing image for: \(product.name ?? "Unknown")")
            self.image = uiImage
            self.isLoading = false
            return
        }
        
        print("🔄 No valid existing image found, fetching from API for: \(product.name ?? "Unknown")")
        
        // If no valid existing images, fetch from API
        isLoading = true
        ProductImageService.shared.generateProductImage(for: product) { fetchedImage in
            DispatchQueue.main.async {
                if let fetchedImage = fetchedImage {
                    print("✅ Successfully fetched image for: \(self.product.name ?? "Unknown")")
                    self.image = fetchedImage
                    self.isLoading = false
                    self.hasError = false
                    // Save the fetched image to the product
                    self.saveImageToProduct(fetchedImage)
                } else {
                    print("❌ Failed to fetch image, using placeholder for: \(self.product.name ?? "Unknown")")
                    self.image = nil
                    self.isLoading = false
                    self.hasError = true
                }
            }
        }
    }
    
    private func saveImageToProduct(_ image: UIImage) {
        // Convert image to data and save to product
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let imagesArray = [imageData] as NSObject
            product.images = imagesArray
            
            // Save to Core Data on main thread
            DispatchQueue.main.async {
                do {
                    try self.product.managedObjectContext?.save()
                    print("✅ Successfully saved image to Core Data for: \(self.product.name ?? "Unknown")")
                } catch {
                    print("❌ Error saving product image to Core Data: \(error)")
                }
            }
        }
    }
    
    private func getPlaceholderImage(for product: Product) -> UIImage? {
        // Create a simple colored rectangle as placeholder
        let size = CGSize(width: 200, height: 150)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        // Get a color based on product category
        let color = getColorForProduct(product)
        color.setFill()
        
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(rect)
        
        // Add text
        let text = product.name?.prefix(1).uppercased() ?? "P"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func getColorForProduct(_ product: Product) -> UIColor {
        let name = product.name?.lowercased() ?? ""
        let description = product.productDescription?.lowercased() ?? ""
        let text = "\(name) \(description)"
        
        if text.contains("home") || text.contains("garden") || text.contains("decor") || text.contains("lamp") || text.contains("pillow") {
            return UIColor.systemGreen
        } else if text.contains("tech") || text.contains("wireless") || text.contains("bluetooth") || text.contains("phone") {
            return UIColor.systemBlue
        } else if text.contains("beauty") || text.contains("makeup") || text.contains("cream") {
            return UIColor.systemPink
        } else if text.contains("fashion") || text.contains("wallet") || text.contains("scarf") {
            return UIColor.systemPurple
        } else if text.contains("pet") || text.contains("dog") || text.contains("cat") {
            return UIColor.systemOrange
        } else if text.contains("flower") || text.contains("plant") || text.contains("art") {
            return UIColor.systemTeal
        } else if text.contains("food") || text.contains("bread") || text.contains("coffee") {
            return UIColor.systemBrown
        } else {
            return UIColor.systemGray
        }
    }
}

// MARK: - Product Image Grid View
struct ProductImageGridView: View {
    let products: [Product]
    let columns: [GridItem]
    
    init(products: [Product], columns: Int = 2) {
        self.products = products
        self.columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(products, id: \.id) { product in
                ProductImageView(product: product)
            }
        }
    }
}

// MARK: - Product Image Carousel
struct ProductImageCarousel: View {
    let products: [Product]
    let height: CGFloat
    
    @State private var currentIndex = 0
    
    init(products: [Product], height: CGFloat = 200) {
        self.products = products
        self.height = height
    }
    
    var body: some View {
        if products.isEmpty {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurfaceSecondary)
                .frame(height: height)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.appTextSecondary)
                        
                        Text("No Products")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                )
        } else {
            TabView(selection: $currentIndex) {
                ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                    ProductImageView(
                        product: product,
                        size: CGSize(width: UIScreen.main.bounds.width - 32, height: height),
                        cornerRadius: 12
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: height)
        }
    }
} 