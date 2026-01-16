//
//  RegistrationViewModel.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import SwiftUI

@MainActor
class RegistrationViewModel: ObservableObject {
    @Published var isRegistering = false
    @Published var isRegistered = false
    @Published var registrationError: String?
    
    private let registrationService = RegistrationService.shared
    
    init() {
        checkRegistrationStatus()
    }
    
    // MARK: - Check Registration Status
    func checkRegistrationStatus() {
        isRegistered = registrationService.isRegistered()
    }
    
    // MARK: - Register
    func register() async {
        guard !isRegistering else { return }
        
        isRegistering = true
        registrationError = nil
        
        do {
            try await registrationService.registerIfNeeded()
            isRegistered = true
        } catch {
            registrationError = error.localizedDescription
            isRegistered = false
        }
        
        isRegistering = false
    }
    
    // MARK: - Get Registration ID
    func getRegistrationId() -> String? {
        return registrationService.getRegistrationId()
    }
}
