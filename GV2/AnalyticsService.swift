//
//  AnalyticsService.swift
//  Gig
//
//  Created by Isaac Hirsch on 7/9/25.
//

import Foundation
import SwiftUI

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

#if canImport(Mixpanel)
import Mixpanel
#endif

// MARK: - Analytics Event Types
enum AnalyticsEvent {
    case appLaunch
    case userSignUp(method: String)
    case userSignIn(method: String)
    case userSignOut
    case gigCreated(category: String)
    case gigViewed(gigId: String, category: String)
    case gigBooked(gigId: String, price: Double)
    case gigReviewed(gigId: String, rating: Int)
    case messageSent(conversationId: String)
    case profileUpdated
    case searchPerformed(query: String, results: Int)
    case filterApplied(filters: [String])
    case paymentInitiated(amount: Double, method: String)
    case paymentCompleted(amount: Double, method: String)
    case errorOccurred(error: String, screen: String)
    case featureUsed(feature: String)
    case screenViewed(screen: String)
    case buttonTapped(button: String, screen: String)
    
    var name: String {
        switch self {
        case .appLaunch: return "app_launch"
        case .userSignUp: return "user_sign_up"
        case .userSignIn: return "user_sign_in"
        case .userSignOut: return "user_sign_out"
        case .gigCreated: return "gig_created"
        case .gigViewed: return "gig_viewed"
        case .gigBooked: return "gig_booked"
        case .gigReviewed: return "gig_reviewed"
        case .messageSent: return "message_sent"
        case .profileUpdated: return "profile_updated"
        case .searchPerformed: return "search_performed"
        case .filterApplied: return "filter_applied"
        case .paymentInitiated: return "payment_initiated"
        case .paymentCompleted: return "payment_completed"
        case .errorOccurred: return "error_occurred"
        case .featureUsed: return "feature_used"
        case .screenViewed: return "screen_viewed"
        case .buttonTapped: return "button_tapped"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .appLaunch:
            return [:]
        case .userSignUp(let method):
            return ["signup_method": method]
        case .userSignIn(let method):
            return ["signin_method": method]
        case .userSignOut:
            return [:]
        case .gigCreated(let category):
            return ["category": category]
        case .gigViewed(let gigId, let category):
            return ["gig_id": gigId, "category": category]
        case .gigBooked(let gigId, let price):
            return ["gig_id": gigId, "price": price]
        case .gigReviewed(let gigId, let rating):
            return ["gig_id": gigId, "rating": rating]
        case .messageSent(let conversationId):
            return ["conversation_id": conversationId]
        case .profileUpdated:
            return [:]
        case .searchPerformed(let query, let results):
            return ["query": query, "results_count": results]
        case .filterApplied(let filters):
            return ["filters": filters.joined(separator: ",")]
        case .paymentInitiated(let amount, let method):
            return ["amount": amount, "payment_method": method]
        case .paymentCompleted(let amount, let method):
            return ["amount": amount, "payment_method": method]
        case .errorOccurred(let error, let screen):
            return ["error": error, "screen": screen]
        case .featureUsed(let feature):
            return ["feature": feature]
        case .screenViewed(let screen):
            return ["screen": screen]
        case .buttonTapped(let button, let screen):
            return ["button": button, "screen": screen]
        }
    }
}

// MARK: - Analytics Service Protocol
protocol AnalyticsProvider {
    func trackEvent(_ event: AnalyticsEvent)
    func setUserProperty(_ property: String, value: Any)
    func setUserId(_ userId: String)
    func resetUser()
}

// MARK: - Firebase Analytics Provider
class FirebaseAnalyticsProvider: AnalyticsProvider {
    func trackEvent(_ event: AnalyticsEvent) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(event.name, parameters: event.parameters)
        #else
        print("Firebase Analytics not available")
        #endif
    }
    
    func setUserProperty(_ property: String, value: Any) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty("\(value)", forName: property)
        #else
        print("Firebase Analytics not available")
        #endif
    }
    
    func setUserId(_ userId: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserID(userId)
        #else
        print("Firebase Analytics not available")
        #endif
    }
    
    func resetUser() {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserID(nil)
        #else
        print("Firebase Analytics not available")
        #endif
    }
}

// MARK: - Mixpanel Analytics Provider
class MixpanelAnalyticsProvider: AnalyticsProvider {
    func trackEvent(_ event: AnalyticsEvent) {
        #if canImport(Mixpanel)
        Mixpanel.mainInstance().track(event: event.name, properties: event.parameters)
        #else
        print("Mixpanel not available")
        #endif
    }
    
    func setUserProperty(_ property: String, value: Any) {
        #if canImport(Mixpanel)
        Mixpanel.mainInstance().people.set(property: property, to: value)
        #else
        print("Mixpanel not available")
        #endif
    }
    
    func setUserId(_ userId: String) {
        #if canImport(Mixpanel)
        Mixpanel.mainInstance().identify(distinctId: userId)
        #else
        print("Mixpanel not available")
        #endif
    }
    
    func resetUser() {
        #if canImport(Mixpanel)
        Mixpanel.mainInstance().reset()
        #else
        print("Mixpanel not available")
        #endif
    }
}

// MARK: - Console Analytics Provider (Development)
class ConsoleAnalyticsProvider: AnalyticsProvider {
    func trackEvent(_ event: AnalyticsEvent) {
        let paramsString = event.parameters.isEmpty ? "" : " with parameters: \(event.parameters)"
        print("📊 Analytics Event: \(event.name)\(paramsString)")
    }
    
    func setUserProperty(_ property: String, value: Any) {
        print("📊 User Property: \(property) = \(value)")
    }
    
    func setUserId(_ userId: String) {
        print("📊 User ID: \(userId)")
    }
    
    func resetUser() {
        print("📊 User Reset")
    }
}

// MARK: - Main Analytics Service
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private var providers: [AnalyticsProvider] = []
    private let configuration = ConfigurationManager.shared
    
    private init() {
        setupProviders()
    }
    
    private func setupProviders() {
        // Always add console provider for development
        providers.append(ConsoleAnalyticsProvider())
        
        // Add Firebase Analytics if enabled and available
        if configuration.enableFirebaseAnalytics {
            providers.append(FirebaseAnalyticsProvider())
        }
        
        // Add Mixpanel if enabled and available
        if configuration.enableMixpanelAnalytics {
            providers.append(MixpanelAnalyticsProvider())
        }
    }
    
    func trackEvent(_ event: AnalyticsEvent) {
        for provider in providers {
            provider.trackEvent(event)
        }
    }
    
    func setUserProperty(_ property: String, value: Any) {
        for provider in providers {
            provider.setUserProperty(property, value: value)
        }
    }
    
    func setUserId(_ userId: String) {
        for provider in providers {
            provider.setUserId(userId)
        }
    }
    
    func resetUser() {
        for provider in providers {
            provider.resetUser()
        }
    }
    
    // MARK: - Convenience Methods
    func trackScreenView(_ screen: String) {
        trackEvent(.screenViewed(screen: screen))
    }
    
    func trackButtonTap(_ button: String, screen: String) {
        trackEvent(.buttonTapped(button: button, screen: screen))
    }
    
    func trackError(_ error: String, screen: String) {
        trackEvent(.errorOccurred(error: error, screen: screen))
    }
    
    func trackFeatureUsage(_ feature: String) {
        trackEvent(.featureUsed(feature: feature))
    }
}

// MARK: - SwiftUI View Extension
extension View {
    func trackScreenView(_ screen: String) -> some View {
        self.onAppear {
            AnalyticsService.shared.trackScreenView(screen)
        }
    }
    
    func trackButtonTap(_ button: String, screen: String) -> some View {
        self.onTapGesture {
            AnalyticsService.shared.trackButtonTap(button, screen: screen)
        }
    }
} 