//
//  ContentView.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    @State private var showingReviewPrompt = false
    @State private var pendingReviewSession: ServiceSession?
    @StateObject private var conversationMonitor = ConversationMonitor()
    @StateObject private var reviewScheduler: ReviewScheduler
    
    init() {
        let monitor = ConversationMonitor()
        self._reviewScheduler = StateObject(wrappedValue: ReviewScheduler(conversationMonitor: monitor))
    }
    
    var body: some View {
        Group {
            if hasUserProfile() {
                TabView(selection: $selectedTab) {
                    HomeFeedView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    
                    SearchView()
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                        .tag(1)
                    
                    MessagesView()
                        .tabItem {
                            Image(systemName: "message.fill")
                            Text("Messages")
                        }
                        .tag(2)
                    
                    SocialView()
                        .tabItem {
                            Image(systemName: "person.2.fill")
                            Text("Social")
                        }
                        .tag(3)
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("Profile")
                        }
                        .tag(4)
                }
                .accentColor(.purple)
                .preferredColorScheme(.light)
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            if !hasUserProfile() {
                showingOnboarding = true
            } else {
                checkForReviewPrompts()
            }
        }
        .alert("Rate your experience", isPresented: $showingReviewPrompt) {
            Button("Leave Review") {
                if let session = pendingReviewSession {
                    // In a real app, you would navigate to the review view
                    // For now, we'll just mark it as prompted
                    conversationMonitor.markSessionAsPrompted(session.id, for: "current_user")
                }
            }
            Button("Not Now", role: .cancel) { }
        } message: {
            if let session = pendingReviewSession {
                Text("Did you receive a service from \(getProviderName(for: session))?")
            }
        }
    }
    
    private func hasUserProfile() -> Bool {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        return (try? viewContext.count(for: request)) ?? 0 > 0
    }
    
    private func checkForReviewPrompts() {
        let pendingReviews = reviewScheduler.getPendingReviewsForUser("current_user")
        if let firstPending = pendingReviews.first {
            pendingReviewSession = firstPending
            showingReviewPrompt = true
        }
    }
    
    private func getProviderName(for session: ServiceSession) -> String {
        // In a real app, you would fetch the provider name from the database
        // For now, return a placeholder
        return "Provider"
    }
}

struct HomeFeedView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Gig.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default)
    private var gigs: FetchedResults<Gig>
    
    @State private var showingAIChat = false
    @State private var showingCreateGig = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // AI Chat Assistant Button
                Button(action: { showingAIChat = true }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Ask AI to find services...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top)
                
                // Trending Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(["🎨 Creative", "🏠 Home", "🐕 Pet Care", "📚 Tutoring", "💪 Fitness", "🍳 Food"], id: \.self) { category in
                            Button(action: {}) {
                                Text(category)
                                    .font(.caption)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Gig Feed
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(gigs) { gig in
                            GigCardView(gig: gig)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Gig")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGig = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAIChat) {
            AIChatView()
        }
        .sheet(isPresented: $showingCreateGig) {
            CreateGigView()
        }
    }
}

struct GigCardView: View {
    let gig: Gig
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with provider info
            HStack {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(gig.provider?.name?.prefix(1) ?? "U"))
                            .font(.headline)
                            .foregroundColor(.purple)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(gig.provider?.name ?? "Unknown Provider")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(gig.location ?? "Location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if gig.provider?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.0f", gig.price))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text(gig.priceType ?? "per service")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Gig content
            VStack(alignment: .leading, spacing: 8) {
                Text(gig.title ?? "Untitled Gig")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(gig.gigDescription ?? "No description available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                // Tags
                if let tags = gig.tags as? [String], !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            // Action buttons
            HStack {
                Button(action: { showingDetail = true }) {
                    HStack {
                        Image(systemName: "eye")
                        Text("View Details")
                    }
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "message")
                        Text("Message")
                    }
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingDetail) {
            GigDetailView(gig: gig, highlightedReviewId: nil)
        }
    }
}

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    let categories = ["All", "Creative", "Home", "Pet Care", "Tutoring", "Fitness", "Food", "Tech", "Beauty"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for services...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Category filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category)
                                    .font(.caption)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.purple : Color.purple.opacity(0.1))
                                    .foregroundColor(selectedCategory == category ? .white : .purple)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Search results placeholder
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Search for amazing services")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Find everything from surf lessons to resume help")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct MessagesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "message.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.purple)
                    
                    Text("No messages yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Start a conversation with service providers")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.createdAt, ascending: false)],
        animation: .default)
    private var users: FetchedResults<User>
    
    @State private var showingCreateGig = false
    @State private var showingProfileManagement = false
    @State private var showingGigManagement = false
    @State private var showingAnalytics = false
    
    var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(currentUser?.name?.prefix(1) ?? "U"))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                            )
                        
                        VStack(spacing: 4) {
                            Text(currentUser?.name ?? "Your Name")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(currentUser?.location ?? "Location")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        if currentUser?.isVerified == true {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                Text("Verified Provider")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    
                    // Stats
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
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: { showingCreateGig = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Create New Gig")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingProfileManagement = true }) {
                            HStack {
                                Image(systemName: "person.circle")
                                Text("Edit Profile")
                            }
                            .font(.headline)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingGigManagement = true }) {
                            HStack {
                                Image(systemName: "briefcase")
                                Text("Manage Gigs")
                            }
                            .font(.headline)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingAnalytics = true }) {
                            HStack {
                                Image(systemName: "chart.bar")
                                Text("Analytics")
                            }
                            .font(.headline)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateGig) {
            CreateGigView()
        }
        .sheet(isPresented: $showingProfileManagement) {
            UserProfileView()
        }
        .sheet(isPresented: $showingGigManagement) {
            GigManagementView()
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsView()
        }
    }
}

struct AIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var aiService = AIService()
    @State private var messageText = ""
    @State private var chatMessages: [ChatMessage] = []
    @State private var showingGigDetail = false
    @State private var selectedGig: Gig?
    
    var body: some View {
        NavigationView {
            VStack {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(chatMessages) { message in
                                ChatMessageView(message: message) { gig in
                                    selectedGig = gig
                                    showingGigDetail = true
                                }
                            }
                            
                            if aiService.isProcessing {
                                HStack {
                                    HStack(spacing: 4) {
                                        ForEach(0..<3) { index in
                                            Circle()
                                                .fill(Color.purple)
                                                .frame(width: 8, height: 8)
                                                .scaleEffect(1.0)
                                                .animation(
                                                    Animation.easeInOut(duration: 0.6)
                                                        .repeatForever()
                                                        .delay(Double(index) * 0.2),
                                                    value: aiService.isProcessing
                                                )
                                        }
                                    }
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(12)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .onChange(of: chatMessages.count) { _ in
                            withAnimation {
                                proxy.scrollTo(chatMessages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input area
                HStack {
                    TextField("Ask me to find services...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(aiService.isProcessing)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(messageText.isEmpty || aiService.isProcessing ? .gray : .purple)
                    }
                    .disabled(messageText.isEmpty || aiService.isProcessing)
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if chatMessages.isEmpty {
                    addWelcomeMessage()
                }
            }
        }
        .sheet(isPresented: $showingGigDetail) {
            if let gig = selectedGig {
                GigDetailView(gig: gig)
            }
        }
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            id: UUID(),
            content: "Hi! I'm your AI assistant. I can help you find amazing services like photography, fitness training, home repair, and much more. Just tell me what you're looking for!",
            isUser: false,
            timestamp: Date(),
            suggestions: ["Find photography services", "Looking for fitness training", "Need home repair help", "Pet care services"],
            gigs: []
        )
        chatMessages.append(welcomeMessage)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID(),
            content: messageText,
            isUser: true,
            timestamp: Date(),
            suggestions: [],
            gigs: []
        )
        chatMessages.append(userMessage)
        
        let query = messageText
        messageText = ""
        
        // Process with AI
        Task {
            let response = await aiService.processUserQuery(query, context: viewContext)
            
            await MainActor.run {
                let aiMessage = ChatMessage(
                    id: UUID(),
                    content: response.message,
                    isUser: false,
                    timestamp: Date(),
                    suggestions: response.suggestions,
                    gigs: response.gigs
                )
                chatMessages.append(aiMessage)
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let suggestions: [String]
    let gigs: [Gig]
}

struct ChatMessageView: View {
    let message: ChatMessage
    let onGigTap: (Gig) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if message.isUser {
                    Spacer()
                    Text(message.content)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                } else {
                    Text(message.content)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    Spacer()
                }
            }
            
            if !message.isUser {
                // Suggestions
                if !message.suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(message.suggestions, id: \.self) { suggestion in
                                Button(action: {}) {
                                    Text(suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                // Recommended gigs
                if !message.gigs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Services:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(message.gigs) { gig in
                            Button(action: { onGigTap(gig) }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(gig.title ?? "Untitled")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("$\(String(format: "%.0f", gig.price)) \(gig.priceType ?? "")")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct GigDetailView: View {
    let gig: Gig
    var highlightedReviewId: String? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showingChat = false
    @State private var showingCall = false
    @State private var showingAllReviews = false
    @StateObject private var reviewScheduler: ReviewScheduler
    @StateObject private var conversationMonitor = ConversationMonitor()
    
    init(gig: Gig, highlightedReviewId: String? = nil) {
        self.gig = gig
        self.highlightedReviewId = highlightedReviewId
        let monitor = ConversationMonitor()
        self._reviewScheduler = StateObject(wrappedValue: ReviewScheduler(conversationMonitor: monitor))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(gig.title ?? "Untitled Gig")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("$\(String(format: "%.0f", gig.price))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text(gig.priceType ?? "per service")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Provider info - Clickable
                    NavigationLink(destination: ProviderProfileView(provider: gig.provider ?? User())) {
                        HStack {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(gig.provider?.name?.prefix(1) ?? "U"))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(gig.provider?.name ?? "Unknown Provider")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text(gig.location ?? "Location")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if gig.provider?.isVerified == true {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "%.1f", gig.provider?.rating ?? 0.0))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("★")
                                    .foregroundColor(.yellow)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this service")
                            .font(.headline)
                        
                        Text(gig.gigDescription ?? "No description available")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Tags
                    if let tags = gig.tags as? [String], !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Reviews Section
                    reviewsSection
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: { showingChat = true }) {
                            HStack {
                                Image(systemName: "message")
                                Text("Message Provider")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingCall = true }) {
                            HStack {
                                Image(systemName: "phone")
                                Text("Call Provider")
                            }
                            .font(.headline)
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
            .navigationTitle("Gig Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingChat) {
            ChatView(partner: gig.provider ?? User())
        }
        .fullScreenCover(isPresented: $showingCall) {
            InAppCallView(provider: gig.provider ?? User())
        }
        .onAppear {
            reviewScheduler.loadGigReviews(for: gig.id?.uuidString ?? "")
        }
    }
    
    private var reviewsSection: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 12) {
                Text("Service Reviews")
                    .font(.headline)

                if reviewScheduler.gigReviews.isEmpty {
                    Text("No reviews yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(reviewScheduler.gigReviews.prefix(3)) { review in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(review.reviewerName)
                                    .fontWeight(.semibold)
                                
                                // Friend badge
                                if review.isFromFriend {
                                    Text("👤 Friend")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .clipShape(Capsule())
                                }
                                
                                Spacer()
                                Text(String(format: "%.1f ★", review.rating))
                                    .foregroundColor(.yellow)
                            }
                            Text(review.comment)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            review.id == highlightedReviewId
                            ? Color.yellow.opacity(0.2)
                            : Color.clear
                        )
                        .cornerRadius(8)
                        .id(review.id)
                        .padding(.bottom, 6)
                    }
                }
            }
            .padding(.top, 20)
            .onAppear {
                // Scroll to highlighted review after a short delay
                if let highlight = highlightedReviewId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(highlight, anchor: .top)
                        }
                    }
                }
            }
        }
    }
}



#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
