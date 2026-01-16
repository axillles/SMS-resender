//
//  ForwardModels.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - Forward Request
struct ForwardRequest: Codable {
    let registrationId: String
    let message: String
    let sender: String
    let timestamp: String
    let subject: String?
    
    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
        case message
        case sender
        case timestamp
        case subject
    }
    
    init(registrationId: String, message: String, sender: String, timestamp: Date, subject: String? = nil) {
        self.registrationId = registrationId
        self.message = message
        self.sender = sender
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.timestamp = formatter.string(from: timestamp)
        
        self.subject = subject
    }
}

// MARK: - Forward Response
struct ForwardResponse: Codable {
    let status: String
    let details: ForwardDetails?
    let message: String?
    
    var isSuccess: Bool {
        return status == "success"
    }
}

// MARK: - Forward Details
struct ForwardDetails: Codable {
    let sent: Int
    let failed: Int
}
