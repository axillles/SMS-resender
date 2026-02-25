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
        ForwardSMSIntent.self
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(registrationViewModel)
                .task {
                    if !registrationViewModel.isRegistered {
                        await registrationViewModel.register()
                    }
                }
                // Не проверяем подписку при возврате в приложение — запрашивает вход в Apple ID
        }
    }
}
