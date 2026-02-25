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
        hasActiveSubscription = StorageService.hasActiveSubscription()
        // Не вызываем checkSubscriptionStatus() при старте — это запрашивает вход в Apple ID.
        // Полная проверка только при Restore и после покупки.
    }
    
    /// Проверка по локальным транзакциям и API. Без AppStore.sync() — он вызывает плашку входа в Apple ID.
    func checkSubscriptionStatus() async {
        isLoading = true
        
        var hasActive = false
        
        do {
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    let isOurSubscription = SubscriptionPeriod.allCases.contains { $0.productId == transaction.productID }
                    if isOurSubscription {
                        if let expirationDate = transaction.expirationDate {
                            if expirationDate > Date() {
                                hasActive = true
                                break
                            }
                        } else {
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
        
        if let registrationId = StorageService.getRegistrationId() {
            do {
                let profileResponse = try await networkService.getProfile(registrationId: registrationId)
                
                if let profile = profileResponse.profile {
                    let apiStatus = profile.subscription.isActive
                    // Не перезаписываем StoreKit: если подписка активна по чекам — считаем активной.
                    // API может отставать (серверные нотификации), в TestFlight это часто так.
                    hasActive = hasActive || apiStatus
                    
                    print("📊 Subscription status from API: \(profile.subscription.status) (product_id: \(profile.subscription.productId))")
                }
            } catch {
                print("⚠️ Failed to check subscription status from API: \(error)")
            }
        }
        
        hasActiveSubscription = hasActive
        StorageService.setHasActiveSubscription(hasActive)
        
        isLoading = false
    }
    
    var hasActiveSubscriptionSync: Bool {
        return StorageService.hasActiveSubscription()
    }
    
    func refreshSubscriptionStatus() async {
        await checkSubscriptionStatus()
    }

    func restorePurchases() async -> RestoreResult {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            return hasActiveSubscription ? .success : .noPurchasesFound
        } catch {
            return .failure(error)
        }
    }
}

enum RestoreResult {
    case success
    case noPurchasesFound
    case failure(Error)
}
