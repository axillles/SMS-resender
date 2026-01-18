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
    
    // Phone specific
    @Published var selectedCountryCode: CountryCode = CountryCode.popularCodes[0]
    @Published var phoneNumber: String = ""
    @Published var showOTPAlert = false
    @Published var otpCode: String = ""
    @Published var isRequestingOTP = false
    @Published var otpError: String?
    
    @Published var isSaving = false
    @Published var isTesting = false
    @Published var saveError: String?
    @Published var testError: String?
    @Published var testSuccess = false
    
    private let networkService = NetworkService.shared
    
    func createRule(type: DestinationType) -> ForwardingRule {
        let finalDestination: String
        if type == .phone {
            finalDestination = selectedCountryCode.code + phoneNumber
        } else {
            finalDestination = destination
        }
        
        return ForwardingRule(
            type: type,
            destination: finalDestination,
            isScheduleEnabled: isScheduleEnabled,
            isAllDay: isAllDay,
            startTime: isScheduleEnabled && !isAllDay ? startTime : nil,
            endTime: isScheduleEnabled && !isAllDay ? endTime : nil,
            selectedDays: isScheduleEnabled ? selectedDays : []
        )
    }
    
    // MARK: - Phone Number
    var fullPhoneNumber: String {
        return selectedCountryCode.code + phoneNumber
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
    
    // MARK: - Request OTP
    func requestOTP(registrationId: String) async {
        guard !phoneNumber.isEmpty else {
            otpError = "Please enter a phone number"
            return
        }
        
        isRequestingOTP = true
        otpError = nil
        
        do {
            _ = try await networkService.requestOTP(
                registrationId: registrationId,
                phoneNumber: fullPhoneNumber
            )
            showOTPAlert = true
        } catch {
            otpError = error.localizedDescription
        }
        
        isRequestingOTP = false
    }
    
    // MARK: - Save Phone
    func savePhone(registrationId: String) async throws {
        guard !phoneNumber.isEmpty else {
            throw ValidationError.emptyPhone
        }
        
        guard !otpCode.isEmpty else {
            throw ValidationError.emptyOTP
        }
        
        isSaving = true
        saveError = nil
        
        do {
            _ = try await networkService.savePhone(
                registrationId: registrationId,
                phoneNumber: fullPhoneNumber,
                otpCode: otpCode
            )
        } catch {
            saveError = error.localizedDescription
            throw error
        }
        
        isSaving = false
    }
    
    // MARK: - Test Phone Connection
    func testPhoneConnection(registrationId: String) async {
        guard !phoneNumber.isEmpty else {
            testError = "Please enter a phone number"
            return
        }
        
        isTesting = true
        testError = nil
        testSuccess = false
        
        do {
            _ = try await networkService.testConnection(
                registrationId: registrationId,
                type: "phone",
                target: fullPhoneNumber,
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
    case emptyPhone
    case emptyOTP
    
    var errorDescription: String? {
        switch self {
        case .emptyEmail:
            return "Email address cannot be empty"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .emptyPhone:
            return "Phone number cannot be empty"
        case .emptyOTP:
            return "OTP code cannot be empty"
        }
    }
}