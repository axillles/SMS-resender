//
//  sms_senderApp.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

@main
struct sms_senderApp: App {
    @StateObject private var registrationViewModel = RegistrationViewModel()
    
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
        }
    }
}
