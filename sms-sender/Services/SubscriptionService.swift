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
    
    func checkSubscriptionStatus() async {
        isLoading = true
        
        var hasActive = false
        
        do {
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.productID.contains("premium") {
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
                    hasActive = apiStatus
                    
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
