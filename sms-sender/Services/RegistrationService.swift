//
//  RegistrationService.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation
import UIKit

class RegistrationService {
    static let shared = RegistrationService()
    
    private init() {}
    
    // MARK: - Device Info
    private func getDeviceInfo() -> DeviceDetails {
        let deviceName = UIDevice.current.name
        let iosVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        return DeviceDetails(
            deviceName: deviceName,
            iosVersion: iosVersion,
            appVersion: appVersion
        )
    }
    
    // MARK: - Registration Flow
    func registerIfNeeded() async throws {
        // 1. Get or create UUID from Keychain
        let uuid = KeychainService.getOrCreateUUID()
        
        // 2. Check if already registered
        if let registrationId = StorageService.getRegistrationId(), StorageService.isRegistered() {
            // Already registered, no need to register again
            return
        }
        
        // 3. Get device info
        let deviceDetails = getDeviceInfo()
        
        // 4. Save device info to UserDefaults
        StorageService.saveDeviceInfo(
            name: deviceDetails.deviceName,
            iosVersion: deviceDetails.iosVersion,
            appVersion: deviceDetails.appVersion
        )
        
        // 5. Register with backend
        let response = try await NetworkService.shared.register(
            uuid: uuid,
            deviceDetails: deviceDetails
        )
        
        // 6. Check response
        guard response.isSuccess, let registrationId = response.registrationId else {
            throw RegistrationError.registrationFailed(message: response.message ?? "Unknown error")
        }
        
        // 7. Save registration_id to UserDefaults
        StorageService.saveRegistrationId(registrationId)
        StorageService.setRegistered(true)
    }
    
    // MARK: - Check Registration Status
    func isRegistered() -> Bool {
        return StorageService.isRegistered() && StorageService.getRegistrationId() != nil
    }
    
    // MARK: - Get Registration ID
    func getRegistrationId() -> String? {
        return StorageService.getRegistrationId()
    }
}

// MARK: - Registration Errors
enum RegistrationError: LocalizedError {
    case registrationFailed(message: String)
    case uuidNotFound
    
    var errorDescription: String? {
        switch self {
        case .registrationFailed(let message):
            return "Registration failed: \(message)"
        case .uuidNotFound:
            return "UUID not found in Keychain"
        }
    }
}
