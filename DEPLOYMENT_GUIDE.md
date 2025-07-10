# 🚀 GV2 App Store Deployment Guide

## Prerequisites

- **Apple Developer Account** ($99/year)
- **Xcode 16+** installed
- **Valid Bundle ID** registered in App Store Connect

## Step 1: Apple Developer Account Setup

### 1.1 Register Bundle ID
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** → **App IDs**
4. Select **App** and click **Continue**
5. Fill in:
   - **Description:** GV2 App
   - **Bundle ID:** `rightimagedigital.GV2`
   - **Capabilities:** 
     - ✅ CloudKit
     - ✅ Push Notifications
6. Click **Continue** → **Register**

### 1.2 Create Distribution Certificate
1. In **Certificates, Identifiers & Profiles**
2. Click **Certificates** → **+**
3. Select **iOS Distribution (App Store and Ad Hoc)**
4. Follow the instructions to create a CSR and upload it
5. Download and install the certificate

### 1.3 Create Provisioning Profile
1. Click **Profiles** → **+**
2. Select **iOS App Development** (for testing) or **App Store** (for distribution)
3. Select your App ID: `rightimagedigital.GV2`
4. Select your distribution certificate
5. Select your devices (for development profile)
6. Name it: `GV2 App Store Distribution`
7. Download and install the profile

## Step 2: Xcode Configuration

### 2.1 Add Apple Developer Account
1. Open **Xcode** → **Preferences** → **Accounts**
2. Click **+** → **Apple ID**
3. Sign in with your Apple Developer account
4. Select your team

### 2.2 Configure Project Signing
1. Open your project in Xcode
2. Select the **GV2** target
3. Go to **Signing & Capabilities**
4. Ensure:
   - ✅ **Automatically manage signing** is checked
   - **Team** is set to your Apple Developer team
   - **Bundle Identifier** is `rightimagedigital.GV2`

### 2.3 Verify Capabilities
Ensure these capabilities are added:
- ✅ **iCloud** (for CloudKit)
- ✅ **Push Notifications**
- ✅ **Background Modes** → **Remote notifications**

## Step 3: App Store Connect Setup

### 3.1 Create App Record
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platforms:** iOS
   - **Name:** GV2
   - **Primary Language:** English
   - **Bundle ID:** `rightimagedigital.GV2`
   - **SKU:** `GV2-2025` (unique identifier)
   - **User Access:** Full Access
4. Click **Create**

### 3.2 App Information
1. In your app record, go to **App Information**
2. Fill in:
   - **App Name:** GV2
   - **Subtitle:** Your app subtitle
   - **Category:** Choose appropriate category
   - **Content Rights:** Declare if you have rights to all content
   - **Age Rating:** Complete the questionnaire

### 3.3 Pricing and Availability
1. Go to **Pricing and Availability**
2. Set:
   - **Price:** Free or Paid
   - **Availability:** All countries or specific regions
   - **App Store Availability:** Available on App Store

## Step 4: Build and Archive

### 4.1 Clean Build
```bash
# Clean the project
xcodebuild clean -project GV2.xcodeproj -scheme GV2
```

### 4.2 Create Archive
```bash
# Create production archive
xcodebuild -project GV2.xcodeproj -scheme GV2 -configuration Release -destination 'generic/platform=iOS' archive -archivePath ./GV2.xcarchive -allowProvisioningUpdates
```

### 4.3 Export IPA
```bash
# Export for App Store
xcodebuild -exportArchive -archivePath ./GV2.xcarchive -exportPath ./GV2-Export -exportOptionsPlist ./Config/ExportOptions.plist
```

## Step 5: Upload to App Store Connect

### 5.1 Using Xcode Organizer
1. In Xcode, go to **Window** → **Organizer**
2. Select your archive
3. Click **Distribute App**
4. Choose **App Store Connect**
5. Select **Upload**
6. Follow the wizard

### 5.2 Using Command Line
```bash
# Upload to App Store Connect
xcrun altool --upload-app --type ios --file ./GV2-Export/GV2.ipa --username "your-apple-id@email.com" --password "app-specific-password"
```

## Step 6: App Store Submission

### 6.1 App Store Information
1. In App Store Connect, go to **App Store** tab
2. Fill in:
   - **App Description:** Detailed description of your app
   - **Keywords:** Relevant search terms
   - **Support URL:** Your support website
   - **Marketing URL:** Your app's marketing page

### 6.2 Screenshots
1. Upload screenshots for all required device sizes:
   - iPhone 6.7" (iPhone 14 Pro Max)
   - iPhone 6.5" (iPhone 11 Pro Max)
   - iPhone 5.5" (iPhone 8 Plus)
   - iPad Pro 12.9" (6th generation)
   - iPad Pro 12.9" (2nd generation)

### 6.3 App Review Information
1. Fill in:
   - **Contact Information:** Your contact details
   - **Demo Account:** Test account for reviewers
   - **Notes:** Any special instructions for reviewers

### 6.4 Version Release
1. Set **Version Release** to:
   - **Automatically release this version** (recommended)
   - **Manually release this version** (if you want control)

## Step 7: Submit for Review

1. Click **Save** on all sections
2. Click **Submit for Review**
3. Answer any additional questions
4. Submit the app

## Troubleshooting

### Common Issues

#### "No profiles found"
- Ensure your Apple Developer account is properly set up
- Check that the bundle ID matches in Xcode and App Store Connect
- Verify your provisioning profiles are installed

#### "Code signing failed"
- Clean and rebuild the project
- Check that your certificates are valid
- Ensure automatic signing is enabled

#### "Archive failed"
- Check that all required capabilities are added
- Verify your entitlements file is correct
- Ensure all dependencies are properly configured

### Useful Commands

```bash
# Check provisioning profiles
security find-identity -v -p codesigning

# List installed certificates
security find-certificate -a -c "Apple Development"

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Next Steps After Approval

1. **Monitor Analytics** in App Store Connect
2. **Respond to Reviews** promptly
3. **Update App** regularly with new features
4. **Monitor Crash Reports** and fix issues
5. **Engage with Users** through feedback

## Support

If you encounter issues:
1. Check [Apple Developer Documentation](https://developer.apple.com/documentation/)
2. Review [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
3. Contact [Apple Developer Support](https://developer.apple.com/contact/)

---

**Good luck with your App Store submission! 🎉** 