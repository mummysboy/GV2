//
//  GV2App.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import SwiftUI
import CoreData

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

@main
struct GV2App: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var analytics = AnalyticsService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(errorHandler)
                .environmentObject(analytics)
                .errorAlert(errorHandler: errorHandler)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: .coreDataLoadFailed)) { notification in
                    if let error = notification.userInfo?["error"] as? Error {
                        errorHandler.handle(DataError.loadFailed)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .coreDataSaveFailed)) { notification in
                    if let error = notification.userInfo?["error"] as? Error {
                        errorHandler.handle(DataError.saveFailed)
                    }
                }
        }
    }
    
    private func setupApp() {
        // Track app launch
        analytics.trackEvent(.appLaunch)
        
        // Log app startup
        ConfigurationManager.shared.log("App launched successfully", level: .info)
        
        #if DEBUG
        // Development-specific setup
        ConfigurationManager.shared.log("Running in DEBUG mode", level: .debug)
        #else
        // Production-specific setup
        ConfigurationManager.shared.log("Running in PRODUCTION mode", level: .info)
        #endif
        
        // Setup crash reporting if enabled
        if ConfigurationManager.shared.enableCrashReporting {
            setupCrashReporting()
        }
    }
    
    private func setupCrashReporting() {
        #if canImport(FirebaseCrashlytics)
        // Configure Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
    }
}
