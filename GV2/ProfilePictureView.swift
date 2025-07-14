import SwiftUI

struct ProfilePictureView: View {
    let name: String
    let size: CGFloat
    let showBorder: Bool
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasError = false
    
    init(name: String, size: CGFloat = 50, showBorder: Bool = true) {
        self.name = name
        self.size = size
        self.showBorder = showBorder
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(showBorder ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            } else if isLoading {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    )
            } else {
                // Fallback avatar
                Circle()
                    .fill(generateColor(for: name))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(generateInitials(for: name))
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(showBorder ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            }
        }
        .onAppear {
            loadProfilePicture()
        }
    }
    
    private func loadProfilePicture() {
        isLoading = true
        hasError = false
        
        ImageCacheService.shared.fetchProfilePicture(for: name) { fetchedImage in
            DispatchQueue.main.async {
                self.isLoading = false
                if let fetchedImage = fetchedImage {
                    self.image = fetchedImage
                } else {
                    self.hasError = true
                }
            }
        }
    }
    
    private func generateColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(red: 0.2, green: 0.6, blue: 0.9), // Blue
            Color(red: 0.9, green: 0.4, blue: 0.6), // Pink
            Color(red: 0.4, green: 0.8, blue: 0.6), // Green
            Color(red: 0.9, green: 0.6, blue: 0.2), // Orange
            Color(red: 0.6, green: 0.4, blue: 0.9), // Purple
            Color(red: 0.9, green: 0.2, blue: 0.3), // Red
            Color(red: 0.3, green: 0.7, blue: 0.8), // Teal
            Color(red: 0.8, green: 0.5, blue: 0.2)  // Brown
        ]
        
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
    
    private func generateInitials(for name: String) -> String {
        return name.components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
}

// MARK: - Preview
struct ProfilePictureView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProfilePictureView(name: "Sarah Chen", size: 60)
            ProfilePictureView(name: "Mike Rodriguez", size: 50)
            ProfilePictureView(name: "Emma Thompson", size: 40)
            ProfilePictureView(name: "David Kim", size: 80)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 