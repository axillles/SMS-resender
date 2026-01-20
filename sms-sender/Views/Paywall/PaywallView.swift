//
//  PaywallView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//
//  Paywall экран для подписки Premium
//  Готов для интеграции с Apple IAP (StoreKit 2)
//
//  Пример использования:
//  @State private var showPaywall = false
//  
//  Button("Show Paywall") {
//      showPaywall = true
//  }
//  .sheet(isPresented: $showPaywall) {
//      PaywallView(isPresented: $showPaywall)
//  }

import SwiftUI

struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) var dismiss
    var isPresented: Binding<Bool>?
    
    init(isPresented: Binding<Bool>? = nil) {
        self.isPresented = isPresented
    }
    
    private func handlePurchaseSuccess() {
        // Update subscription status after successful purchase
        // Это проверит и StoreKit транзакции, и API статус
        Task {
            await SubscriptionService.shared.refreshSubscriptionStatus()
        }
        dismiss()
        isPresented?.wrappedValue = false
    }
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.08, blue: 0.25),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.products.isEmpty {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Top bar with Skip button
                        topBar
                            .padding(.top, 10)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        
                        // Premium badge
                        premiumBadge
                            .padding(.bottom, 30)
                        
                        // Title
                        titleSection
                            .padding(.bottom, 40)
                        
                        // Feature icons in triangle
                        featureIconsSection
                            .padding(.bottom, 20)
                        
                        // Pagination dots
                        paginationDots
                            .padding(.bottom, 40)
                        
                        // Subscription Options
                        if !viewModel.products.isEmpty {
                            subscriptionOptionsSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)
                        }
                        
                        // CTA Button
                        ctaButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        
                        // Footer
                        footerSection
                            .padding(.bottom, 30)
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: {
                dismiss()
                isPresented?.wrappedValue = false
            }) {
                Text("Skip")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Premium Badge
    
    private var premiumBadge: some View {
        Text("PREMIUM")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
            )
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        Text("Manage everything in one place")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }
    
    // MARK: - Feature Icons Section
    
    private var featureIconsSection: some View {
        ZStack {
            // Triangle layout for icons
            VStack(spacing: 0) {
                // Top icon (green - phone with arrows)
                // Можно использовать системную иконку или кастомное изображение
                // Для кастомного: добавьте изображение в Assets.xcassets (например, "phone-icon") или используйте имя файла "phone-icon.png"
                FeatureIconView(
                    icon: "arrow.triangle.2.circlepath.phone.fill", // Системная иконка SF Symbols
                    color: .green,
                    size: 60
                )
                .offset(y: -30)
                
                HStack(spacing: 80) {
                    // Left icon (red - envelope)
                    FeatureIconView(
                        icon: "envelope.fill", // Системная иконка SF Symbols
                        color: .red,
                        size: 60
                    )
                    .offset(x: -20)
                    
                    // Right icon (teal - custom image)
                    // Пример использования кастомного изображения: "slack.webp" или "slack" (если в Assets)
                    FeatureIconView(
                        icon: "slack.png", // Кастомное изображение (должно быть в Assets или bundle)
                        color: .cyan,
                        size: 60
                    )
                    .offset(x: 20)
                }
            }
        }
        .frame(height: 180)
    }
    
    // MARK: - Pagination Dots
    
    private var paginationDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index == 0 ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    // MARK: - Subscription Options
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.products) { product in
                SubscriptionOptionView(
                    product: product,
                    weeklyProduct: viewModel.weeklyProduct,
                    isSelected: viewModel.selectedProduct?.id == product.id
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedProduct = product
                    }
                }
            }
        }
    }
    
    // MARK: - CTA Button
    
    private var ctaButton: some View {
        Button(action: {
            Task {
                let success = await viewModel.purchase()
                if success {
                    handlePurchaseSuccess()
                }
            }
        }) {
            HStack {
                if viewModel.purchaseInProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Start 7-day free trial")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.4, blue: 1.0), // Blue
                        Color(red: 0.5, green: 0.2, blue: 0.8)    // Purple
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
        .disabled(viewModel.purchaseInProgress || viewModel.isLoading || viewModel.products.isEmpty)
        .opacity((viewModel.purchaseInProgress || viewModel.isLoading || viewModel.products.isEmpty) ? 0.6 : 1.0)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                // Handle referral code
            }) {
                Text("Have a referral code?")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Button(action: {
                Task {
                    await viewModel.restorePurchases()
                }
            }) {
                Text("Restore purchase")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Button(action: {
                // Open Terms & Conditions
                if let url = URL(string: "https://yourwebsite.com/terms") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Terms & Conditions")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Feature Icon View

struct FeatureIconView: View {
    let icon: String
    let color: Color
    let size: CGFloat
    
    // Проверяем, является ли иконка системной (SF Symbol) или кастомным изображением
    private var isSystemIcon: Bool {
        // Если иконка содержит точку (например, "slack.webp"), это кастомное изображение
        return !icon.contains(".")
    }
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size + 20, height: size + 20)
                .blur(radius: 15)
            
            // Icon circle
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            
            if isSystemIcon {
                // Системная иконка SF Symbols
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(color)
            } else {
                // Кастомное изображение (например, slack.webp)
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.5, height: size * 0.5)
                    .foregroundColor(color)
            }
        }
    }
}

// MARK: - Subscription Option View

struct SubscriptionOptionView: View {
    let product: SubscriptionProduct
    let weeklyProduct: SubscriptionProduct?
    let isSelected: Bool
    let onTap: () -> Void
    
    private var monthlyPrice: String {
        if product.isYearly {
            // For yearly, show price per month (divide by 12)
            let monthly = product.priceValue / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.maximumFractionDigits = 2
            return formatter.string(from: monthly as NSDecimalNumber) ?? "$0.00"
        } else {
            // For weekly, show price per month (multiply by 4.33)
            let monthly = product.priceValue * 4.33
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.maximumFractionDigits = 2
            return formatter.string(from: monthly as NSDecimalNumber) ?? "$0.00"
        }
    }
    
    private var totalBilled: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        let total = formatter.string(from: product.priceValue as NSDecimalNumber) ?? "$0.00"
        
        if product.isYearly {
            // For yearly, show as "quarterly" to match design (though it's actually yearly)
            return "\(total) billed quarterly"
        } else {
            return "\(total) billed monthly"
        }
    }
    
    private var periodDisplayName: String {
        // Show "Quarterly" for yearly to match design
        if product.isYearly {
            return "Quarterly"
        } else {
            return "Monthly"
        }
    }
    
    private var savingsAmount: String? {
        guard product.isYearly, let weeklyProduct = weeklyProduct else { return nil }
        let weeklyYearlyEquivalent = weeklyProduct.priceValue * 52
        let savings = weeklyYearlyEquivalent - product.priceValue
        guard savings > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: savings as NSDecimalNumber)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(periodDisplayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(monthlyPrice) / month")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(totalBilled)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // Savings badge
                if let savings = savingsAmount, product.isYearly {
                    Text("\(savings) OFF")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? 
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.5, green: 0.2, blue: 0.8),
                                        Color(red: 0.2, green: 0.4, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) : 
                                LinearGradient(
                                    colors: [Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
            )
            .shadow(color: isSelected ? Color.purple.opacity(0.3) : Color.clear, radius: isSelected ? 10 : 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView(isPresented: .constant(true))
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    PaywallView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}
