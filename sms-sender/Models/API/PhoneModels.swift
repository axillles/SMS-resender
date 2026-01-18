//
//  PhoneModels.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - Request OTP
struct PhoneOTPRequest: Codable {
    let registrationId: String
    let phoneNumber: String
    
    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
        case phoneNumber = "phone_number"
    }
}

// MARK: - Save Phone Number
struct PhoneSaveRequest: Codable {
    let registrationId: String
    let phoneNumber: String
    let otpCode: String
    
    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
        case phoneNumber = "phone_number"
        case otpCode = "otp_code"
    }
}

// MARK: - Delete Phone Number
struct PhoneDeleteRequest: Codable {
    let registrationId: String
    let phoneNumber: String
    
    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
        case phoneNumber = "phone_number"
    }
}

// MARK: - Phone Response
struct PhoneResponse: Codable {
    let status: String
    let message: String
    let otpCode: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case otpCode = "otp_code"
    }
    
    var isSuccess: Bool {
        return status == "success"
    }
}
