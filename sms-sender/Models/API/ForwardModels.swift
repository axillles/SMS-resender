//
//  ForwardModels.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - Forward Request
/// Один получатель для пересылки (только активные по расписанию попадают в список).
struct ForwardTarget: Codable {
    let type: String  // "email" | "phone" | "slack" | "api"
    let destination: String
}

struct ForwardRequest: Codable {
    let registrationId: String
    let message: String
    let sender: String
    let timestamp: String
    let subject: String?
    /// Список получателей, на которые нужно отправить (уже отфильтрованы по расписанию на клиенте). Если пустой — сервер может слать на все (fallback).
    let targets: [ForwardTarget]?
    
    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
        case message
        case sender
        case timestamp
        case subject
        case targets
    }
    
    init(registrationId: String, message: String, sender: String, timestamp: Date, subject: String? = nil, targets: [ForwardTarget]? = nil) {
        self.registrationId = registrationId
        self.message = message
        self.sender = sender
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.timestamp = formatter.string(from: timestamp)
        
        self.subject = subject
        self.targets = targets
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
