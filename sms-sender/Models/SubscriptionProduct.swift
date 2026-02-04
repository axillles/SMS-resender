//
//  SubscriptionProduct.swift
//  sms-sender
//
//  Created by Артем Гавrilов on 10.01.26.
//
//  Product IDs в App Store Connect должны совпадать: week (недельная), year (годовая).
//

import Foundation
import StoreKit

enum SubscriptionPeriod: String, CaseIterable {
    case weekly = "weekly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .weekly:
            return "Weekly"
        case .yearly:
            return "Yearly"
        }
    }
    
    var productId: String {
        switch self {
        case .weekly:
            return "week"
        case .yearly:
            return "year"
        }
    }
}

struct SubscriptionProduct: Identifiable, Equatable {
    let id: String
    let period: SubscriptionPeriod
    let price: String
    let priceValue: Decimal
    let displayPrice: String
    let product: Product?
    
    var isYearly: Bool {
        period == .yearly
    }
    
    func savingsText(comparedTo weeklyProduct: SubscriptionProduct?) -> String? {
        guard isYearly, let weeklyProduct = weeklyProduct else { return nil }
        
        let weeklyYearlyEquivalent = weeklyProduct.priceValue * 52
        let savings = weeklyYearlyEquivalent - priceValue
        
        let savingsDouble = NSDecimalNumber(decimal: savings).doubleValue
        let weeklyYearlyEquivalentDouble = NSDecimalNumber(decimal: weeklyYearlyEquivalent).doubleValue
        let savingsPercentage = Int((savingsDouble / weeklyYearlyEquivalentDouble) * 100)
        
        guard savingsPercentage > 0 else { return nil }
        return "Save \(savingsPercentage)%"
    }
}
