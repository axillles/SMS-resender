//
//  ProfileModels.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - Profile Request
struct ProfileRequest: Codable {
    let registrationId: String
    
    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
    }
}

// MARK: - Profile Response
struct ProfileResponse: Codable {
    let status: String
    let profile: UserProfile?
    let message: String?
    
    var isSuccess: Bool {
        return status == "success"
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    let registrationDate: String
    let subscription: Subscription
    let destinations: Destinations
    
    enum CodingKeys: String, CodingKey {
        case registrationDate = "registration_date"
        case subscription
        case destinations
    }
}

// MARK: - Subscription
struct Subscription: Codable {
    let status: String
    let productId: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case productId = "product_id"
    }
    
    var isActive: Bool {
        return status == "active"
    }
}

// MARK: - Destinations
struct Destinations: Codable {
    let emails: [EmailDestination]
    let phones: [PhoneDestination]
    let webhooks: [WebhookDestination]
}

// MARK: - Email Destination
struct EmailDestination: Codable {
    let email: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case createdAt = "created_at"
    }
}

// MARK: - Phone Destination
struct PhoneDestination: Codable {
    let phoneNumber: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case createdAt = "created_at"
    }
}

// MARK: - Webhook Destination
struct WebhookDestination: Codable {
    let url: String
    let isSlack: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case url
        case isSlack = "is_slack"
        case createdAt = "created_at"
    }
    
    var isSlackBool: Bool {
        return isSlack == "1" || isSlack.lowercased() == "true"
    }
}
