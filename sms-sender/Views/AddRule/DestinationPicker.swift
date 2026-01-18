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
    @Environment(\.dismiss) var dismiss
    @State private var selectedDestination: DestinationType?
    
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
                            selectedDestination = .email
                        }
                        
                        DestinationButton(
                            type: .phone,
                            icon: DestinationType.phone.iconName,
                            title: "Phone"
                        ) {
                            selectedDestination = .phone
                        }
                    }
                    
                    HStack(spacing: 20) {
                        DestinationButton(
                            type: .slack,
                            icon: "number",
                            title: "Slack"
                        ) {
                            selectedDestination = .slack
                        }
                        
                        DestinationButton(
                            type: .api,
                            icon: DestinationType.api.iconName,
                            title: "API"
                        ) {
                            selectedDestination = .api
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
