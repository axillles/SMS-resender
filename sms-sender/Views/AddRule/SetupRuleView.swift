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
    @EnvironmentObject var registrationViewModel: RegistrationViewModel
    
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
                        if destinationType == .email {
                            Text("PROVIDE THE EMAIL ADDRESS YOU WISH TO FORWARD TO")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(destinationType.rawValue.uppercased())
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        TextField(getPlaceholderText(), text: $viewModel.destination)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .keyboardType(destinationType == .email ? .emailAddress : .default)
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
                    
                    // Test Message Button (only for email)
                    if destinationType == .email {
                        Button(action: {
                            Task {
                                await viewModel.testEmailConnection(
                                    registrationId: registrationViewModel.getRegistrationId() ?? ""
                                )
                            }
                        }) {
                            HStack {
                                if viewModel.isTesting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text("Send Test Message")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.testSuccess ? Color.green : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isTesting)
                        .padding(.horizontal)
                        
                        if let testError = viewModel.testError {
                            Text(testError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        if viewModel.testSuccess {
                            Text("Test message sent successfully!")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Save Button
                    Button(action: {
                        Task {
                            await saveRule()
                        }
                    }) {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text("Save")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isSaving)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    if let saveError = viewModel.saveError {
                        Text(saveError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(destinationType == .email ? "Email Address" : destinationType.rawValue.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await saveRule()
                    }
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.isSaving || viewModel.destination.isEmpty)
            }
        }
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
    
    private func saveRule() async {
        guard !viewModel.destination.isEmpty else { return }
        
        // For email, save to backend first
        if destinationType == .email {
            guard let registrationId = registrationViewModel.getRegistrationId() else {
                viewModel.saveError = "Device not registered"
                return
            }
            
            do {
                try await viewModel.saveEmail(registrationId: registrationId)
            } catch {
                // Error is already set in viewModel
                return
            }
        }
        
        // Create and save rule locally
        let rule = viewModel.createRule(type: destinationType)
        homeViewModel.rules.append(rule)
        
        // Save to UserDefaults
        StorageService.saveForwardingRules(homeViewModel.rules)
        
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SetupRuleView(destinationType: .email, homeViewModel: HomeViewModel())
    }
}
