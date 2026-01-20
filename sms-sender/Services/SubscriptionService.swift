//
//  SubscriptionService.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation
import StoreKit

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var hasActiveSubscription = false
    @Published var isLoading = false
    
    private let networkService = NetworkService.shared
    
    private init() {
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    /// Проверяет статус подписки из StoreKit и API
    func checkSubscriptionStatus() async {
        isLoading = true
        
        var hasActive = false
        
        // 1. Проверяем StoreKit (локальные транзакции)
        do {
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    // Check if transaction is for our subscription products
                    if transaction.productID.contains("premium") {
                        // Check if subscription is still active
                        if let expirationDate = transaction.expirationDate {
                            if expirationDate > Date() {
                                hasActive = true
                                break
                            }
                        } else {
                            // Non-consumable or subscription without expiration
                            hasActive = true
                            break
                        }
                    }
                case .unverified(_, let error):
                    print("Unverified transaction: \(error)")
                }
            }
        } catch {
            print("Error checking StoreKit transactions: \(error)")
        }
        
        // 2. Проверяем API (источник истины - сервер)
        if let registrationId = StorageService.getRegistrationId() {
            do {
                let profileResponse = try await networkService.getProfile(registrationId: registrationId)
                
                if let profile = profileResponse.profile {
                    // API статус имеет приоритет
                    let apiStatus = profile.subscription.isActive
                    hasActive = apiStatus
                    
                    print("📊 Subscription status from API: \(profile.subscription.status) (product_id: \(profile.subscription.productId))")
                }
            } catch {
                print("⚠️ Failed to check subscription status from API: \(error)")
                // Если API недоступен, используем StoreKit статус
            }
        }
        
        hasActiveSubscription = hasActive
        StorageService.setHasActiveSubscription(hasActive)
        
        isLoading = false
    }
    
    /// Быстрая проверка статуса подписки (синхронная, из кеша)
    var hasActiveSubscriptionSync: Bool {
        return StorageService.hasActiveSubscription()
    }
    
    /// Обновляет статус подписки (асинхронно)
    func refreshSubscriptionStatus() async {
        await checkSubscriptionStatus()
    }
}
