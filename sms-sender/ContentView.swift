//
//  ContentView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var registrationViewModel: RegistrationViewModel
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showOnboarding: Bool = {
        // Initialize based on onboarding status
        return !StorageService.hasCompletedOnboarding()
    }()
    @State private var showPaywall = false
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(
                    isPresented: $showOnboarding,
                    isFirstTime: !StorageService.hasCompletedOnboarding()
                )
            } else if registrationViewModel.isRegistering {
                RegistrationLoadingView()
            } else if let error = registrationViewModel.registrationError {
                RegistrationErrorView(error: error) {
                    Task {
                        await registrationViewModel.register()
                    }
                }
            } else {
                HomeView()
                    .environmentObject(registrationViewModel)
                    .sheet(isPresented: $showPaywall) {
                        PaywallView(isPresented: $showPaywall)
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showOnboarding)) { _ in
            showOnboarding = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPaywall)) { _ in
            // Only show paywall if user doesn't have active subscription
            if !subscriptionService.hasActiveSubscription {
                showPaywall = true
            }
        }
        .task {
            // Check subscription status on app launch
            await subscriptionService.checkSubscriptionStatus()
            
            // Show paywall once on launch if no subscription and hasn't been shown before
            if !subscriptionService.hasActiveSubscription && 
               !StorageService.hasShownPaywallOnLaunch() &&
               !showOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showPaywall = true
                    StorageService.setHasShownPaywallOnLaunch(true)
                }
            }
        }
    }
}

// MARK: - Registration Loading View
struct RegistrationLoadingView: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Registering device...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Registration Error View
struct RegistrationErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("Registration Failed")
                    .font(.headline)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RegistrationViewModel())
}
