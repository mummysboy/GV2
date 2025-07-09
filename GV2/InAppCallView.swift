import SwiftUI
import AVFoundation

struct InAppCallView: View {
    let provider: User
    @Environment(\.dismiss) private var dismiss
    @StateObject private var callService = CallService()
    @StateObject private var moderationService = ModerationService()
    
    @State private var showingModerationAlert = false
    @State private var moderationResult: ModerationResult?
    @State private var callTranscript = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Call status and provider info
                VStack(spacing: 20) {
                    // Provider avatar
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(String(provider.name?.prefix(1) ?? "U"))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.purple)
                        )
                    
                    // Provider name and status
                    VStack(spacing: 8) {
                        Text(provider.name ?? "Unknown Provider")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(callStatusText)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if callService.callStatus == .connected {
                            Text(formatCallDuration(callService.callDuration))
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Call controls
                if callService.callStatus == .connected {
                    VStack(spacing: 30) {
                        // Mute and speaker controls
                        HStack(spacing: 40) {
                            CallControlButton(
                                icon: callService.isMuted ? "mic.slash.fill" : "mic.fill",
                                title: callService.isMuted ? "Unmute" : "Mute",
                                color: callService.isMuted ? .red : .white
                            ) {
                                callService.toggleMute()
                            }
                            
                            CallControlButton(
                                icon: callService.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                                title: callService.isSpeakerOn ? "Speaker Off" : "Speaker",
                                color: callService.isSpeakerOn ? .purple : .white
                            ) {
                                callService.toggleSpeaker()
                            }
                        }
                        
                        // End call button
                        Button(action: endCall) {
                            Image(systemName: "phone.down.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                } else if callService.callStatus == .connecting {
                    // Connecting state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Connecting...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startCall()
        }
        .alert("Call Moderation", isPresented: $showingModerationAlert) {
            Button("OK") {
                showingModerationAlert = false
            }
        } message: {
            if let result = moderationResult {
                Text(callModerationAlertMessage(for: result))
            }
        }
        .onChange(of: callService.callStatus) { status in
            if status == .ended {
                dismiss()
            }
        }
    }
    
    private var callStatusText: String {
        switch callService.callStatus {
        case .idle:
            return "Preparing call..."
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .ended:
            return "Call ended"
        case .failed:
            return "Call failed"
        }
    }
    
    private func startCall() {
        callService.startCall(with: provider.id?.uuidString ?? "unknown")
        
        // Start AI moderation monitoring
        startModerationMonitoring()
    }
    
    private func endCall() {
        callService.endCall()
    }
    
    private func startModerationMonitoring() {
        // In a real app, this would:
        // 1. Start real-time audio transcription
        // 2. Process transcripts for moderation
        // 3. Handle violations appropriately
        
        // For demo purposes, we'll simulate moderation events
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
            if callService.callStatus == .connected {
                simulateModerationCheck()
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func simulateModerationCheck() {
        // Simulate detecting inappropriate content
        let inappropriatePhrases = [
            "This is really stupid",
            "You're an idiot",
            "I hate this",
            "This is harassment"
        ]
        
        let randomPhrase = inappropriatePhrases.randomElement() ?? ""
        
        Task {
            let result = await moderationService.moderateCallTranscript(randomPhrase, participantId: "current_user")
            
            await MainActor.run {
                moderationResult = result
                
                switch result.action {
                case .warn:
                    showingModerationAlert = true
                    
                case .block, .report:
                    showingModerationAlert = true
                    // In a real app, this might end the call
                    
                case .endCall:
                    showingModerationAlert = true
                    callService.endCall()
                    
                case .allow:
                    break
                }
            }
        }
    }
    
    private func formatCallDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func callModerationAlertMessage(for result: ModerationResult) -> String {
        switch result.level {
        case .safe:
            return "Call proceeding normally."
        case .warning:
            return "Warning: Inappropriate language detected. Please be respectful during the call."
        case .violation:
            return "Inappropriate content detected. This call may be monitored or ended if violations continue."
        case .severe:
            return "Severe violations detected. This call has been ended and the incident has been reported."
        }
    }
}

struct CallControlButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
} 