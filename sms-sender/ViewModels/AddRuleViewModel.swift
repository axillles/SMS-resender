//
//  AddRuleViewModel.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

@MainActor
class SetupRuleViewModel: ObservableObject {
    @Published var destination: String = ""
    @Published var isScheduleEnabled: Bool = false
    @Published var isAllDay: Bool = true
    @Published var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var endTime: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // Monday to Friday
    
    @Published var isSaving = false
    @Published var isTesting = false
    @Published var saveError: String?
    @Published var testError: String?
    @Published var testSuccess = false
    
    private let networkService = NetworkService.shared
    
    func createRule(type: DestinationType) -> ForwardingRule {
        return ForwardingRule(
            type: type,
            destination: destination,
            isScheduleEnabled: isScheduleEnabled,
            isAllDay: isAllDay,
            startTime: isScheduleEnabled && !isAllDay ? startTime : nil,
            endTime: isScheduleEnabled && !isAllDay ? endTime : nil,
            selectedDays: isScheduleEnabled ? selectedDays : []
        )
    }
    
    // MARK: - Save Email
    func saveEmail(registrationId: String) async throws {
        guard !destination.isEmpty else {
            throw ValidationError.emptyEmail
        }
        
        guard isValidEmail(destination) else {
            throw ValidationError.invalidEmail
        }
        
        isSaving = true
        saveError = nil
        
        do {
            _ = try await networkService.saveEmail(
                registrationId: registrationId,
                emailAddress: destination,
                delete: false
            )
        } catch {
            saveError = error.localizedDescription
            throw error
        }
        
        isSaving = false
    }
    
    // MARK: - Test Connection
    func testEmailConnection(registrationId: String) async {
        guard !destination.isEmpty, isValidEmail(destination) else {
            testError = "Please enter a valid email address"
            return
        }
        
        isTesting = true
        testError = nil
        testSuccess = false
        
        do {
            _ = try await networkService.testConnection(
                registrationId: registrationId,
                type: "email",
                target: destination,
                message: "This is a test from my iOS app!"
            )
            testSuccess = true
        } catch {
            testError = error.localizedDescription
        }
        
        isTesting = false
    }
    
    // MARK: - Validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Validation Errors
enum ValidationError: LocalizedError {
    case emptyEmail
    case invalidEmail
    
    var errorDescription: String? {
        switch self {
        case .emptyEmail:
            return "Email address cannot be empty"
        case .invalidEmail:
            return "Please enter a valid email address"
        }
    }
}