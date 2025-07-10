//
//  ErrorHandling.swift
//  GV2
//
//  Created by Isaac Hirsch on 7/9/25.
//

import Foundation
import SwiftUI

// MARK: - App Error Types
enum AppError: LocalizedError, Identifiable {
    case networkError(NetworkError)
    case dataError(DataError)
    case validationError(ValidationError)
    case authenticationError(AuthenticationError)
    case permissionError(PermissionError)
    case unknownError(Error)
    
    var id: String {
        switch self {
        case .networkError(let error): return "network_\(error.id)"
        case .dataError(let error): return "data_\(error.id)"
        case .validationError(let error): return "validation_\(error.id)"
        case .authenticationError(let error): return "auth_\(error.id)"
        case .permissionError(let error): return "permission_\(error.id)"
        case .unknownError(let error): return "unknown_\(error.localizedDescription.hashValue)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return error.localizedDescription
        case .dataError(let error):
            return error.localizedDescription
        case .validationError(let error):
            return error.localizedDescription
        case .authenticationError(let error):
            return error.localizedDescription
        case .permissionError(let error):
            return error.localizedDescription
        case .unknownError(let error):
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError(let error):
            return error.recoverySuggestion
        case .dataError(let error):
            return error.recoverySuggestion
        case .validationError(let error):
            return error.recoverySuggestion
        case .authenticationError(let error):
            return error.recoverySuggestion
        case .permissionError(let error):
            return error.recoverySuggestion
        case .unknownError:
            return "Please try again later. If the problem persists, contact support."
        }
    }
    
    var shouldShowToUser: Bool {
        switch self {
        case .networkError(let error):
            return error.shouldShowToUser
        case .dataError(let error):
            return error.shouldShowToUser
        case .validationError:
            return true // Always show validation errors
        case .authenticationError:
            return true // Always show auth errors
        case .permissionError:
            return true // Always show permission errors
        case .unknownError:
            return false // Don't show unknown errors to users
        }
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError, Identifiable {
    case noInternetConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case rateLimited
    
    var id: String {
        switch self {
        case .noInternetConnection: return "no_internet"
        case .timeout: return "timeout"
        case .serverError(let code): return "server_error_\(code)"
        case .invalidResponse: return "invalid_response"
        case .rateLimited: return "rate_limited"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .noInternetConnection:
            return "No Internet Connection"
        case .timeout:
            return "Request Timed Out"
        case .serverError(let code):
            return "Server Error (\(code))"
        case .invalidResponse:
            return "Invalid Response"
        case .rateLimited:
            return "Too Many Requests"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Please check your internet connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .serverError:
            return "We're experiencing technical difficulties. Please try again later."
        case .invalidResponse:
            return "The server returned an unexpected response. Please try again."
        case .rateLimited:
            return "You've made too many requests. Please wait a moment and try again."
        }
    }
    
    var shouldShowToUser: Bool {
        return true
    }
}

// MARK: - Data Errors
enum DataError: LocalizedError, Identifiable {
    case saveFailed
    case loadFailed
    case deleteFailed
    case syncFailed
    case corruptedData
    
    var id: String {
        switch self {
        case .saveFailed: return "save_failed"
        case .loadFailed: return "load_failed"
        case .deleteFailed: return "delete_failed"
        case .syncFailed: return "sync_failed"
        case .corruptedData: return "corrupted_data"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .saveFailed:
            return "Failed to Save Data"
        case .loadFailed:
            return "Failed to Load Data"
        case .deleteFailed:
            return "Failed to Delete Data"
        case .syncFailed:
            return "Sync Failed"
        case .corruptedData:
            return "Data Corruption Detected"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed:
            return "Please try saving again. If the problem persists, restart the app."
        case .loadFailed:
            return "Please try refreshing the data. If the problem persists, restart the app."
        case .deleteFailed:
            return "Please try deleting again. If the problem persists, restart the app."
        case .syncFailed:
            return "Please check your internet connection and try syncing again."
        case .corruptedData:
            return "Your data appears to be corrupted. Please contact support for assistance."
        }
    }
    
    var shouldShowToUser: Bool {
        return true
    }
}

// MARK: - Validation Errors
enum ValidationError: LocalizedError, Identifiable {
    case invalidEmail
    case invalidPhone
    case invalidPassword
    case requiredField(String)
    case invalidFormat(String)
    case tooShort(String, Int)
    case tooLong(String, Int)
    
    var id: String {
        switch self {
        case .invalidEmail: return "invalid_email"
        case .invalidPhone: return "invalid_phone"
        case .invalidPassword: return "invalid_password"
        case .requiredField(let field): return "required_\(field)"
        case .invalidFormat(let field): return "invalid_format_\(field)"
        case .tooShort(let field, _): return "too_short_\(field)"
        case .tooLong(let field, _): return "too_long_\(field)"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .invalidEmail:
            return "Invalid Email Address"
        case .invalidPhone:
            return "Invalid Phone Number"
        case .invalidPassword:
            return "Invalid Password"
        case .requiredField(let field):
            return "\(field) is Required"
        case .invalidFormat(let field):
            return "Invalid \(field) Format"
        case .tooShort(let field, let min):
            return "\(field) Must Be At Least \(min) Characters"
        case .tooLong(let field, let max):
            return "\(field) Must Be No More Than \(max) Characters"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address (e.g., user@example.com)."
        case .invalidPhone:
            return "Please enter a valid phone number (e.g., +1-555-123-4567)."
        case .invalidPassword:
            return "Password must be at least 8 characters and contain letters and numbers."
        case .requiredField:
            return "Please fill in all required fields."
        case .invalidFormat:
            return "Please check the format and try again."
        case .tooShort(_, let min):
            return "Please enter at least \(min) characters."
        case .tooLong(_, let max):
            return "Please enter no more than \(max) characters."
        }
    }
}

// MARK: - Authentication Errors
enum AuthenticationError: LocalizedError, Identifiable {
    case invalidCredentials
    case accountLocked
    case emailNotVerified
    case sessionExpired
    case unauthorized
    
    var id: String {
        switch self {
        case .invalidCredentials: return "invalid_credentials"
        case .accountLocked: return "account_locked"
        case .emailNotVerified: return "email_not_verified"
        case .sessionExpired: return "session_expired"
        case .unauthorized: return "unauthorized"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .invalidCredentials:
            return "Invalid Credentials"
        case .accountLocked:
            return "Account Locked"
        case .emailNotVerified:
            return "Email Not Verified"
        case .sessionExpired:
            return "Session Expired"
        case .unauthorized:
            return "Unauthorized"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Please check your email and password and try again."
        case .accountLocked:
            return "Your account has been locked. Please contact support."
        case .emailNotVerified:
            return "Please verify your email address before signing in."
        case .sessionExpired:
            return "Please sign in again to continue."
        case .unauthorized:
            return "You don't have permission to perform this action."
        }
    }
}

// MARK: - Permission Errors
enum PermissionError: LocalizedError, Identifiable {
    case cameraAccessDenied
    case photoLibraryAccessDenied
    case locationAccessDenied
    case notificationAccessDenied
    case microphoneAccessDenied
    
    var id: String {
        switch self {
        case .cameraAccessDenied: return "camera_denied"
        case .photoLibraryAccessDenied: return "photo_library_denied"
        case .locationAccessDenied: return "location_denied"
        case .notificationAccessDenied: return "notification_denied"
        case .microphoneAccessDenied: return "microphone_denied"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .cameraAccessDenied:
            return "Camera Access Denied"
        case .photoLibraryAccessDenied:
            return "Photo Library Access Denied"
        case .locationAccessDenied:
            return "Location Access Denied"
        case .notificationAccessDenied:
            return "Notification Access Denied"
        case .microphoneAccessDenied:
            return "Microphone Access Denied"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .cameraAccessDenied:
            return "Please enable camera access in Settings > Privacy & Security > Camera."
        case .photoLibraryAccessDenied:
            return "Please enable photo library access in Settings > Privacy & Security > Photos."
        case .locationAccessDenied:
            return "Please enable location access in Settings > Privacy & Security > Location Services."
        case .notificationAccessDenied:
            return "Please enable notifications in Settings > Notifications."
        case .microphoneAccessDenied:
            return "Please enable microphone access in Settings > Privacy & Security > Microphone."
        }
    }
}

// MARK: - Error Handler
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showingError = false
    
    func handle(_ error: Error) {
        let appError: AppError
        
        if let networkError = error as? NetworkError {
            appError = .networkError(networkError)
        } else if let dataError = error as? DataError {
            appError = .dataError(dataError)
        } else if let validationError = error as? ValidationError {
            appError = .validationError(validationError)
        } else if let authError = error as? AuthenticationError {
            appError = .authenticationError(authError)
        } else if let permissionError = error as? PermissionError {
            appError = .permissionError(permissionError)
        } else {
            appError = .unknownError(error)
        }
        
        // Log error for debugging
        ConfigurationManager.shared.log("Error occurred: \(appError.localizedDescription)", level: .error)
        
        // Only show user-facing errors
        if appError.shouldShowToUser {
            DispatchQueue.main.async {
                self.currentError = appError
                self.showingError = true
            }
        }
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
}

// MARK: - Error Alert View
struct ErrorAlert: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showingError) {
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.localizedDescription)
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func errorAlert(errorHandler: ErrorHandler) -> some View {
        modifier(ErrorAlert(errorHandler: errorHandler))
    }
} 