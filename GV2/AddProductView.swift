import SwiftUI
import CoreData
import PhotosUI

struct AddProductView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let productToEdit: Product?
    
    @State private var productName = ""
    @State private var productDescription = ""
    @State private var productPrice = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var productImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(productToEdit: Product? = nil) {
        self.productToEdit = productToEdit
    }
    
    var isEditing: Bool {
        productToEdit != nil
    }
    
    var isValidForm: Bool {
        !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !productPrice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(productPrice) != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: isEditing ? "pencil.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        
                        Text(isEditing ? "Edit Product" : "Add New Product")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(isEditing ? "Update your product details" : "Create a new product listing")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Product Images
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Product Images")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Add Image Button
                                PhotosPicker(selection: $selectedImages, maxSelectionCount: 5, matching: .images) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(.purple)
                                        Text("Add Image")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
                                // Display Selected Images
                                ForEach(Array(productImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Button(action: {
                                            productImages.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Product Details Form
                    VStack(spacing: 20) {
                        // Product Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Product Name")
                                .font(.headline)
                            
                            TextField("Enter product name", text: $productName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Product Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            TextEditor(text: $productDescription)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        
                        // Product Price
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Price")
                                .font(.headline)
                            
                            HStack {
                                Text("$")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                
                                TextField("0.00", text: $productPrice)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle(isEditing ? "Edit Product" : "Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Update" : "Save") {
                        saveProduct()
                    }
                    .disabled(!isValidForm)
                }
            }
        }
        .onAppear {
            if let product = productToEdit {
                loadProductData(product)
            }
        }
        .onChange(of: selectedImages) { _ in
            Task {
                await loadImages()
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadProductData(_ product: Product) {
        productName = product.name ?? ""
        productDescription = product.productDescription ?? ""
        productPrice = String(format: "%.2f", product.price)
        
        if let imagesData = product.images as? [Data] {
            productImages = imagesData.compactMap { UIImage(data: $0) }
        }
    }
    
    private func loadImages() async {
        productImages.removeAll()
        
        for item in selectedImages {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                productImages.append(image)
            }
        }
    }
    
    private func saveProduct() {
        guard isValidForm else {
            alertMessage = "Please fill in all required fields with valid data."
            showingAlert = true
            return
        }
        
        guard let price = Double(productPrice) else {
            alertMessage = "Please enter a valid price."
            showingAlert = true
            return
        }
        
        let product: Product
        
        if let existingProduct = productToEdit {
            product = existingProduct
            product.updatedAt = Date()
        } else {
            product = Product(context: viewContext)
            product.id = UUID()
            product.createdAt = Date()
            product.updatedAt = Date()
            product.isActive = true
        }
        
        product.name = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        product.productDescription = productDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        product.price = price
        
        // Convert images to Data array
        let imagesData = productImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        product.images = imagesData as NSObject
        
        // Set owner if creating new product
        if productToEdit == nil {
            // Get current user and set as owner
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            if let currentUser = try? viewContext.fetch(fetchRequest).first {
                product.owner = currentUser
                product.ownerId = currentUser.id?.uuidString
            }
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save product: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    AddProductView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 