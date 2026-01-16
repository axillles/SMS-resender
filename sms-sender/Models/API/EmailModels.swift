//
//  EmailModels.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - Email Request
struct EmailRequest: Codable {
    let registrationId: String
    let emailAddress: String
    let delete: Bool
    
    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
        case emailAddress = "email_address"
        case delete
    }
}

// MARK: - Email Response
struct EmailResponse: Codable {
    let status: String
    let message: String
    
    var isSuccess: Bool {
        return status == "success"
    }
}
