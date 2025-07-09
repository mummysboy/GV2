import SwiftUI

struct ConnectSocialsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var connectedAccounts: Set<SocialPlatform> = []
    @State private var isConnecting = false
    
    enum SocialPlatform: String, CaseIterable {
        case instagram = "Instagram"
        case facebook = "Facebook"
        case twitter = "Twitter"
        case linkedin = "LinkedIn"
        
        var icon: String {
            switch self {
            case .instagram: return "camera"
            case .facebook: return "person.2"
            case .twitter: return "bird"
            case .linkedin: return "briefcase"
            }
        }
        
        var color: Color {
            switch self {
            case .instagram: return .purple
            case .facebook: return .blue
            case .twitter: return .cyan
            case .linkedin: return .blue
            }
        }
        
        var description: String {
            switch self {
            case .instagram: return "Find friends from your Instagram following"
            case .facebook: return "Connect with your Facebook friends"
            case .twitter: return "Discover people you follow on Twitter"
            case .linkedin: return "Connect with your professional network"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "link.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Connect Social Accounts")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Connect your social media accounts to find friends and see their activity on GV2.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Social Platforms List
                LazyVStack(spacing: 12) {
                    ForEach(SocialPlatform.allCases, id: \.self) { platform in
                        SocialPlatformCard(
                            platform: platform,
                            isConnected: connectedAccounts.contains(platform),
                            onToggle: { isConnected in
                                if isConnected {
                                    connectPlatform(platform)
                                } else {
                                    disconnectPlatform(platform)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Connected Accounts Summary
                if !connectedAccounts.isEmpty {
                    VStack(spacing: 8) {
                        Text("Connected Accounts")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(Array(connectedAccounts), id: \.self) { platform in
                                Image(systemName: platform.icon)
                                    .foregroundColor(platform.color)
                                    .padding(8)
                                    .background(platform.color.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Connect Socials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isConnecting)
                }
            }
        }
    }
    
    private func connectPlatform(_ platform: SocialPlatform) {
        isConnecting = true
        
        // Mock connection process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            connectedAccounts.insert(platform)
            isConnecting = false
        }
    }
    
    private func disconnectPlatform(_ platform: SocialPlatform) {
        connectedAccounts.remove(platform)
    }
}

struct SocialPlatformCard: View {
    let platform: ConnectSocialsView.SocialPlatform
    let isConnected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Platform Icon
            Image(systemName: platform.icon)
                .font(.title2)
                .foregroundColor(platform.color)
                .frame(width: 40, height: 40)
                .background(platform.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(platform.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(platform.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Connection Toggle
            Button(action: {
                onToggle(!isConnected)
            }) {
                Text(isConnected ? "Connected" : "Connect")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isConnected ? Color.green : platform.color)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ConnectSocialsView()
} 