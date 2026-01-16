//
//  TestConnectionModels.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - Test Connection Request
struct TestConnectionRequest: Codable {
    let registrationId: String
    let type: String // 'email', 'webhook', or 'phone'
    let target: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
        case type
        case target
        case message
    }
}

// MARK: - Test Connection Response
struct TestConnectionResponse: Codable {
    let status: String
    
    var isSuccess: Bool {
        return status == "success"
    }
}
