import SwiftUI
import CoreData

struct ProductAIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default)
    private var products: FetchedResults<Product>
    
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var aiResults: [Product] = []
    @State private var selectedProduct: Product? = nil
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp = Date()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding(10)
                                        .background(Color.purple.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                } else {
                                    Text(message.text)
                                        .padding(10)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    Spacer()
                                }
                            }
                        }
                        if !aiResults.isEmpty {
                            Text("Found \(aiResults.count) product(s):")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(aiResults, id: \.id) { product in
                                        ProductCard(product: product, onTap: { selectedProduct = product })
                                            .frame(width: 160)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                HStack {
                    TextField("Ask about products...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isLoading)
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.purple)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("Product AI Assistant")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
            }
        }
    }
    
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(text: trimmed, isUser: true))
        messageText = ""
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let results = searchProducts(for: trimmed)
            aiResults = results
            let productNames = results.map { $0.name ?? "Unnamed" }
            let response: String
            if results.isEmpty {
                response = "Sorry, I couldn't find any products matching your search."
            } else {
                response = "I found some products that match your search for '\(trimmed)': \(productNames.joined(separator: ", ")). Check them out above!"
            }
            messages.append(ChatMessage(text: response, isUser: false))
            isLoading = false
        }
    }
    
    private func searchProducts(for query: String) -> [Product] {
        let lowercasedQuery = query.lowercased()
        var keywords: [String] = []
        // Basic keyword extraction for flowers
        if lowercasedQuery.contains("flower") || lowercasedQuery.contains("bouquet") {
            keywords = ["flower", "flowers", "bouquet", "rose", "roses", "tulip", "tulips", "orchid", "orchids", "succulent", "succulents", "plant", "plants"]
        } else {
            // Split query into words, filter out stopwords
            let stopwords = ["i", "need", "want", "find", "show", "me", "a", "an", "the", "for", "of", "to", "and", "or", "about"]
            keywords = lowercasedQuery.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                .filter { !$0.isEmpty && !stopwords.contains($0) }
        }
        guard !keywords.isEmpty else { return [] }
        return products.filter { product in
            let name = (product.name ?? "").lowercased()
            let desc = (product.productDescription ?? "").lowercased()
            return keywords.contains { keyword in
                name.contains(keyword) || desc.contains(keyword)
            }
        }
    }
}

// ProductCard is already defined in ProductMarketplaceView.swift 