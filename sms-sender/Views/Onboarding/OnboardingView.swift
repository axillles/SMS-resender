//
//  OnboardingView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import SwiftUI

// MARK: - Load image (Assets с Light/Dark или Resources/Images)
// Если изображение в Assets.xcassets с вариантами Light и Dark — подставится по текущей теме.
private func onboardingImage(named name: String) -> UIImage? {
    UIImage(named: name)
        ?? UIImage(named: "Resources/Images/\(name)")
        ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Resources/Images")
            .flatMap { UIImage(contentsOfFile: $0.path) }
}

// MARK: - Onboarding: слайды; один шаг — выбор между двумя картинками (как с видео)
fileprivate enum OnboardingStepConfig {
    enum StepContent {
        case single(image: String, caption: String)
        case choice(image1: String, image2: String, label1: String, label2: String, caption1: String, caption2: String)
    }

    static let steps: [StepContent] = [
        .single(image: "Step1", caption: "Press New Automation"),
        .single(image: "Step2", caption: "Press Message"),
        .single(image: "Step3", caption: "Select Run Immediately"),
        .single(image: "Step4", caption: "Run immediately"),
        .choice(image1: "Step5_1", image2: "Step5_2", label1: "Resend All messages", label2: "Resend Only code SMS", caption1: "Type ' ' ", caption2: "Type 'code' "),
        .single(image: "Step6", caption: "Press Create New Shortcut"),
        .single(image: "Step7", caption: "Type AutoForward Text"),
        .single(image: "Step8", caption: "Select it"),
        .single(image: "Step9", caption: "Make sure it looks like this"),
        .single(image: "Step10", caption: "Tap the Sender field"),
        .single(image: "Step11", caption: "Go to Shortcut Input"),
        .single(image: "Step12", caption: "Select Sender. You're all set!")
    ]
}

private let onboardingBackgroundLight = Color(red: 242/255, green: 242/255, blue: 247/255)

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var isTransitioning = false
    @Environment(\.colorScheme) private var colorScheme

    private var totalPages: Int { OnboardingStepConfig.steps.count }
    private let isFirstTime: Bool
    private let transitionDuration: Double = 0.4

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGroupedBackground) : onboardingBackgroundLight
    }

    init(isPresented: Binding<Bool>, isFirstTime: Bool? = nil) {
        self._isPresented = isPresented
        self.isFirstTime = isFirstTime ?? !StorageService.hasCompletedOnboarding()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()

                PageViewController(
                    currentPage: $currentPage,
                    pages: (0..<totalPages).map { index in
                        AnyView(
                            OnboardingStepView(
                                stepContent: OnboardingStepConfig.steps[index],
                                stepIndex: index,
                                totalSteps: totalPages,
                                isLastStep: index == totalPages - 1,
                                isTransitioning: isTransitioning,
                                onNext: {
                                    guard !isTransitioning else { return }
                                    if index < totalPages - 1 {
                                        goToPage(index + 1)
                                    } else {
                                        completeOnboarding()
                                    }
                                }
                            )
                        )
                    }
                )
            }
            .navigationTitle("Setup Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isFirstTime {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: closeOnboarding) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.blue)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func closeOnboarding() {
        withAnimation {
            isPresented = false
        }
    }

    private func goToPage(_ page: Int) {
        isTransitioning = true
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) {
                self.currentPage = page
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
                isTransitioning = false
            }
        }
    }

    private func completeOnboarding() {
        isTransitioning = true
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
    fileprivate let stepContent: OnboardingStepConfig.StepContent
    let stepIndex: Int
    let totalSteps: Int
    let isLastStep: Bool
    let isTransitioning: Bool
    let onNext: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var choiceIndex: Int = 0

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGroupedBackground) : onboardingBackgroundLight
    }

    private var currentImageName: String {
        switch stepContent {
        case .single(let image, _): return image
        case .choice(let image1, let image2, _, _, _, _): return choiceIndex == 0 ? image1 : image2
        }
    }

    private var currentCaption: String {
        switch stepContent {
        case .single(_, let caption): return caption
        case .choice(_, _, _, _, let caption1, let caption2): return choiceIndex == 0 ? caption1 : caption2
        }
    }

    private var isChoiceStep: Bool {
        if case .choice = stepContent { return true }
        return false
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Область картинки + подпись в одну строку снизу
                VStack(spacing: 0) {
                    ZStack {
                        backgroundColor
                        if let uiImage = onboardingImage(named: currentImageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                    Text(currentCaption)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity)
                        .frame(height: 22)
                        .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Для шага с выбором — переключатель под картинкой
                if case .choice(_, _, let label1, let label2, _, _) = stepContent {
                    HStack(spacing: 12) {
                        choiceButton(title: label1, isSelected: choiceIndex == 0) { choiceIndex = 0 }
                        choiceButton(title: label2, isSelected: choiceIndex == 1) { choiceIndex = 1 }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }

                // Точки + кнопка внизу
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Circle()
                                .fill(index == stepIndex ? Color.accentColor : Color(UIColor.tertiaryLabel).opacity(0.6))
                                .frame(width: 6, height: 6)
                        }
                    }

                    Button(action: onNext) {
                        Text(isLastStep ? "Done" : "Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .cornerRadius(14)
                    }
                    .disabled(isTransitioning)
                    .opacity(isTransitioning ? 0.6 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isTransitioning)
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 20)
                .background(backgroundColor)
            }
        }
    }

    private func choiceButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? Color(UIColor.systemBackground) : Color.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.accentColor : Color(UIColor.tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
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
