import SwiftUI
import CoreData
import PhotosUI

struct GigManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Gig.createdAt, ascending: false)],
        animation: .default)
    private var allGigs: FetchedResults<Gig>
    
    // Add computed property to filter gigs for current user
    private var userGigs: [Gig] {
        let currentUser = GigManagementView.currentUser(in: viewContext)
        return allGigs.filter { $0.provider == currentUser }
    }
    
    @State private var selectedFilter = "All"
    @State private var showingCreateGig = false
    @State private var showingGigDetail: Gig?
    @State private var showingDeleteConfirmation = false
    @State private var gigToDelete: Gig?
    @State private var showingPromoteGig = false
    @State private var gigToPromote: Gig?
    
    let filters = ["All", "Live", "Draft", "Paused", "Under Review"]
    
    var filteredGigs: [Gig] {
        switch selectedFilter {
        case "Live":
            return userGigs.filter { $0.isActive == true }
        case "Draft":
            return userGigs.filter { $0.isActive == false }
        case "Paused":
            return userGigs.filter { $0.isActive == false }
        case "Under Review":
            return userGigs.filter { $0.isActive == false }
        default:
            return Array(userGigs)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: { selectedFilter = filter }) {
                                Text(filter)
                                    .font(.caption)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.appAccent : Color.appAccentLight)
                                    .foregroundColor(selectedFilter == filter ? .appWhite : .appAccent)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Gig List
                if filteredGigs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "briefcase")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No gigs found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Create your first gig to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingCreateGig = true }) {
                            Text("Create New Gig")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.appAccent)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredGigs) { gig in
                                GigManagementCard(
                                    gig: gig,
                                    onEdit: { showingGigDetail = gig },
                                    onDelete: {
                                        gigToDelete = gig
                                        showingDeleteConfirmation = true
                                    },
                                    onPromote: {
                                        gigToPromote = gig
                                        showingPromoteGig = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Gigs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGig = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.appAccent)
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateGig) {
            CreateGigView()
        }
        .sheet(item: $showingGigDetail) { gig in
            GigEditView(gig: gig)
        }
        .sheet(isPresented: $showingPromoteGig) {
            if let gig = gigToPromote {
                GigPromoteView(gig: gig)
            }
        }
        .alert("Delete Gig", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let gig = gigToDelete {
                    deleteGig(gig)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this gig? This action cannot be undone.")
        }
    }
    
    private func deleteGig(_ gig: Gig) {
        viewContext.delete(gig)
        try? viewContext.save()
    }
}

extension GigManagementView {
    static func currentUser(in context: NSManagedObjectContext) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

struct GigManagementCard: View {
    let gig: Gig
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPromote: () -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(gig.title ?? "Untitled Gig")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        StatusBadge(status: gig.isActive ? "Live" : "Draft")
                        Text(gig.category ?? "Category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            // Gig content
            Text(gig.gigDescription ?? "No description")
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Engagement stats
            HStack(spacing: 20) {
                EngagementStat(icon: "eye", value: "\(Int.random(in: 50...500))", label: "Views")
                EngagementStat(icon: "message", value: "\(Int.random(in: 2...20))", label: "Messages")
                EngagementStat(icon: "heart", value: "\(Int.random(in: 5...50))", label: "Likes")
                EngagementStat(icon: "calendar", value: "\(Int.random(in: 0...10))", label: "Bookings")
            }
            
            // Price and location
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("$\(String(format: "%.0f", gig.price))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.appAccent)
                    
                    Text(gig.priceType ?? "per service")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(gig.location ?? "Location")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .confirmationDialog("Gig Actions", isPresented: $showingActionSheet) {
            Button("Edit Gig") { onEdit() }
            Button("Promote Gig") { onPromote() }
            Button("Pause Gig") { /* Toggle gig status */ }
            Button("Delete Gig", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        }
    }
}

struct StatusBadge: View {
    let status: String
    
    var statusColor: Color {
        switch status {
        case "Live":
            return .green
        case "Draft":
            return .orange
        case "Paused":
            return .red
        case "Under Review":
            return .blue
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
}

struct EngagementStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.purple)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct GigEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let gig: Gig
    
    @State private var title = ""
    @State private var gigDescription = ""
    @State private var category = ""
    @State private var price = 0.0
    @State private var priceType = ""
    @State private var location = ""
    @State private var tags = ""
    @State private var isActive = true
    @State private var showingImagePicker = false
    @State private var selectedImages: [PhotosPickerItem] = []
    
    let categories = ["Creative", "Home", "Pet Care", "Tutoring", "Fitness", "Food", "Tech", "Beauty", "Transportation", "Other"]
    let priceTypes = ["Fixed", "Per Hour", "Per Day", "Negotiable"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        
                        Text("Edit Gig")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Update your gig details to attract more clients")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        GigEditField(
                            title: "Title",
                            placeholder: "Enter gig title",
                            text: $title
                        )
                        
                        GigEditField(
                            title: "Description",
                            placeholder: "Describe your service...",
                            text: $gigDescription,
                            isMultiline: true
                        )
                        
                        // Category Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                            
                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color.appGrayLight)
                            .cornerRadius(12)
                        }
                        
                        // Price and Price Type
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Price")
                                    .font(.headline)
                                
                                TextField("0", value: $price, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Price Type")
                                    .font(.headline)
                                
                                Picker("Price Type", selection: $priceType) {
                                    ForEach(priceTypes, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding()
                                .background(Color.appGrayLight)
                                .cornerRadius(12)
                            }
                        }
                        
                        GigEditField(
                            title: "Location",
                            placeholder: "City, State or Remote",
                            text: $location
                        )
                        
                        GigEditField(
                            title: "Tags",
                            placeholder: "tag1, tag2, tag3",
                            text: $tags
                        )
                        
                        // Status Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Gig Status")
                                .font(.headline)
                            
                            HStack {
                                Text("Active")
                                    .font(.body)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isActive)
                                    .labelsHidden()
                            }
                            .padding()
                            .background(Color.appGrayLight)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: saveGig) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appAccent)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Edit Gig")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadGigData()
            }
        }
    }
    
    private func loadGigData() {
        title = gig.title ?? ""
        gigDescription = gig.gigDescription ?? ""
        category = gig.category ?? ""
        price = gig.price
        priceType = gig.priceType ?? ""
        location = gig.location ?? ""
        tags = (gig.tags as? [String])?.joined(separator: ", ") ?? ""
        isActive = gig.isActive
    }
    
    private func saveGig() {
        gig.title = title
        gig.gigDescription = gigDescription
        gig.category = category
        gig.price = price
        gig.priceType = priceType
        gig.location = location
        gig.tags = (tags.isEmpty ? [String]() : tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }) as NSObject
        gig.isActive = isActive
        gig.updatedAt = Date()
        
        try? viewContext.save()
        dismiss()
    }
}

struct GigEditField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: 100)
                    .padding()
                    .background(Color.appGrayLight)
                    .cornerRadius(12)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

struct GigPromoteView: View {
    @Environment(\.dismiss) private var dismiss
    
    let gig: Gig
    
    @State private var selectedPromotionType = "Pin to Top"
    @State private var selectedDuration = "24 hours"
    @State private var showingPayment = false
    
    let promotionTypes = ["Pin to Top", "Featured on Homepage", "Highlight in Search"]
    let durations = ["24 hours", "48 hours", "72 hours", "1 week"]
    
    var promotionPrice: Double {
        switch selectedPromotionType {
        case "Pin to Top":
            return 9.99
        case "Featured on Homepage":
            return 19.99
        case "Highlight in Search":
            return 14.99
        default:
            return 9.99
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                        
                        Text("Promote Your Gig")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Boost your visibility and reach more potential clients")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Gig Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gig to Promote")
                            .font(.headline)
                        
                        HStack {
                            Circle()
                                .fill(Color.appAccentLight)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(gig.provider?.name?.prefix(1) ?? "U"))
                                        .font(.headline)
                                        .foregroundColor(.appAccent)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(gig.title ?? "Untitled Gig")
                                    .font(.headline)
                                
                                Text(gig.category ?? "Category")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.0f", gig.price))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.appAccent)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Promotion Options
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Promotion Type")
                                .font(.headline)
                            
                            Picker("Promotion Type", selection: $selectedPromotionType) {
                                ForEach(promotionTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration")
                                .font(.headline)
                            
                            Picker("Duration", selection: $selectedDuration) {
                                ForEach(durations, id: \.self) { duration in
                                    Text(duration).tag(duration)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Price Display
                    VStack(spacing: 12) {
                        HStack {
                            Text("Promotion Cost")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", promotionPrice))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appAccent)
                        }
                        .padding()
                        .background(Color.appAccentLight)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Text("This promotion will help your gig appear prominently in search results and recommendations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Purchase Button
                    Button(action: { showingPayment = true }) {
                        Text("Purchase Promotion")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appAccent)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Promote Gig")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Payment Required", isPresented: $showingPayment) {
            Button("Purchase") {
                // Handle payment
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You will be charged $\(String(format: "%.2f", promotionPrice)) for this promotion.")
        }
    }
} 