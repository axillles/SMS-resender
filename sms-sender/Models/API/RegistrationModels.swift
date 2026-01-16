//
//  RegistrationModels.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - Registration Request
struct RegistrationRequest: Codable {
    let uuid: String
    let details: DeviceDetails?
}

// MARK: - Device Details
struct DeviceDetails: Codable {
    let deviceName: String
    let iosVersion: String
    let appVersion: String
    
    enum CodingKeys: String, CodingKey {
        case deviceName = "device_name"
        case iosVersion = "ios_version"
        case appVersion = "app_version"
    }
}

// MARK: - Registration Response
struct RegistrationResponse: Codable {
    let status: String
    let registrationId: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case registrationId = "registration_id"
        case message
    }
    
    var isSuccess: Bool {
        return status == "success"
    }
}
