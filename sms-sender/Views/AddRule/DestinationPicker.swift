//
//  DestinationPicker.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

struct DestinationPicker: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @EnvironmentObject var registrationViewModel: RegistrationViewModel
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedDestination: DestinationType?
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 2x2 Grid of destination buttons
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        DestinationButton(
                            type: .email,
                            icon: DestinationType.email.iconName,
                            title: "Email"
                        ) {
                            handleDestinationSelection(.email)
                        }
                        
                        DestinationButton(
                            type: .phone,
                            icon: DestinationType.phone.iconName,
                            title: "Phone"
                        ) {
                            handleDestinationSelection(.phone)
                        }
                    }
                    
                    HStack(spacing: 20) {
                        DestinationButton(
                            type: .slack,
                            icon: "number",
                            title: "Slack"
                        ) {
                            handleDestinationSelection(.slack)
                        }
                        
                        DestinationButton(
                            type: .api,
                            icon: DestinationType.api.iconName,
                            title: "API"
                        ) {
                            handleDestinationSelection(.api)
            }
        }
    }
                .padding()
            }
        }
        .navigationTitle("New Destination")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedDestination) { destination in
            SetupRuleView(destinationType: destination, homeViewModel: homeViewModel)
                .environmentObject(registrationViewModel)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
        }
        .onChange(of: showPaywall) { oldValue, newValue in
            // После закрытия paywall проверяем статус подписки
            if oldValue == true && newValue == false {
                Task {
                    await subscriptionService.checkSubscriptionStatus()
                    // Если подписка активирована, разрешаем добавление правила
                    if subscriptionService.hasActiveSubscription, let pendingDestination = selectedDestination {
                        // selectedDestination уже установлен, navigation произойдет автоматически
                    }
                }
            }
        }
        .task {
            // Проверяем статус подписки при открытии
            await subscriptionService.checkSubscriptionStatus()
        }
    }
    
    private func handleDestinationSelection(_ destination: DestinationType) {
        // Проверяем подписку перед добавлением правила
        if subscriptionService.hasActiveSubscription {
            selectedDestination = destination
        } else {
            // Сохраняем выбранное назначение и показываем paywall
            selectedDestination = destination
            showPaywall = true
        }
    }
}

struct DestinationButton: View {
    let type: DestinationType
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.black)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .frame(width: 150, height: 150)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black, lineWidth: 1)
            )
    }
}
}

#Preview {
    NavigationStack {
        DestinationPicker(homeViewModel: HomeViewModel())
    }
}
