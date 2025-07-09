//
//  OnboardingView.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import SwiftUI
import CoreData

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var userLocation = ""
    @State private var userBio = ""
    @State private var isProvider = false
    
    let pages = [
        OnboardingPage(
            title: "Welcome to Gig",
            subtitle: "Discover amazing local services or offer your skills to the community",
            image: "sparkles",
            description: "Find everything from surf lessons to resume help, all in one place."
        ),
        OnboardingPage(
            title: "AI-Powered Discovery",
            subtitle: "Just tell our AI what you need",
            image: "brain.head.profile",
            description: "Ask naturally and get personalized service recommendations instantly."
        ),
        OnboardingPage(
            title: "Verified Providers",
            subtitle: "Connect with trusted professionals",
            image: "checkmark.seal.fill",
            description: "All providers are verified and reviewed by the community."
        ),
        OnboardingPage(
            title: "Secure Communication",
            subtitle: "Chat and call safely",
            image: "message.and.waveform.fill",
            description: "Built-in messaging and calling with AI safety monitoring."
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if currentPage < pages.count {
                    // Onboarding pages
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            OnboardingPageView(page: pages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                    
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.purple : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentPage)
                        }
                    }
                    .padding(.bottom, 30)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        Button(currentPage == pages.count - 1 ? "Get Started" : "Next") {
                            withAnimation {
                                if currentPage < pages.count - 1 {
                                    currentPage += 1
                                } else {
                                    // Show profile setup
                                    currentPage = pages.count
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                } else {
                    // Profile setup
                    ProfileSetupView(
                        userName: $userName,
                        userLocation: $userLocation,
                        userBio: $userBio,
                        isProvider: $isProvider,
                        onComplete: createUserProfile
                    )
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func createUserProfile() {
        let user = User(context: viewContext)
        user.id = UUID()
        user.name = userName.isEmpty ? "New User" : userName
        user.location = userLocation.isEmpty ? "Location" : userLocation
        user.bio = userBio.isEmpty ? "Tell us about yourself..." : userBio
        user.isVerified = false
        user.rating = 0.0
        user.totalReviews = 0
        user.createdAt = Date()
        user.updatedAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error creating user profile: \(error)")
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let image: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: page.image)
                .font(.system(size: 80))
                .foregroundColor(.purple)
                .padding(.bottom, 20)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .foregroundColor(.purple)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct ProfileSetupView: View {
    @Binding var userName: String
    @Binding var userLocation: String
    @Binding var userBio: String
    @Binding var isProvider: Bool
    let onComplete: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Set Up Your Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Tell us a bit about yourself")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Your name", text: $userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("City, State", text: $userLocation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Bio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Tell us about yourself...", text: $userBio, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Provider toggle
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I want to offer services")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Create gigs and earn money")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isProvider)
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                // Complete button
                Button(action: onComplete) {
                    Text("Complete Setup")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 