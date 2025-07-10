# GV2 - Production-Ready iOS App

A comprehensive gig marketplace iOS app built with SwiftUI and CoreData, optimized for production deployment and App Store submission.

## 🚀 Features

- **User Management**: Complete user profiles with verification system
- **Gig Marketplace**: Create, browse, and book gigs with categories and tags
- **Messaging System**: Real-time chat between users
- **Reviews & Ratings**: Comprehensive review system
- **Social Features**: User connections and friend activity
- **CloudKit Sync**: Offline-first with iCloud synchronization
- **Analytics**: Comprehensive event tracking and user analytics
- **Error Handling**: Graceful error handling with user-friendly messages
- **Performance**: Optimized image caching and lazy loading

## 📱 Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- Apple Developer Account (for App Store deployment)

## 🛠 Setup & Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/GV2.git
cd GV2
```

### 2. Install Dependencies
The project uses Swift Package Manager for dependencies. Open the project in Xcode and dependencies will be automatically resolved.

### 3. Configuration Setup

#### Development Configuration
1. Copy `Config/Secrets.plist` and fill in your API keys:
```bash
cp Config/Secrets.plist Config/Secrets-local.plist
```

2. Update `Config/Development.xcconfig` with your development settings:
- API endpoints
- CloudKit container identifiers
- Feature flags

#### Production Configuration
1. Update `Config/Production.xcconfig` with production settings
2. Configure App Store Connect API keys in `Config/ExportOptions.plist`
3. Set up your Apple Developer Team ID

### 4. CloudKit Setup
1. Enable CloudKit in your Apple Developer account
2. Create a CloudKit container: `iCloud.com.yourcompany.GV2`
3. Update the container identifier in `Persistence.swift`

### 5. Build and Run
```bash
# Development build
xcodebuild -project GV2.xcodeproj -scheme GV2 -configuration Debug build

# Production build
./Scripts/build-production.sh
```

## 🏗 Architecture

### Core Components

- **CoreData + CloudKit**: Persistent storage with iCloud sync
- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Clean separation of concerns
- **Dependency Injection**: Environment objects for services
- **Error Handling**: Comprehensive error management system

### Key Services

- `PersistenceController`: CoreData and CloudKit management
- `ConfigurationManager`: Environment-specific configuration
- `ErrorHandler`: Centralized error handling
- `AnalyticsService`: Event tracking and analytics
- `ImageCacheService`: Optimized image loading and caching

## 📊 Analytics & Monitoring

### Analytics Events
The app tracks comprehensive user interactions:
- App launches and screen views
- User registration and authentication
- Gig creation, viewing, and booking
- Messaging and social interactions
- Payment events
- Error occurrences

### Crash Reporting
- Firebase Crashlytics integration (production)
- Console logging (development)
- Custom error tracking

## 🔒 Security

### API Key Management
- Sensitive keys stored in `Secrets.plist` (not in version control)
- Environment-specific configuration files
- Secure key injection at build time

### Data Protection
- CoreData encryption enabled
- Secure network communication
- Input validation and sanitization
- Privacy-compliant analytics

## 🚀 Deployment

### Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Production configuration verified
- [ ] API keys and secrets configured
- [ ] App icons and launch screen ready
- [ ] Privacy policy and terms of service updated
- [ ] App Store metadata prepared
- [ ] Crash reporting configured
- [ ] Analytics enabled

### Production Build

```bash
# Run the production build script
./Scripts/build-production.sh

# The script will:
# 1. Clean previous builds
# 2. Run all tests
# 3. Create production archive
# 4. Export IPA
# 5. Validate IPA
# 6. Generate build report
```

### App Store Submission

1. **Upload to App Store Connect**:
   ```bash
   xcrun altool --upload-app \
     --type ios \
     --file build/Export/GV2.ipa \
     --apiKey YOUR_API_KEY \
     --apiIssuer YOUR_ISSUER_ID
   ```

2. **Submit for Review**:
   - Complete App Store Connect metadata
   - Add screenshots and app description
   - Configure privacy settings
   - Submit for review

## 🔧 Configuration

### Environment Variables

| Variable | Development | Production |
|----------|-------------|------------|
| API_BASE_URL | `https://api-dev.yourcompany.com` | `https://api.yourcompany.com` |
| ENABLE_LOGGING | `YES` | `NO` |
| ENABLE_ANALYTICS | `NO` | `YES` |
| ENABLE_CRASH_REPORTING | `NO` | `YES` |

### Feature Flags

- `ENABLE_DEBUG_MENU`: Development-only debug features
- `ENABLE_SAMPLE_DATA`: Sample data generation
- `ENABLE_CRASH_REPORTING`: Crash reporting service

## 📈 Performance Optimization

### Image Optimization
- Lazy loading with `LazyVStack`
- Memory and disk caching
- Automatic cache cleanup
- Compressed image storage

### Memory Management
- Efficient CoreData fetch requests
- Background task optimization
- Memory leak prevention
- Automatic cleanup routines

### Network Optimization
- Request caching
- Background refresh
- Offline-first architecture
- Efficient API calls

## 🐛 Debugging & Troubleshooting

### Common Issues

1. **CoreData Sync Issues**:
   - Check CloudKit container configuration
   - Verify network connectivity
   - Review error logs

2. **Build Failures**:
   - Clean build folder: `xcodebuild clean`
   - Reset package cache
   - Check configuration files

3. **Performance Issues**:
   - Monitor memory usage
   - Check image cache size
   - Review CoreData queries

### Debug Tools

- **Development Menu**: Accessible in debug builds
- **Console Logging**: Detailed logs in development
- **Analytics Dashboard**: User behavior insights
- **Crash Reports**: Automatic crash collection

## 📚 API Documentation

### CoreData Entities

- **User**: User profiles and authentication
- **Gig**: Marketplace listings
- **Message**: Chat system
- **Conversation**: Message threads
- **Review**: Rating and review system
- **UserConnection**: Social connections
- **FriendActivity**: Social feed

### Key Relationships

```
User 1:N Gig (provider)
User 1:N Review (reviewer)
Gig 1:N Review
Gig 1:N Conversation
Conversation N:N User (participants)
Conversation 1:N Message
Message 1:1 User (sender)
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Code Style

- Follow Swift style guidelines
- Use meaningful variable names
- Add documentation comments
- Keep functions focused and small
- Use proper error handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Email: support@yourcompany.com
- Documentation: [docs.yourcompany.com](https://docs.yourcompany.com)
- Issues: [GitHub Issues](https://github.com/yourusername/GV2/issues)

## 🔄 Version History

- **v1.0.0**: Initial production release
- **v0.9.0**: Beta testing version
- **v0.8.0**: Core features implementation
- **v0.7.0**: UI/UX improvements
- **v0.6.0**: Backend integration
- **v0.5.0**: Basic functionality

---

**Built with ❤️ using SwiftUI and CoreData** 