//
//  ConfigurationManager.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import Foundation

struct ConfigurationManager {
    static let shared = ConfigurationManager()
    
    // MARK: - Environment Configuration
    enum Environment: String {
        case development = "Development"
        case production = "Production"
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
    
    // MARK: - API Configuration
    var apiBaseURL: String {
        guard let url = Bundle.main.infoDictionary?["API_BASE_URL"] as? String else {
            fatalError("API_BASE_URL not found in configuration")
        }
        return url
    }
    
    var apiTimeout: TimeInterval {
        guard let timeout = Bundle.main.infoDictionary?["API_TIMEOUT"] as? String,
              let timeoutValue = Double(timeout) else {
            return 30.0
        }
        return timeoutValue
    }
    
    // MARK: - Feature Flags
    var enableLogging: Bool {
        guard let logging = Bundle.main.infoDictionary?["ENABLE_LOGGING"] as? String else {
            return false
        }
        return logging == "YES"
    }
    
    var enableAnalytics: Bool {
        guard let analytics = Bundle.main.infoDictionary?["ENABLE_ANALYTICS"] as? String else {
            return false
        }
        return analytics == "YES"
    }
    
    var enableFirebaseAnalytics: Bool {
        guard let firebase = Bundle.main.infoDictionary?["ENABLE_FIREBASE_ANALYTICS"] as? String else {
            return false
        }
        return firebase == "YES"
    }
    
    var enableMixpanelAnalytics: Bool {
        guard let mixpanel = Bundle.main.infoDictionary?["ENABLE_MIXPANEL_ANALYTICS"] as? String else {
            return false
        }
        return mixpanel == "YES"
    }
    
    var enableDebugMenu: Bool {
        guard let debugMenu = Bundle.main.infoDictionary?["ENABLE_DEBUG_MENU"] as? String else {
            return false
        }
        return debugMenu == "YES"
    }
    
    var enableSampleData: Bool {
        guard let sampleData = Bundle.main.infoDictionary?["ENABLE_SAMPLE_DATA"] as? String else {
            return false
        }
        return sampleData == "YES"
    }
    
    var enableCrashReporting: Bool {
        guard let crashReporting = Bundle.main.infoDictionary?["ENABLE_CRASH_REPORTING"] as? String else {
            return false
        }
        return crashReporting == "YES"
    }
    
    // MARK: - CloudKit Configuration
    var cloudKitContainerIdentifier: String {
        guard let identifier = Bundle.main.infoDictionary?["CLOUDKIT_CONTAINER_IDENTIFIER"] as? String else {
            fatalError("CLOUDKIT_CONTAINER_IDENTIFIER not found in configuration")
        }
        return identifier
    }
    
    // MARK: - Secure API Keys
    var apiKeys: [String: String] {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            print("Warning: Secrets.plist not found or invalid")
            return [:]
        }
        return dict
    }
    
    // MARK: - App Store Configuration
    var appStoreConfiguration: AppStoreConfiguration {
        return AppStoreConfiguration(
            privacyPolicyURL: "https://yourcompany.com/privacy",
            termsOfServiceURL: "https://yourcompany.com/terms",
            supportEmail: "support@yourcompany.com",
            appStoreURL: "https://apps.apple.com/app/id123456789"
        )
    }
}

// MARK: - App Store Configuration
struct AppStoreConfiguration {
    let privacyPolicyURL: String
    let termsOfServiceURL: String
    let supportEmail: String
    let appStoreURL: String
}

// MARK: - Logging
extension ConfigurationManager {
    func log(_ message: String, level: LogLevel = .info) {
        guard enableLogging else { return }
        
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue.uppercased())] \(message)"
        
        #if DEBUG
        print(logMessage)
        #else
        // In production, send to crash reporting service
        if enableCrashReporting {
            // Send to Crashlytics or similar service
            // Crashlytics.crashlytics().log(logMessage)
        }
        #endif
    }
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
} 