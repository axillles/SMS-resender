//
//  PaywallViewModel.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation
import SwiftUI
import StoreKit

@MainActor
class PaywallViewModel: ObservableObject {
    @Published var products: [SubscriptionProduct] = []
    @Published var selectedProduct: SubscriptionProduct?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseInProgress = false
    
    private var storeProducts: [Product] = []
    
    init() {
        // Set default selected product to yearly (better value)
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIds = SubscriptionPeriod.allCases.map { $0.productId }
            storeProducts = try await Product.products(for: productIds)
            
            // Если продукты не найдены (еще не настроены в App Store Connect), используем fallback
            if storeProducts.isEmpty {
                print("⚠️ Products not found in App Store Connect. Using fallback prices.")
                print("💡 После настройки продуктов в App Store Connect цены будут загружаться автоматически.")
                products = createFallbackProducts()
                selectedProduct = products.first(where: { $0.isYearly }) ?? products.first
                isLoading = false
                return
            }
            
            products = storeProducts.compactMap { product in
                guard let period = SubscriptionPeriod.allCases.first(where: { $0.productId == product.id }) else {
                    return nil
                }
                
                return SubscriptionProduct(
                    id: product.id,
                    period: period,
                    price: product.displayPrice,
                    priceValue: product.price,
                    displayPrice: formatPrice(product: product, period: period),
                    product: product
                )
            }.sorted { first, second in
                // Sort: yearly first, then weekly
                if first.isYearly && !second.isYearly {
                    return true
                } else if !first.isYearly && second.isYearly {
                    return false
                }
                return false
            }
            
            // Set default selection to yearly if available
            if let yearlyProduct = products.first(where: { $0.isYearly }) {
                selectedProduct = yearlyProduct
            } else if let firstProduct = products.first {
                selectedProduct = firstProduct
            }
            
            print("✅ Successfully loaded \(products.count) products from App Store Connect")
            
        } catch {
            print("❌ Error loading products: \(error)")
            print("💡 Используются fallback цены. После настройки продуктов в App Store Connect цены будут загружаться автоматически.")
            
            // Fallback to hardcoded prices if StoreKit fails
            products = createFallbackProducts()
            selectedProduct = products.first(where: { $0.isYearly }) ?? products.first
        }
        
        isLoading = false
    }
    
    func purchase() async -> Bool {
        guard let selectedProduct = selectedProduct,
              let product = selectedProduct.product else {
            errorMessage = "Please select a subscription plan"
            return false
        }
        
        purchaseInProgress = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified, complete it
                    await transaction.finish()
                    purchaseInProgress = false
                    return true
                case .unverified(_, let error):
                    errorMessage = "Purchase verification failed: \(error.localizedDescription)"
                    purchaseInProgress = false
                    return false
                }
            case .userCancelled:
                purchaseInProgress = false
                return false
            case .pending:
                errorMessage = "Your purchase is pending approval"
                purchaseInProgress = false
                return false
            @unknown default:
                errorMessage = "Unknown purchase result"
                purchaseInProgress = false
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            purchaseInProgress = false
            return false
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            // Check current entitlements
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    print("Restored transaction: \(transaction.productID)")
                case .unverified(_, let error):
                    print("Unverified transaction: \(error)")
                }
            }
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    var weeklyProduct: SubscriptionProduct? {
        return products.first { !$0.isYearly }
    }
    
    private func formatPrice(product: Product, period: SubscriptionPeriod) -> String {
        switch period {
        case .weekly:
            return "\(product.displayPrice) / week"
        case .yearly:
            return "\(product.displayPrice) / yr"
        }
    }
    
    private func createFallbackProducts() -> [SubscriptionProduct] {
        return [
            SubscriptionProduct(
                id: SubscriptionPeriod.weekly.productId,
                period: .weekly,
                price: "$2.99",
                priceValue: 2.99,
                displayPrice: "$2.99 / week",
                product: nil
            ),
            SubscriptionProduct(
                id: SubscriptionPeriod.yearly.productId,
                period: .yearly,
                price: "$79.99",
                priceValue: 79.99,
                displayPrice: "$79.99 / yr",
                product: nil
            )
        ]
    }
}
