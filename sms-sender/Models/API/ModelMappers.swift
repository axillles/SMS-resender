//
//  ModelMappers.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - Mapping between App Models and API Models

extension ForwardingRule {
    /// Convert ForwardingRule to API destination format
    func toAPIDestination() -> (type: DestinationType, value: String) {
        return (type: self.type, value: self.destination)
    }
    
    /// Create ForwardingRule from API Profile destinations
    static func fromEmailDestination(_ email: EmailDestination) -> ForwardingRule {
        return ForwardingRule(
            type: .email,
            destination: email.email,
            isScheduleEnabled: false,
            isAllDay: true,
            startTime: nil,
            endTime: nil,
            selectedDays: []
        )
    }
    
    static func fromPhoneDestination(_ phone: PhoneDestination) -> ForwardingRule {
        return ForwardingRule(
            type: .phone,
            destination: phone.phoneNumber,
            isScheduleEnabled: false,
            isAllDay: true,
            startTime: nil,
            endTime: nil,
            selectedDays: []
        )
    }
    
    static func fromWebhookDestination(_ webhook: WebhookDestination) -> ForwardingRule {
        let destinationType: DestinationType = webhook.isSlackBool ? .slack : .api
        return ForwardingRule(
            type: destinationType,
            destination: webhook.url,
            isScheduleEnabled: false,
            isAllDay: true,
            startTime: nil,
            endTime: nil,
            selectedDays: []
        )
    }
}

extension UserProfile {
    /// Convert UserProfile to array of ForwardingRules
    func toForwardingRules() -> [ForwardingRule] {
        var rules: [ForwardingRule] = []
        
        // Add email rules
        rules.append(contentsOf: destinations.emails.map { ForwardingRule.fromEmailDestination($0) })
        
        // Add phone rules
        rules.append(contentsOf: destinations.phones.map { ForwardingRule.fromPhoneDestination($0) })
        
        // Add webhook rules (Slack and API)
        rules.append(contentsOf: destinations.webhooks.map { ForwardingRule.fromWebhookDestination($0) })
        
        return rules
    }
}

extension DestinationType {
    /// Convert to API test connection type
    var testConnectionType: String {
        switch self {
        case .email:
            return "email"
        case .phone:
            return "phone"
        case .slack, .api:
            return "webhook"
        }
    }
}
