//
//  CreateGigView.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import SwiftUI
import CoreData

struct CreateGigView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(entity: User.entity(), sortDescriptors: []) var users: FetchedResults<User>

    @State private var title = ""
    @State private var description = ""
    @State private var category = "Creative"
    @State private var price = ""
    @State private var priceType = "per service"
    @State private var location = ""
    @State private var tags = ""
    @State private var isActive = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isEnhancing = false
    @State private var enhancedText = ""
    @State private var showEnhancementPreview = false
    @State private var locationSuggestions: [String] = []
    @State private var showCustomCategory = false
    @State private var customCategory = ""
    @State private var selectedCategory = "Creative"

    let categories = ["Creative", "Fitness", "Home", "Pet Care", "Tutoring", "Beauty", "Food", "Tech", "Sports", "Music", "Professional"]
    let priceTypes = ["per service", "per hour", "per session", "per day", "per week", "per month"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)

                        Text("Create Your Gig")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Share your skills with the community")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Form
                    VStack(spacing: 20) {
                        // Service Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Service Information")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }

                            // Title
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.purple)
                                    Text("Gig Title")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                TextField("e.g., Professional Photography Session", text: $title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "text.alignleft")
                                        .foregroundColor(.purple)
                                    Text("Description")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                TextField("Describe your service in detail...", text: $description, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(4...8)

                                // Enhance with AI button
                                if !description.isEmpty {
                                    Button(action: enhanceDescriptionWithAI) {
                                        HStack {
                                            Image(systemName: "sparkles")
                                            Text("Enhance with AI")
                                        }
                                        .foregroundColor(.purple)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .disabled(isEnhancing)
                                    .overlay(
                                        Group {
                                            if isEnhancing {
                                                HStack {
                                                    ProgressView()
                                                        .scaleEffect(0.8)
                                                    Text("Enhancing...")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color(.systemBackground))
                                                .cornerRadius(8)
                                            }
                                        }
                                    )
                                }
                            }

                            // Category
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.purple)
                                    Text("Category")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                Menu {
                                    ForEach(categories, id: \.self) { category in
                                        Button(category) {
                                            selectedCategory = category
                                            showCustomCategory = false
                                        }
                                    }
                                    Divider()
                                    Button("+ Custom Category") {
                                        showCustomCategory = true
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCategory.isEmpty ? "Choose Category" : selectedCategory)
                                            .foregroundColor(selectedCategory.isEmpty ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }

                                if showCustomCategory {
                                    TextField("Enter custom category", text: $customCategory)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onChange(of: customCategory) { newValue in
                                            selectedCategory = newValue
                                        }
                                }
                            }
                        }

                        // Pricing Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Pricing")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "dollarsign")
                                            .foregroundColor(.purple)
                                        Text("Price")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }

                                    HStack {
                                        Text("$")
                                            .foregroundColor(.secondary)
                                        TextField("0", text: $price)
                                            .keyboardType(.decimalPad)
                                    }
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.purple)
                                        Text("Price Type")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }

                                    Picker("Price Type", selection: $priceType) {
                                        ForEach(priceTypes, id: \.self) { type in
                                            Text(type).tag(type)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }

                        // Location & Tags Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Location & Tags")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }

                            // Location
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.purple)
                                    Text("Location")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                TextField("City, State", text: $location)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: location) { query in
                                        if query.count >= 2 {
                                            LocationService.shared.autocomplete(query) { results in
                                                locationSuggestions = results
                                            }
                                        } else {
                                            locationSuggestions = []
                                        }
                                    }

                                if !locationSuggestions.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(locationSuggestions, id: \.self) { suggestion in
                                            Button(action: {
                                                location = suggestion
                                                locationSuggestions = []
                                            }) {
                                                HStack {
                                                    Image(systemName: "location")
                                                        .foregroundColor(.purple)
                                                        .font(.caption)
                                                    Text(suggestion)
                                                        .font(.caption)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(6)
                                            }
                                        }
                                    }
                                }
                            }

                            // Tags
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.purple)
                                    Text("Tags")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                TextField("e.g., photography, portraits, events (separate with commas)", text: $tags)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())

                                Text("Tags help people find your service")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Active toggle
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Make gig active")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("Active gigs are visible to customers")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: $isActive)
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: createGig) {
                            Text("Create Gig")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(12)
                        }
                        .disabled(title.isEmpty || description.isEmpty || price.isEmpty || selectedCategory.isEmpty)

                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Create Gig")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Gig Created", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showEnhancementPreview) {
                EnhancementPreviewView(
                    originalText: description,
                    enhancedText: enhancedText,
                    onKeep: {
                        description = enhancedText
                        showEnhancementPreview = false
                    },
                    onUndo: {
                        enhancedText = ""
                        showEnhancementPreview = false
                    },
                    onEdit: {
                        description = enhancedText
                        showEnhancementPreview = false
                    }
                )
            }
            .onAppear {
                loadUserLocation()
            }
        }
    }

    func enhanceDescriptionWithAI() {
        isEnhancing = true
        AIService.enhance(text: description) { result in
            DispatchQueue.main.async {
                isEnhancing = false
                enhancedText = result
                showEnhancementPreview = true
            }
        }
    }

    func loadUserLocation() {
        if let currentUser = users.first, let userLocation = currentUser.location, !userLocation.isEmpty {
            location = userLocation
        }
    }

    func createGig() {
        guard !title.isEmpty, !description.isEmpty, !price.isEmpty else {
            alertMessage = "Please fill in all required fields"
            showingAlert = true
            return
        }

        guard let priceValue = Double(price), priceValue > 0 else {
            alertMessage = "Please enter a valid price"
            showingAlert = true
            return
        }

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1

        guard let currentUser = try? viewContext.fetch(request).first else {
            alertMessage = "User profile not found"
            showingAlert = true
            return
        }

        let gig = Gig(context: viewContext)
        gig.id = UUID()
        gig.title = title
        gig.gigDescription = description
        gig.category = selectedCategory
        gig.price = priceValue
        gig.priceType = priceType
        gig.location = location.isEmpty ? currentUser.location : location
        gig.tags = (tags.isEmpty ? [] : tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }) as NSObject
        gig.isActive = isActive
        gig.createdAt = Date()
        gig.updatedAt = Date()
        gig.provider = currentUser

        do {
            try viewContext.save()
            alertMessage = "Your gig has been created successfully!"
            showingAlert = true
        } catch {
            alertMessage = "Error creating gig: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Enhancement Preview View
struct EnhancementPreviewView: View {
    let originalText: String
    let enhancedText: String
    let onKeep: () -> Void
    let onUndo: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Enhanced Description")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("AI has improved your description to make it more appealing and professional.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Original vs Enhanced comparison
                VStack(alignment: .leading, spacing: 16) {
                    // Original
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(originalText)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    // Enhanced
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enhanced")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        Text(enhancedText)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onKeep) {
                        Text("Keep Enhanced Version")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: onUndo) {
                            Text("Undo")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        Button(action: onEdit) {
                            Text("Edit Enhanced")
                                .font(.body)
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("AI Enhancement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onUndo()
                    }
                }
            }
        }
    }
}
