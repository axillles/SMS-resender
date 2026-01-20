//
//  sms_senderApp.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI
import AppIntents

@main
struct sms_senderApp: App {
    @StateObject private var registrationViewModel = RegistrationViewModel()
    
    init() {
        // Регистрируем App Intent для Shortcuts
        ForwardSMSIntent.self
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(registrationViewModel)
                .task {
                    // Register on app launch if not already registered
                    if !registrationViewModel.isRegistered {
                        await registrationViewModel.register()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Проверяем статус подписки при возврате приложения в foreground
                    Task {
                        await SubscriptionService.shared.checkSubscriptionStatus()
                    }
                }
        }
    }
}
