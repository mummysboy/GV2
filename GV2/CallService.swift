import Foundation
import AVFoundation
import Combine

enum CallStatus {
    case idle
    case connecting
    case connected
    case ended
    case failed
}

enum CallType {
    case audio
    case video
}

struct CallParticipant {
    let userId: String
    let name: String
    let isMuted: Bool
    let isLocal: Bool
}

class CallService: ObservableObject {
    @Published var callStatus: CallStatus = .idle
    @Published var callType: CallType = .audio
    @Published var participants: [CallParticipant] = []
    @Published var isMuted: Bool = false
    @Published var isSpeakerOn: Bool = false
    @Published var callDuration: TimeInterval = 0
    
    private var timer: Timer?
    private var audioSession: AVAudioSession?
    private var currentCallId: String?
    
    func startCall(with userId: String, type: CallType = .audio) {
        callStatus = .connecting
        callType = type
        currentCallId = UUID().uuidString
        
        // Initialize audio session
        setupAudioSession()
        
        // Add participants
        participants = [
            CallParticipant(userId: "current", name: "You", isMuted: false, isLocal: true),
            CallParticipant(userId: userId, name: "Provider", isMuted: false, isLocal: false)
        ]
        
        // Simulate call connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.callStatus = .connected
            self.startCallTimer()
        }
    }
    
    func endCall() {
        callStatus = .ended
        stopCallTimer()
        resetAudioSession()
        currentCallId = nil
    }
    
    // Process call transcript for service completion detection
    func processCallTranscript(_ transcript: String, from: User, to: User, gigId: String) {
        // In a real app, this would be called with actual transcript data
        // For now, this is a placeholder for the conversation monitor integration
        print("Call transcript processed: \(transcript)")
    }
    
    func toggleMute() {
        isMuted.toggle()
        
        // Update local participant
        if let index = participants.firstIndex(where: { $0.isLocal }) {
            participants[index] = CallParticipant(
                userId: participants[index].userId,
                name: participants[index].name,
                isMuted: isMuted,
                isLocal: true
            )
        }
        
        // In a real app, this would send mute state to the other participant
    }
    
    func toggleSpeaker() {
        isSpeakerOn.toggle()
        
        do {
            try audioSession?.setCategory(
                isSpeakerOn ? .playAndRecord : .playAndRecord,
                options: isSpeakerOn ? .defaultToSpeaker : []
            )
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession?.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
            callStatus = .failed
        }
    }
    
    private func resetAudioSession() {
        do {
            try audioSession?.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    private func startCallTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.callDuration += 1
        }
    }
    
    private func stopCallTimer() {
        timer?.invalidate()
        timer = nil
        callDuration = 0
    }
    
    // AI Moderation for calls
    func processAudioForModeration(audioData: Data) {
        // In a real app, this would:
        // 1. Send audio to a transcription service (OpenAI Whisper, Google Speech-to-Text)
        // 2. Process the transcript for inappropriate content
        // 3. Log violations or take action
        
        // For now, we'll simulate this process
        DispatchQueue.global(qos: .background).async {
            // Simulate audio processing
            Thread.sleep(forTimeInterval: 0.5)
            
            DispatchQueue.main.async {
                // Check for violations (simulated)
                let hasViolation = Bool.random()
                if hasViolation {
                    self.handleModerationViolation()
                }
            }
        }
    }
    
    private func handleModerationViolation() {
        // In a real app, this would:
        // 1. Log the violation
        // 2. Send warning to user
        // 3. Potentially end the call for serious violations
        
        print("Moderation violation detected in call")
        // For now, we'll just log it
    }
} 