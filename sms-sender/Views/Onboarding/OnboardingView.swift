//
//  OnboardingView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import SwiftUI
import AVKit
import AVFoundation

// MARK: - Video Preloader
final class OnboardingVideoPreloader: ObservableObject {
    private var players: [String: AVPlayer] = [:]
    private let lock = NSLock()
    
    private static func videoKey(stepNumber: Int, allMessages: Bool) -> String {
        if stepNumber == 3 {
            return allMessages ? "step3_2" : "step3"
        }
        return "step\(stepNumber + 1)"
    }
    
    func player(stepNumber: Int, allMessages: Bool) -> AVPlayer? {
        lock.lock()
        defer { lock.unlock() }
        return players[Self.videoKey(stepNumber: stepNumber, allMessages: allMessages)]
    }
    
    func preloadAll() {
        let keys = ["step2", "step3", "step3_2", "step4", "step5", "step6", "step7"]
        let extensions = ["mp4", "mov", "m4v", "MOV"]
        for key in keys {
            var url: URL?
            for ext in extensions {
                if let u = Bundle.main.url(forResource: key, withExtension: ext) {
                    url = u
                    break
                }
            }
            guard let url else { continue }
            let item = AVPlayerItem(asset: AVURLAsset(url: url))
            let p = AVPlayer(playerItem: item)
            p.actionAtItemEnd = .none
            p.isMuted = true
            lock.lock()
            players[key] = p
            lock.unlock()
        }
    }
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @StateObject private var videoPreloader = OnboardingVideoPreloader()
    
    private let totalPages = 7
    private let isFirstTime: Bool
    
    init(isPresented: Binding<Bool>, isFirstTime: Bool? = nil) {
        self._isPresented = isPresented
        self.isFirstTime = isFirstTime ?? !StorageService.hasCompletedOnboarding()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                PageViewController(
                    currentPage: $currentPage,
                    pages: (0..<totalPages).map { index in
                        AnyView(
                            OnboardingStepView(
                                stepNumber: index,
                                isLastStep: index == totalPages - 1,
                                currentPage: $currentPage,
                                onNext: {
                                    if index < totalPages - 1 {
                                        goToPage(index + 1)
                                    } else {
                                        completeOnboarding()
                                    }
                                }
                            )
                            .environmentObject(videoPreloader)
                        )
                    }
                )
            }
            .environmentObject(videoPreloader)
            .onAppear {
                videoPreloader.preloadAll()
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
    
    private func goToPage(_ page: Int) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) {
                self.currentPage = page
            }
        }
    }
    

    private func completeOnboarding() {
        StorageService.setOnboardingCompleted(true)
        withAnimation {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: .showPaywall, object: nil)
        }
    }
}

struct OnboardingStepView: View {
    let stepNumber: Int
    let isLastStep: Bool
    @Binding var currentPage: Int
    let onNext: () -> Void
    
    @EnvironmentObject private var videoPreloader: OnboardingVideoPreloader
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?
    @State private var statusObservation: NSKeyValueObservation?
    @State private var step3ChoiceAllMessages: Bool = false
    
    private var stepTitle: String {
        if stepNumber == 0 {
            return "Finish Setup"
        } else {
            return "Step \(stepNumber)"
        }
    }
    
    private var videoName: String {
        if stepNumber == 3 {
            return step3ChoiceAllMessages ? "step3_2" : "step3"
        }
        return "step\(stepNumber + 1)"
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if stepNumber == 0 {
                    if let image = UIImage(named: "step1") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: geometry.size.height * 0.55)
                            .clipped()
                            .background(Color.white)
                    } else {
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
                    if let player = player {
                        VideoPlayerView(player: player)
                            .frame(maxWidth: .infinity)
                            .frame(height: geometry.size.height * 0.55)
                            .edgesIgnoringSafeArea(.horizontal)
                            .background(Color.white)
                            .onDisappear {
                                player.pause()
                            }
                    } else {
                        ZStack {
                            Color.white
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.55)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text(stepTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 10)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            instructionContent
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                }
                
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            Circle()
                                .fill(index == stepNumber ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    Button(action: onNext) {
                        Text(isLastStep ? "Done" : "Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(26)
                    }
                    .padding(.horizontal, 20)
                    
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .onAppear {
            if stepNumber != 0 {
                attachPreloadedPlayer()
            }
        }
        .onDisappear {
            cleanupVideo()
        }
        .onChange(of: step3ChoiceAllMessages) { _, _ in
            if stepNumber == 3 {
                switchStep3Video()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard stepNumber == currentPage else { return }
            switch newPhase {
            case .active:
                player?.play()
            case .inactive, .background:
                player?.pause()
            @unknown default:
                break
            }
        }
    }
    
    private var instructionContent: some View {
        Group {
            switch stepNumber {
            case 0:
                Text("Required to forward text messages.")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text("Forward SMS requires Shortcuts Automations to automatically receive and forward incoming messages.")
            case 1:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(
                        number: 1,
                        appIcon: Image("Shortcuts"), // asset с иконкой
                        appName: "Shortcuts",
                        url: URL(string: "shortcuts://")!
                    )


                    instructionItem(number: 2, text: "Go to the **Automation** tab.")
                }
            case 2:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "Tap on **New Automation**.")
                    instructionItem(number: 2, text: "Select **Mesage** from the list of triggers.")
                }
            case 3:
                step3Content
            case 4:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "Select **Run Immediately** to skip confirmation for each forward.")
                }
            case 5:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "Choose **New Blank Automation**.")
                    instructionItem(number: 2, text: "Search for **Forward SMS**.")
                    instructionItem(number: 3, text: "Select **Forward Message** from the list of actions.")
                }
            case 6:
                VStack(alignment: .leading, spacing: 12) {
                    instructionItem(number: 1, text: "Select the **Message** field.")
                    instructionItem(number: 2, text: "**Scroll to theright** on the toolbar above the keyboard.")
                    instructionItem(number: 3, text: "Set **Mesage** to .")
                }
            default:
                EmptyView()
            }
        }
    }

    private var step3Content: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text("What messages do you want to forward?")
                    .font(.body)
                    .foregroundColor(.primary)
                Image(systemName: "questionmark.circle")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    step3ChoiceAllMessages = false
                } label: {
                    Text("Specific Messages")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(step3ChoiceAllMessages ? .secondary : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(step3ChoiceAllMessages
                                      ? Color(UIColor.tertiarySystemFill)
                                      : Color(UIColor.secondarySystemGroupedBackground))
                            )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(step3ChoiceAllMessages ? Color.clear : Color.blue, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    step3ChoiceAllMessages = true
                } label: {
                    Text("All Messages")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(step3ChoiceAllMessages ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(step3ChoiceAllMessages
                                      ? Color(UIColor.secondarySystemGroupedBackground)
                                      : Color(UIColor.tertiarySystemFill))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(step3ChoiceAllMessages ? Color.blue : Color.clear, lineWidth: 2)
                        )
                            )
                }
                .buttonStyle(.plain)
            }

            if step3ChoiceAllMessages {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Forwarding All Messages")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("Set the \"Message Contains\" condition to a single space (tap the space bar once) to forward all texts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                )
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
            
            Text(.init(text))
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private func instructionItem(
        number: Int,
        appIcon: Image,
        appName: String,
        url: URL
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())

            HStack(spacing: 6) {
                Text("Open")

                appIcon
                    .resizable()
                    .frame(width: 18, height: 18)
                    .cornerRadius(4)

                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text(appName)
                            .fontWeight(.semibold)

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
        }
    }

    
    private func attachPreloadedPlayer() {
        cleanupVideo()
        guard let preloaded = videoPreloader.player(stepNumber: stepNumber, allMessages: step3ChoiceAllMessages) else {
            return
        }
        attachPlayerAndStart(preloaded)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak preloaded] in
            preloaded?.seek(to: .zero)
            preloaded?.play()
        }
    }

    private func switchStep3Video() {
        removeObserversOnly()
        guard let preloaded = videoPreloader.player(stepNumber: 3, allMessages: step3ChoiceAllMessages) else {
            player = nil
            return
        }
        attachPlayerAndStart(preloaded)
    }

    private func attachPlayerAndStart(_ preloaded: AVPlayer) {
        let item = preloaded.currentItem
        let startPlayback: () -> Void = { [weak preloaded] in
            DispatchQueue.main.async {
                preloaded?.seek(to: .zero)
                preloaded?.play()
            }
        }
        statusObservation = item?.observe(\.status, options: [.new]) { _, _ in
            guard item?.status == .readyToPlay else { return }
            startPlayback()
        }
        if item?.status == .readyToPlay {
            startPlayback()
        }
        if let item {
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak preloaded] _ in
                preloaded?.seek(to: .zero)
                preloaded?.play()
            }
        }
        self.player = preloaded
        startPlayback()
    }

    private func removeObserversOnly() {
        player?.pause()
        statusObservation?.invalidate()
        statusObservation = nil
        if let obs = loopObserver {
            NotificationCenter.default.removeObserver(obs)
            loopObserver = nil
        }
    }
    
    private func cleanupVideo() {
        player?.pause()
        statusObservation?.invalidate()
        statusObservation = nil
        if let obs = loopObserver {
            NotificationCenter.default.removeObserver(obs)
            loopObserver = nil
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
        playerLayer.videoGravity = .resizeAspect
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

// MARK: - Page View Controller with Swipe Animation
struct PageViewController: UIViewControllerRepresentable {
    @Binding var currentPage: Int
    let pages: [AnyView]
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        if let firstPage = context.coordinator.viewControllers.first {
            pageViewController.setViewControllers(
                [firstPage],
                direction: .forward,
                animated: false
            )
        }
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        guard currentPage >= 0 && currentPage < context.coordinator.viewControllers.count else {
            return
        }
        
        let currentViewController = context.coordinator.viewControllers[currentPage]
        let displayedViewController = pageViewController.viewControllers?.first
        
        if displayedViewController !== currentViewController {
            let direction: UIPageViewController.NavigationDirection = 
                currentPage > context.coordinator.currentPage ? .forward : .reverse
            
            pageViewController.setViewControllers(
                [currentViewController],
                direction: direction,
                animated: true
            )
            
            context.coordinator.currentPage = currentPage
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageViewController
        var viewControllers: [UIHostingController<AnyView>] = []
        var currentPage: Int = 0
        
        init(_ parent: PageViewController) {
            self.parent = parent
            self.viewControllers = parent.pages.map { page in
                let hostingController = UIHostingController(rootView: page)
                hostingController.view.backgroundColor = .clear
                return hostingController
            }
            self.currentPage = parent.currentPage
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = viewControllers.firstIndex(where: { $0 === viewController }),
                  index > 0 else {
                return nil
            }
            return viewControllers[index - 1]
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = viewControllers.firstIndex(where: { $0 === viewController }),
                  index < viewControllers.count - 1 else {
                return nil
            }
            return viewControllers[index + 1]
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let currentViewController = pageViewController.viewControllers?.first,
               let index = viewControllers.firstIndex(where: { $0 === currentViewController }) {
                currentPage = index
                parent.currentPage = index
            }
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
