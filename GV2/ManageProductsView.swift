import SwiftUI
import CoreData
import PhotosUI

struct ManageProductsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.createdAt, ascending: false)],
        animation: .default)
    private var products: FetchedResults<Product>
    
    @State private var showingAddProductSheet = false
    @State private var searchText = ""
    @State private var sortOption = SortOption.newest
    @State private var showingDeleteAlert = false
    @State private var productToDelete: Product?
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case priceHighToLow = "Price: High to Low"
        case priceLowToHigh = "Price: Low to High"
        case nameAZ = "Name: A-Z"
        case nameZA = "Name: Z-A"
    }
    
    var filteredAndSortedProducts: [Product] {
        let filtered = products.filter { product in
            searchText.isEmpty || 
            (product.name?.localizedCaseInsensitiveContains(searchText) == true) ||
            (product.productDescription?.localizedCaseInsensitiveContains(searchText) == true)
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .newest:
                return (first.createdAt ?? Date.distantPast) > (second.createdAt ?? Date.distantPast)
            case .oldest:
                return (first.createdAt ?? Date.distantPast) < (second.createdAt ?? Date.distantPast)
            case .priceHighToLow:
                return first.price > second.price
            case .priceLowToHigh:
                return first.price < second.price
            case .nameAZ:
                return (first.name ?? "") < (second.name ?? "")
            case .nameZA:
                return (first.name ?? "") > (second.name ?? "")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Sort Bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search products...", text: $searchText)
                    }
                    .padding()
                    .background(Color.appGrayLight)
                    .cornerRadius(12)
                    
                    HStack {
                        Text("Sort by:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Spacer()
                        
                        Text("\(filteredAndSortedProducts.count) products")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Products List
                if filteredAndSortedProducts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bag")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "No products yet" : "No products found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty {
                            Text("Start selling by adding your first product")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredAndSortedProducts, id: \.id) { product in
                                ProductRowView(product: product) {
                                    productToDelete = product
                                    showingDeleteAlert = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Manage Products")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProductSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddProductSheet) {
            AddProductView()
        }
        .alert("Delete Product", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let product = productToDelete {
                    deleteProduct(product)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this product? This action cannot be undone.")
        }
    }
    
    private func deleteProduct(_ product: Product) {
        viewContext.delete(product)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting product: \(error)")
        }
    }
}

struct ProductRowView: View {
    let product: Product
    let onDelete: () -> Void
    
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            if let imagesData = product.images as? [Data],
               let firstImageData = imagesData.first,
               let uiImage = UIImage(data: firstImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appGrayLight)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "bag")
                            .foregroundColor(.appAccent)
                    )
            }
            
            // Product Details
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name ?? "Untitled Product")
                    .font(.headline)
                    .lineLimit(1)
                
                Text(product.productDescription ?? "No description")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(String(format: "$%.2f", product.price))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                                            .foregroundColor(.appAccent)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 8) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.appGrayLight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingEditSheet) {
            AddProductView(productToEdit: product)
        }
    }
}

#Preview {
    ManageProductsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 