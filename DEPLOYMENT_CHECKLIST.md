# ✅ GV2 App Store Deployment Checklist

## Pre-Deployment Verification

### 🔧 Technical Requirements
- [ ] **Apple Developer Account** ($99/year) - Active and paid
- [ ] **Bundle ID** `rightimagedigital.GV2` registered in Apple Developer Portal
- [ ] **Distribution Certificate** created and installed
- [ ] **Provisioning Profile** created for App Store distribution
- [ ] **Xcode 16+** installed and updated

### 📱 App Configuration
- [ ] **Bundle Identifier** matches: `rightimagedigital.GV2`
- [ ] **Version** and **Build Number** set appropriately
- [ ] **App Icon** in all required sizes (1024x1024, etc.)
- [ ] **Launch Screen** configured and tested
- [ ] **Info.plist** contains all required keys

### 🔐 Signing & Capabilities
- [ ] **Automatic Signing** enabled in Xcode
- [ ] **Team** selected correctly
- [ ] **iCloud Capability** added (for CloudKit)
- [ ] **Push Notifications** capability added
- [ ] **Background Modes** configured for remote notifications
- [ ] **Entitlements** file properly configured

### 🧪 Testing
- [ ] **App builds successfully** in Release configuration
- [ ] **All features tested** on physical device
- [ ] **CloudKit sync** working properly
- [ ] **Push notifications** tested
- [ ] **No debug code** or test data in production build
- [ ] **Crash-free** during testing

### 📋 App Store Connect
- [ ] **App record created** in App Store Connect
- [ ] **Bundle ID** matches between Xcode and App Store Connect
- [ ] **App Information** filled out completely
- [ ] **Screenshots** uploaded for all required device sizes
- [ ] **App Description** written and reviewed
- [ ] **Keywords** optimized for App Store search
- [ ] **Age Rating** questionnaire completed
- [ ] **Privacy Policy** URL provided (if required)

### 🎨 App Store Assets
- [ ] **App Icon** (1024x1024 PNG)
- [ ] **App Preview Videos** (optional but recommended)
- [ ] **Screenshots** for iPhone 6.7", 6.5", 5.5"
- [ ] **Screenshots** for iPad Pro 12.9" (if iPad supported)
- [ ] **App Description** compelling and accurate
- [ ] **What's New** text for updates

### 📝 Legal & Compliance
- [ ] **Privacy Policy** created and hosted
- [ ] **Terms of Service** (if applicable)
- [ ] **App Privacy** details filled out in App Store Connect
- [ ] **Export Compliance** questions answered
- [ ] **Content Rights** declared
- [ ] **Age Rating** appropriate for app content

### 🔍 Final Review
- [ ] **App name** is unique and available
- [ ] **No trademark violations** in app name or content
- [ ] **App Store Guidelines** compliance verified
- [ ] **No placeholder text** or images
- [ ] **All links** work correctly
- [ ] **App functionality** matches description

## Build Commands

### Clean Build
```bash
xcodebuild clean -project GV2.xcodeproj -scheme GV2
```

### Create Archive
```bash
xcodebuild -project GV2.xcodeproj -scheme GV2 -configuration Release -destination 'generic/platform=iOS' archive -archivePath ./GV2.xcarchive -allowProvisioningUpdates
```

### Export IPA
```bash
xcodebuild -exportArchive -archivePath ./GV2.xcarchive -exportPath ./GV2-Export -exportOptionsPlist ./Config/ExportOptions.plist
```

## Quick Test Commands

### Verify Signing
```bash
# Check if app is properly signed
codesign -dv --verbose=4 ./GV2-Export/GV2.ipa
```

### Validate IPA
```bash
# Validate IPA for App Store
xcrun altool --validate-app --type ios --file ./GV2-Export/GV2.ipa --username "your-apple-id@email.com" --password "app-specific-password"
```

## Submission Checklist

### Before Submitting
- [ ] **Archive created** successfully
- [ ] **IPA exported** without errors
- [ ] **App uploaded** to App Store Connect
- [ ] **Build processed** successfully
- [ ] **All metadata** completed in App Store Connect
- [ ] **Screenshots** uploaded and approved
- [ ] **App Review Information** filled out

### Submit for Review
- [ ] **Save** all changes in App Store Connect
- [ ] **Submit for Review** button clicked
- [ ] **Review questions** answered
- [ ] **Submission confirmed**

## Post-Submission

### Monitor Review
- [ ] **Check review status** daily in App Store Connect
- [ ] **Respond to feedback** if app is rejected
- [ ] **Fix issues** and resubmit if needed

### After Approval
- [ ] **App appears** on App Store
- [ ] **Test download** and installation
- [ ] **Monitor analytics** and reviews
- [ ] **Plan next update**

---

## 🚨 Common Rejection Reasons

- **Missing Privacy Policy** for apps that collect user data
- **Incomplete App Information** or placeholder text
- **App crashes** during review
- **Misleading app description** or screenshots
- **Missing required permissions** explanation
- **Inappropriate content** or age rating mismatch

## 📞 Support Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Apple Developer Support](https://developer.apple.com/contact/)

---

**✅ Complete this checklist before submitting to ensure a smooth App Store review process!** 