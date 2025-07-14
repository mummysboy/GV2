import SwiftUI
import CoreData

struct ProductMarketplaceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default)
    private var products: FetchedResults<Product>
    
    @State private var showingAIChat = false
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedProduct: Product?
    
    let categories = ["All", "🛍️ Products", "🏠 Home & Garden", "💻 Tech & Gadgets", "💄 Beauty & Health", "👕 Fashion & Style", "🐕 Pet Supplies", "🎨 Art & Crafts"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Chat Assistant Button
                    Button(action: { showingAIChat = true }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.appAccent)
                            Text("Ask AI to find products...")
                                .foregroundColor(.appTextSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.appSurfaceSecondary)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Product Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(selectedCategory == category ? Color.appAccent : Color.appSurfaceSecondary)
                                        .foregroundColor(selectedCategory == category ? .white : .appText)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedCategory == category ? Color.clear : Color.appBorder, lineWidth: 1)
                                        )
                                        .shadow(color: selectedCategory == category ? .appAccent.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    // Products Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredProducts, id: \.id) { product in
                            ProductCard(product: product) {
                                selectedProduct = product
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Shop")
            .sheet(isPresented: $showingAIChat) {
                ProductAIChatView()
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
            }
        }
        .onAppear {
            loadSampleDataIfNeeded()
        }
    }
    
    // TODO: Replace with actual location/zip filtering if available
    var filteredProducts: [Product] {
        let allProducts = Array(products)
        let filteredByCategory = selectedCategory == "All" ? allProducts : allProducts.filter { product in
            let category = getCategoryForProduct(product)
            return category == selectedCategory
        }
        if searchText.isEmpty {
            return filteredByCategory
        } else {
            return filteredByCategory.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) || ($0.productDescription ?? "").localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func getCategoryForProduct(_ product: Product) -> String {
        let name = product.name?.lowercased() ?? ""
        let description = product.productDescription?.lowercased() ?? ""
        
        if name.contains("home") || name.contains("garden") || name.contains("decor") || name.contains("lamp") || name.contains("pillow") || name.contains("clock") || description.contains("home") || description.contains("garden") || description.contains("decor") {
            return "🏠 Home & Garden"
        } else if name.contains("tech") || name.contains("phone") || name.contains("wireless") || name.contains("bluetooth") || name.contains("usb") || description.contains("tech") || description.contains("wireless") || description.contains("bluetooth") {
            return "💻 Tech & Gadgets"
        } else if name.contains("beauty") || name.contains("makeup") || name.contains("cream") || name.contains("nail") || name.contains("hair") || description.contains("beauty") || description.contains("makeup") || description.contains("cream") {
            return "💄 Beauty & Health"
        } else if name.contains("fashion") || name.contains("wallet") || name.contains("scarf") || name.contains("sunglasses") || name.contains("watch") || description.contains("fashion") || description.contains("accessory") {
            return "👕 Fashion & Style"
        } else if name.contains("pet") || name.contains("dog") || name.contains("cat") || description.contains("pet") || description.contains("dog") || description.contains("cat") {
            return "🐕 Pet Supplies"
        } else if name.contains("art") || name.contains("craft") || name.contains("flower") || name.contains("rose") || name.contains("succulent") || name.contains("tulip") || name.contains("orchid") || description.contains("art") || description.contains("craft") || description.contains("flower") {
            return "🎨 Art & Crafts"
        } else {
            return "🛍️ Products"
        }
    }
    
    private func loadSampleDataIfNeeded() {
        // Load sample data if we have fewer than 10 products (to avoid duplicates)
        if products.count < 10 {
            loadSampleProducts()
        }
    }
    
    private func loadSampleProducts() {
        print("📦 Loading sample products...")
        
        let sampleProducts = [
            // Flowers and Plants
            ("Fresh Roses Bouquet", "Beautiful hand-picked roses, perfect for any occasion. Available in red, pink, and white.", 45.99, "Creative"),
            ("Succulent Garden", "Low-maintenance succulent collection in decorative ceramic pots. Perfect for home or office.", 28.50, "Home"),
            ("Tulip Bulbs Pack", "Spring tulip bulbs ready for planting. Includes 20 bulbs in assorted colors.", 15.99, "Creative"),
            ("Orchid Plant", "Elegant Phalaenopsis orchid in bloom. Comes with care instructions.", 65.00, "Home"),
            
            // Tech Products
            ("Wireless Earbuds", "High-quality wireless earbuds with noise cancellation and 20-hour battery life.", 89.99, "Tech"),
            ("Phone Stand", "Adjustable aluminum phone stand perfect for video calls and hands-free viewing.", 24.99, "Tech"),
            ("USB-C Cable Pack", "Set of 3 durable USB-C cables in different lengths. Fast charging compatible.", 19.99, "Tech"),
            ("Bluetooth Speaker", "Portable waterproof speaker with 360-degree sound and 12-hour battery.", 79.99, "Tech"),
            
            // Home Decor
            ("Vintage Wall Clock", "Handcrafted wooden wall clock with a rustic design. Perfect for farmhouse decor.", 125.00, "Home"),
            ("Throw Pillow Set", "Set of 4 decorative throw pillows in various patterns. 18x18 inches.", 45.99, "Home"),
            ("Table Lamp", "Modern LED table lamp with adjustable brightness and warm light setting.", 67.50, "Home"),
            ("Wall Art Print", "Abstract canvas print, 24x36 inches. Ready to hang with included hardware.", 89.99, "Creative"),
            
            // Pet Care
            ("Pet Bed", "Comfortable memory foam pet bed with removable cover. Available in multiple sizes.", 55.99, "Pet Care"),
            ("Cat Tree", "Multi-level cat tree with scratching posts and hanging toys.", 129.99, "Pet Care"),
            ("Dog Leash", "Durable leather dog leash with comfortable handle and secure clasp.", 34.99, "Pet Care"),
            ("Pet Food Bowl Set", "Stainless steel food and water bowl set with non-slip base.", 22.50, "Pet Care"),
            
            // Beauty Products
            ("Natural Face Cream", "Organic face cream with aloe vera and vitamin E. Suitable for all skin types.", 38.99, "Beauty"),
            ("Makeup Brush Set", "Professional 12-piece makeup brush set with carrying case.", 49.99, "Beauty"),
            ("Hair Dryer", "Ionic hair dryer with multiple heat settings and concentrator attachment.", 89.99, "Beauty"),
            ("Nail Polish Set", "Set of 6 long-lasting nail polishes in trendy colors.", 29.99, "Beauty"),
            
            // Fashion
            ("Leather Wallet", "Genuine leather wallet with multiple card slots and RFID protection.", 45.99, "Fashion"),
            ("Silk Scarf", "100% silk scarf with elegant pattern. Perfect accessory for any outfit.", 35.99, "Fashion"),
            ("Sunglasses", "Polarized sunglasses with UV protection and lightweight frame.", 79.99, "Fashion"),
            ("Watch", "Minimalist watch with leather strap and water resistance.", 95.99, "Fashion"),
            
            // Food Items
            ("Artisan Bread", "Freshly baked sourdough bread made with organic ingredients.", 8.99, "Food"),
            ("Honey Jar", "Local raw honey in decorative glass jar. 16 oz.", 12.99, "Food"),
            ("Coffee Beans", "Premium whole bean coffee, medium roast. 1 lb bag.", 18.99, "Food"),
            ("Chocolate Truffles", "Handcrafted chocolate truffles in assorted flavors. 12 pieces.", 24.99, "Food")
        ]
        
        for (name, description, price, category) in sampleProducts {
            let product = Product(context: viewContext)
            product.id = UUID()
            product.name = name
            product.productDescription = description
            product.price = price
            product.ownerId = "sample_user"
            product.createdAt = Date()
            product.updatedAt = Date()
            product.isActive = true
        }
        
        // Save to Core Data
        do {
            try viewContext.save()
            print("✅ Successfully saved \(sampleProducts.count) sample products")
        } catch {
            print("❌ Error saving sample products: \(error)")
        }
    }
}

struct ProductCard: View {
    let product: Product
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Product image using new ProductImageView
                ProductImageView(
                    product: product,
                    size: CGSize(width: 200, height: 120),
                    cornerRadius: 12
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name ?? "Unknown Product")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(product.productDescription ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                                                        .foregroundColor(.appAccent)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProductDetailView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product image using new ProductImageView
                    ProductImageView(
                        product: product,
                        size: CGSize(width: UIScreen.main.bounds.width - 32, height: 300),
                        cornerRadius: 16
                    )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Product name and price
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(product.name ?? "Unknown Product")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("$\(String(format: "%.2f", product.price))")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // TODO: Add to favorites
                            }) {
                                Image(systemName: "heart")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Product description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(product.productDescription ?? "No description available.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                // TODO: Implement purchase/contact seller
                            }) {
                                Text("Contact Seller")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                // TODO: Add to cart
                            }) {
                                Text("Add to Cart")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProductDetailModalView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Image
                    if let imagesData = product.images as? [Data],
                       let firstImageData = imagesData.first,
                       let uiImage = UIImage(data: firstImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(16)
                    }
                    // Product Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name ?? "Untitled Product")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(String(format: "$%.2f", product.price))
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                        Text(product.productDescription ?? "No description")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    // Owner Info
                    if let owner = product.owner {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(owner.name?.prefix(1) ?? "U"))
                                        .font(.headline)
                                        .foregroundColor(.purple)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(owner.name ?? "Unknown Seller")
                                    .font(.headline)
                                Text(owner.location ?? "Location")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProductMarketplaceView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 