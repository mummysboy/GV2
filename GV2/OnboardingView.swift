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
                                .fill(index == currentPage ? Color.appAccent : Color.appBorder)
                                .frame(width: 10, height: 10)
                                .animation(.easeInOut, value: currentPage)
                        }
                    }
                    .padding(.bottom, 40)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.appAccent)
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
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.appAccent)
                        .cornerRadius(16)
                        .shadow(color: .appAccent.opacity(0.3), radius: 8, x: 0, y: 4)
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
                .font(.system(size: 88))
                .foregroundColor(.appAccent)
                .padding(.bottom, 24)
                .shadow(color: .appAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.appAccent)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
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
                        .font(.system(size: 64))
                        .foregroundColor(.appAccent)
                        .shadow(color: .appAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text("Set Up Your Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                    
                    Text("Tell us a bit about yourself")
                        .font(.body)
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.appText)
                        
                        TextField("Your name", text: $userName)
                            .hingeInputField()
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.appText)
                        
                        TextField("City, State", text: $userLocation)
                            .hingeInputField()
                    }
                    
                    // Bio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.appText)
                        
                        TextField("Tell us about yourself...", text: $userBio, axis: .vertical)
                            .hingeInputField()
                            .lineLimit(3...6)
                    }
                    
                    // Provider toggle
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I want to offer services")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.appText)
                                
                                Text("Create gigs and earn money")
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isProvider)
                                .toggleStyle(SwitchToggleStyle(tint: .appAccent))
                        }
                        .padding(20)
                        .background(Color.appSurfaceSecondary)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                // Complete button
                Button(action: onComplete) {
                    Text("Complete Setup")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appAccent)
                        .cornerRadius(16)
                        .shadow(color: .appAccent.opacity(0.3), radius: 8, x: 0, y: 4)
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