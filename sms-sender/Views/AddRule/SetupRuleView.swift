//
//  SetupRuleView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import SwiftUI

struct SetupRuleView: View {
    let destinationType: DestinationType
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SetupRuleViewModel()
    @ObservedObject var homeViewModel: HomeViewModel
    
    init(destinationType: DestinationType, homeViewModel: HomeViewModel) {
        self.destinationType = destinationType
        self._homeViewModel = ObservedObject(wrappedValue: homeViewModel)
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Destination input section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(destinationType.rawValue.uppercased())
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField(getPlaceholderText(), text: $viewModel.destination)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Schedule Component
                    ScheduleComponent(
                        isScheduleEnabled: $viewModel.isScheduleEnabled,
                        isAllDay: $viewModel.isAllDay,
                        startTime: $viewModel.startTime,
                        endTime: $viewModel.endTime,
                        selectedDays: $viewModel.selectedDays
                    )
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: {
                        saveRule()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(destinationType.rawValue.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getPlaceholderText() -> String {
        switch destinationType {
        case .email:
            return "email@example.com"
        case .phone:
            return "+1234567890"
        case .slack:
            return "Slack webhook URL"
        case .api:
            return "API endpoint URL"
        }
    }
    
    private func saveRule() {
        guard !viewModel.destination.isEmpty else { return }
        let rule = viewModel.createRule(type: destinationType)
        homeViewModel.rules.append(rule)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SetupRuleView(destinationType: .email, homeViewModel: HomeViewModel())
    }
}
