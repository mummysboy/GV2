import SwiftUI
import CoreData
import PhotosUI

struct UserProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.createdAt, ascending: false)],
        animation: .default)
    private var users: FetchedResults<User>
    
    @State private var showingImagePicker = false
    @State private var showingVerificationSheet = false
    @State private var showingSocialLinksSheet = false
    @State private var showingContactPreferencesSheet = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    
    var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        ZStack {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if let avatarData = currentUser?.avatar,
                                      let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.purple.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Text(String(currentUser?.name?.prefix(1) ?? "U"))
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(.purple)
                                    )
                            }
                            
                            // Edit button overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    PhotosPicker(selection: $selectedImage, matching: .images) {
                                        Image(systemName: "camera.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.purple)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                        
                        // Name and Location
                        VStack(spacing: 4) {
                            Text(currentUser?.name ?? "Your Name")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(currentUser?.location ?? "Location")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Verification Status
                        if currentUser?.isVerified == true {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                Text("Verified Provider")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Button(action: { showingVerificationSheet = true }) {
                                HStack {
                                    Image(systemName: "checkmark.seal")
                                        .foregroundColor(.secondary)
                                    Text("Get Verified")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    // Profile Stats
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(currentUser?.totalReviews ?? 0)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Reviews")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text(String(format: "%.1f", currentUser?.rating ?? 0.0))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Rating")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(currentUser?.gigs?.count ?? 0)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Gigs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Profile Management Options
                    VStack(spacing: 12) {
                        ProfileOptionButton(
                            title: "Edit Profile Details",
                            subtitle: "Name, bio, location",
                            icon: "person.circle",
                            action: { showingContactPreferencesSheet = true }
                        )
                        
                        ProfileOptionButton(
                            title: "Contact Preferences",
                            subtitle: "Phone, email, messaging",
                            icon: "envelope.circle",
                            action: { showingContactPreferencesSheet = true }
                        )
                        
                        ProfileOptionButton(
                            title: "Social Media Links",
                            subtitle: "Instagram, TikTok, LinkedIn",
                            icon: "link.circle",
                            action: { showingSocialLinksSheet = true }
                        )
                        
                        ProfileOptionButton(
                            title: "Verification Status",
                            subtitle: currentUser?.isVerified == true ? "Verified" : "Get verified",
                            icon: "checkmark.seal.circle",
                            action: { showingVerificationSheet = true }
                        )
                        
                        ProfileOptionButton(
                            title: "Manage Gigs",
                            subtitle: "View, edit, promote your gigs",
                            icon: "briefcase.circle",
                            action: { /* Navigate to gig management */ }
                        )
                        
                        ProfileOptionButton(
                            title: "Analytics & Insights",
                            subtitle: "Views, bookings, performance",
                            icon: "chart.bar.circle",
                            action: { /* Navigate to analytics */ }
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedImage) { _ in
            Task {
                if let data = try? await selectedImage?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage = Image(uiImage: uiImage)
                    // Save to Core Data
                    currentUser?.avatar = data
                    try? viewContext.save()
                }
            }
        }
        .sheet(isPresented: $showingVerificationSheet) {
            VerificationView()
        }
        .sheet(isPresented: $showingSocialLinksSheet) {
            SocialLinksView()
        }
        .sheet(isPresented: $showingContactPreferencesSheet) {
            ContactPreferencesView()
        }
    }
}

struct ProfileOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDocumentType = "Driver's License"
    @State private var showingDocumentPicker = false
    @State private var documentImage: Image?
    
    let documentTypes = ["Driver's License", "Passport", "National ID", "Business License"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Get Verified")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Verification helps build trust with potential clients and increases your visibility in search results.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Document Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Document Type")
                            .font(.headline)
                        
                        Picker("Document Type", selection: $selectedDocumentType) {
                            ForEach(documentTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Document Upload
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upload Document")
                            .font(.headline)
                        
                        Button(action: { showingDocumentPicker = true }) {
                            VStack(spacing: 12) {
                                if let documentImage = documentImage {
                                    documentImage
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 200)
                                        .cornerRadius(12)
                                } else {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 48))
                                        .foregroundColor(.purple)
                                    
                                    Text("Tap to upload document")
                                        .font(.body)
                                        .foregroundColor(.purple)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Submit Button
                    Button(action: {
                        // Submit verification request
                        dismiss()
                    }) {
                        Text("Submit for Verification")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(documentImage == nil)
                }
            }
            .navigationTitle("Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SocialLinksView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var instagram = ""
    @State private var tiktok = ""
    @State private var linkedin = ""
    @State private var twitter = ""
    @State private var website = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        
                        Text("Social Media Links")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Add your social media profiles to help clients learn more about you.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Social Media Fields
                    VStack(spacing: 16) {
                        SocialLinkField(
                            title: "Instagram",
                            placeholder: "@username",
                            text: $instagram,
                            icon: "camera"
                        )
                        
                        SocialLinkField(
                            title: "TikTok",
                            placeholder: "@username",
                            text: $tiktok,
                            icon: "music.note"
                        )
                        
                        SocialLinkField(
                            title: "LinkedIn",
                            placeholder: "linkedin.com/in/username",
                            text: $linkedin,
                            icon: "briefcase"
                        )
                        
                        SocialLinkField(
                            title: "Twitter",
                            placeholder: "@username",
                            text: $twitter,
                            icon: "bird"
                        )
                        
                        SocialLinkField(
                            title: "Website",
                            placeholder: "yourwebsite.com",
                            text: $website,
                            icon: "globe"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: {
                        // Save social links
                        dismiss()
                    }) {
                        Text("Save Links")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Social Links")
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

struct SocialLinkField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct ContactPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.createdAt, ascending: false)],
        animation: .default)
    private var users: FetchedResults<User>
    
    @State private var name = ""
    @State private var bio = ""
    @State private var location = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var allowInAppMessaging = true
    @State private var allowPhoneCalls = false
    @State private var allowEmail = true
    
    var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        
                        Text("Profile Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Update your profile information and contact preferences.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Profile Information
                    VStack(spacing: 16) {
                        ProfileField(
                            title: "Name",
                            placeholder: "Your full name",
                            text: $name
                        )
                        
                        ProfileField(
                            title: "Bio",
                            placeholder: "Tell clients about yourself...",
                            text: $bio,
                            isMultiline: true
                        )
                        
                        ProfileField(
                            title: "Location",
                            placeholder: "City, State",
                            text: $location
                        )
                        
                        ProfileField(
                            title: "Phone",
                            placeholder: "+1 (555) 123-4567",
                            text: $phone
                        )
                        
                        ProfileField(
                            title: "Email",
                            placeholder: "your@email.com",
                            text: $email
                        )
                    }
                    .padding(.horizontal)
                    
                    // Contact Preferences
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Preferences")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ContactPreferenceToggle(
                                title: "In-App Messaging",
                                subtitle: "Allow clients to message you through the app",
                                isOn: $allowInAppMessaging
                            )
                            
                            ContactPreferenceToggle(
                                title: "Phone Calls",
                                subtitle: "Allow clients to call you directly",
                                isOn: $allowPhoneCalls
                            )
                            
                            ContactPreferenceToggle(
                                title: "Email",
                                subtitle: "Allow clients to email you",
                                isOn: $allowEmail
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Save Button
                    Button(action: saveProfile) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }
    
    private func loadCurrentProfile() {
        guard let user = currentUser else { return }
        name = user.name ?? ""
        bio = user.bio ?? ""
        location = user.location ?? ""
        phone = user.phone ?? ""
        email = user.email ?? ""
    }
    
    private func saveProfile() {
        guard let user = currentUser else { return }
        
        user.name = name
        user.bio = bio
        user.location = location
        user.phone = phone
        user.email = email
        user.updatedAt = Date()
        
        try? viewContext.save()
        dismiss()
    }
}

struct ProfileField: View {
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
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

struct ContactPreferenceToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 