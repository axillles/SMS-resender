//
//  DestinationType.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import Foundation

enum DestinationType: String, Codable {
    case email, phone, slack, api
    
    var iconName: String {
        switch self {
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        case .slack: return "bubble.left.and.exclamationmark.bubble.right.fill"
        case .api: return "network"
        }
    }
}

