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
        let uuid = KeychainService.getOrCreateUUID()
        
        if let registrationId = StorageService.getRegistrationId(), StorageService.isRegistered() {
            return
        }
        
        let deviceDetails = getDeviceInfo()
        
        StorageService.saveDeviceInfo(
            name: deviceDetails.deviceName,
            iosVersion: deviceDetails.iosVersion,
            appVersion: deviceDetails.appVersion
        )
        
        let response = try await NetworkService.shared.register(
            uuid: uuid,
            deviceDetails: deviceDetails
        )
        
        guard response.isSuccess, let registrationId = response.registrationId else {
            throw RegistrationError.registrationFailed(message: response.message ?? "Unknown error")
        }
        
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
