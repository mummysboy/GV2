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
        // First check if product already has images
        if let imagesData = product.images as? [Data],
           let firstImageData = imagesData.first,
           let uiImage = UIImage(data: firstImageData) {
            self.image = uiImage
            self.isLoading = false
            return
        }
        
        // If no existing images, fetch from API
        isLoading = true
        hasError = false
        
        ProductImageService.shared.generateProductImage(for: product) { fetchedImage in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let fetchedImage = fetchedImage {
                    self.image = fetchedImage
                    self.hasError = false
                    
                    // Save the fetched image to the product
                    self.saveImageToProduct(fetchedImage)
                } else {
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
            
            // Save to Core Data
            do {
                try product.managedObjectContext?.save()
            } catch {
                print("Error saving product image: \(error)")
            }
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