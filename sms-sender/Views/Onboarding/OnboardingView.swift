//
//  OnboardingView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import SwiftUI
import AVKit
import AVFoundation

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    private let totalPages = 7
    private let isFirstTime: Bool
    
    init(isPresented: Binding<Bool>, isFirstTime: Bool? = nil) {
        self._isPresented = isPresented
        // If not specified, determine based on whether onboarding was completed before
        self.isFirstTime = isFirstTime ?? !StorageService.hasCompletedOnboarding()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                TabView(selection: $currentPage) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        OnboardingStepView(
                            stepNumber: index,
                            isLastStep: index == totalPages - 1,
                            onNext: {
                                if index < totalPages - 1 {
                                    withAnimation {
                                        currentPage = index + 1
                                    }
                                } else {
                                    completeOnboarding()
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
            }
            .navigationTitle("Setup Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isFirstTime {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    

    private func completeOnboarding() {
        StorageService.setOnboardingCompleted(true)
        withAnimation {
            isPresented = false
        }
        // Show paywall after onboarding if no active subscription
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: .showPaywall, object: nil)
        }
    }
}

struct OnboardingStepView: View {
    let stepNumber: Int
    let isLastStep: Bool
    let onNext: () -> Void
    
    @State private var player: AVPlayer?
    @State private var observer: NSObjectProtocol?
    
    private var stepTitle: String {
        if stepNumber == 0 {
            return "Finish Setup"
        } else {
            return "Step \(stepNumber)"
        }
    }
    
    private var videoName: String {
        return "step\(stepNumber + 1)"
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Image/Video Section - Full size at top
                if stepNumber == 0 {
                    // First screen - show image
                    if let image = UIImage(named: "step1") {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                    } else {
                        // Fallback if image not found
                        ZStack {
                            Color.white
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                    }
                } else {
                    // Other screens - show video
                    if let player = player {
                        VideoPlayerView(player: player)
                            .frame(maxWidth: .infinity)
                            .frame(height: min(450, geometry.size.height * 0.45))
                            .clipped()
                            .background(Color.white)
                            .onAppear {
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                            }
                    } else {
                        // Placeholder while video loads
                        ZStack {
                            Color.white
                            ProgressView()
                        }
                        .frame(maxWidth: geometry.size.width)
                        .frame(height: 300)
                    }
                }
                
                // Scrollable content section
                ScrollView {
                    VStack(spacing: 20) {
                        // Step Title
                        Text(stepTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 30)
                            .padding(.horizontal)
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 16) {
                            instructionContent
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                }
                
                // Fixed bottom section
                VStack(spacing: 0) {
                    // Navigation Dots
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            Circle()
                                .fill(index == stepNumber ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Next/Done Button
                    Button(action: onNext) {
                        Text(isLastStep ? "Done" : "Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .onAppear {
            if stepNumber != 0 {
                setupVideo()
            }
        }
        .onDisappear {
            cleanupVideo()
        }
    }
    
    private var instructionContent: some View {
        Group {
            // This will be customized for each step
            // For now, showing placeholder content
            switch stepNumber {
            case 0:
                Text("Welcome! Let's set up your SMS forwarding automation.")
                    .font(.body)
                    .foregroundColor(.secondary)
            case 1:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "Choose New Blank Automation.")
                    instructionItem(number: 2, text: "Search for Forward SMS.")
                    instructionItem(number: 3, text: "Select Forward Message from the list of actions.")
                }
            case 2:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "Configure the automation settings.")
                    instructionItem(number: 2, text: "Set up your forwarding destination.")
                }
            case 3:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "Enable the automation.")
                    instructionItem(number: 2, text: "Test the connection.")
                }
            case 4:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "Verify your settings.")
                    instructionItem(number: 2, text: "Confirm the setup.")
                }
            case 5:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "Choose New Blank Automation.")
                    instructionItem(number: 2, text: "Search for Forward SMS.")
                    instructionItem(number: 3, text: "Select Forward Message from the list of actions.")
                }
            case 6:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "You're all set!")
                    instructionItem(number: 2, text: "Your SMS forwarding is now active.")
                }
            default:
                EmptyView()
            }
        }
    }
    
    private func instructionItem(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private func setupVideo() {
        // Try different video extensions
        let extensions = ["mp4", "mov", "m4v"]
        var videoURL: URL?
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: videoName, withExtension: ext) {
                videoURL = url
                break
            }
        }
        
        guard let url = videoURL else {
            // If video file doesn't exist, show placeholder
            print("Video file \(videoName) not found in bundle (tried: \(extensions.joined(separator: ", ")))")
            return
        }
        
        let newPlayer = AVPlayer(url: url)
        newPlayer.actionAtItemEnd = .none
        newPlayer.isMuted = true // Mute by default for better UX
        
        // Set up looping
        let item = newPlayer.currentItem
        observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak newPlayer] _ in
            newPlayer?.seek(to: .zero)
            newPlayer?.play()
        }
        
        self.player = newPlayer
    }
    
    private func cleanupVideo() {
        player?.pause()
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        player = nil
    }
}

// MARK: - Custom Video Player with Aspect Fit
struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerContainerView {
        let containerView = PlayerContainerView()
        containerView.backgroundColor = .white
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        containerView.playerLayer = playerLayer
        containerView.layer.addSublayer(playerLayer)
        
        return containerView
    }
    
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if let playerLayer = uiView.playerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
}

class PlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
