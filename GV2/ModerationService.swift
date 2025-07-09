import Foundation
import Combine

enum ModerationLevel {
    case safe
    case warning
    case violation
    case severe
}

struct ModerationResult {
    let level: ModerationLevel
    let categories: [String]
    let confidence: Double
    let flaggedContent: String?
    let action: ModerationAction
}

enum ModerationAction {
    case allow
    case warn
    case block
    case report
    case endCall
}

class ModerationService: ObservableObject {
    @Published var moderationLog: [ModerationLogEntry] = []
    @Published var isProcessing = false
    
    private let apiKey: String? // For OpenAI or other moderation APIs
    
    init(apiKey: String? = nil) {
        self.apiKey = apiKey
    }
    
    // Moderate chat messages
    func moderateMessage(_ content: String, senderId: String) async -> ModerationResult {
        isProcessing = true
        
        // In a real app, this would call OpenAI Moderation API or similar
        // For now, we'll simulate the moderation process
        
        let result = await simulateModeration(content: content)
        
        // Log the moderation result
        let logEntry = ModerationLogEntry(
            id: UUID(),
            timestamp: Date(),
            contentType: .message,
            content: content,
            senderId: senderId,
            result: result
        )
        
        DispatchQueue.main.async {
            self.moderationLog.append(logEntry)
            self.isProcessing = false
        }
        
        return result
    }
    
    // Moderate call audio (transcript)
    func moderateCallTranscript(_ transcript: String, participantId: String) async -> ModerationResult {
        isProcessing = true
        
        let result = await simulateModeration(content: transcript)
        
        let logEntry = ModerationLogEntry(
            id: UUID(),
            timestamp: Date(),
            contentType: .call,
            content: transcript,
            senderId: participantId,
            result: result
        )
        
        DispatchQueue.main.async {
            self.moderationLog.append(logEntry)
            self.isProcessing = false
        }
        
        return result
    }
    
    // Check for inappropriate content patterns
    private func checkContentPatterns(_ content: String) -> (level: ModerationLevel, categories: [String]) {
        let lowercased = content.lowercased()
        
        // Define inappropriate patterns (simplified for demo)
        let severePatterns = ["kill", "bomb", "terrorist", "suicide"]
        let violationPatterns = ["hate", "racist", "sexist", "harassment"]
        let warningPatterns = ["stupid", "idiot", "dumb", "ugly"]
        
        let severeMatches = severePatterns.filter { lowercased.contains($0) }
        let violationMatches = violationPatterns.filter { lowercased.contains($0) }
        let warningMatches = warningPatterns.filter { lowercased.contains($0) }
        
        if !severeMatches.isEmpty {
            return (.severe, severeMatches)
        } else if !violationMatches.isEmpty {
            return (.violation, violationMatches)
        } else if !warningMatches.isEmpty {
            return (.warning, warningMatches)
        } else {
            return (.safe, [])
        }
    }
    
    private func simulateModeration(content: String) async -> ModerationResult {
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let (level, categories) = checkContentPatterns(content)
        
        let confidence = Double.random(in: 0.7...1.0)
        let flaggedContent = categories.isEmpty ? nil : categories.joined(separator: ", ")
        
        let action: ModerationAction
        switch level {
        case .safe:
            action = .allow
        case .warning:
            action = .warn
        case .violation:
            action = .block
        case .severe:
            action = .report
        }
        
        return ModerationResult(
            level: level,
            categories: categories,
            confidence: confidence,
            flaggedContent: flaggedContent,
            action: action
        )
    }
    
    // Get moderation statistics
    func getModerationStats() -> ModerationStats {
        let totalEntries = moderationLog.count
        let violations = moderationLog.filter { $0.result.level == .violation || $0.result.level == .severe }.count
        let warnings = moderationLog.filter { $0.result.level == .warning }.count
        
        return ModerationStats(
            totalModerated: totalEntries,
            violations: violations,
            warnings: warnings,
            safeContent: totalEntries - violations - warnings
        )
    }
    
    // Clear moderation log
    func clearLog() {
        moderationLog.removeAll()
    }
}

struct ModerationLogEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let contentType: ContentType
    let content: String
    let senderId: String
    let result: ModerationResult
    
    enum ContentType {
        case message
        case call
    }
}

struct ModerationStats {
    let totalModerated: Int
    let violations: Int
    let warnings: Int
    let safeContent: Int
    
    var violationRate: Double {
        guard totalModerated > 0 else { return 0 }
        return Double(violations) / Double(totalModerated)
    }
} 