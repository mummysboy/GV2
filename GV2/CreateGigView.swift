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
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gig Title")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("e.g., Professional Photography Session", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Describe your service in detail...", text: $description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(4...8)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Price
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Price")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text("$")
                                        .foregroundColor(.secondary)
                                    TextField("0", text: $price)
                                        .keyboardType(.decimalPad)
                                }
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Price Type")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
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
                        
                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("City, State", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("e.g., photography, portraits, events (separate with commas)", text: $tags)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Tags help people find your service")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                        .disabled(title.isEmpty || description.isEmpty || price.isEmpty)
                        
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
        }
        .alert("Gig Created", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func createGig() {
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
        
        // Get current user
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        
        guard let currentUser = try? viewContext.fetch(request).first else {
            alertMessage = "User profile not found"
            showingAlert = true
            return
        }
        
        // Create gig
        let gig = Gig(context: viewContext)
        gig.id = UUID()
        gig.title = title
        gig.gigDescription = description
        gig.category = category
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

#Preview {
    CreateGigView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 