//
//  URLModels.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - URL/Slack/API Request
struct WebhookRequest: Codable {
    let registrationId: String
    let url: String
    let isSlack: Bool
    let delete: Bool?
    
    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
        case url
        case isSlack = "is_slack"
        case delete
    }
    
    init(registrationId: String, url: String, isSlack: Bool, delete: Bool = false) {
        self.registrationId = registrationId
        self.url = url
        self.isSlack = isSlack
        self.delete = delete
    }
}

// MARK: - URL Response
struct WebhookResponse: Codable {
    let status: String
    let message: String
    
    var isSuccess: Bool {
        return status == "success"
    }
}
