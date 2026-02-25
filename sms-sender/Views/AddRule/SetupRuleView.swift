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
    let editingRule: ForwardingRule?
    var onSaveComplete: (() -> Void)?
    
    init(destinationType: DestinationType, homeViewModel: HomeViewModel, editingRule: ForwardingRule? = nil, onSaveComplete: (() -> Void)? = nil) {
        self.destinationType = destinationType
        self._homeViewModel = ObservedObject(wrappedValue: homeViewModel)
        self.editingRule = editingRule
        self.onSaveComplete = onSaveComplete
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        if destinationType == .email {
                            Text("PROVIDE THE EMAIL ADDRESS YOU WISH TO FORWARD TO")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField(getPlaceholderText(), text: $viewModel.destination)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(UIColor.separator), lineWidth: 1)
                                )
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        } else if destinationType == .phone {
                            Text("PROVIDE THE PHONE NUMBER YOU WISH TO FORWARD TO")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("+15551234567", text: $viewModel.phoneNumber)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(UIColor.separator), lineWidth: 1)
                                )
                                .keyboardType(.phonePad)
                                .autocapitalization(.none)
                        } else {
                            Text(destinationType.rawValue.uppercased())
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField(getPlaceholderText(), text: $viewModel.destination)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(UIColor.separator), lineWidth: 1)
                                )
                                .autocapitalization(.none)
                                .keyboardType(.default)
                        }
                    }
                    .padding(.horizontal)
                    
                    ScheduleComponent(
                        isScheduleEnabled: $viewModel.isScheduleEnabled,
                        isAllDay: $viewModel.isAllDay,
                        startTime: $viewModel.startTime,
                        endTime: $viewModel.endTime,
                        selectedDays: $viewModel.selectedDays
                    )
                    .padding(.horizontal)
                    
                    if destinationType == .email || destinationType == .phone || destinationType == .slack || destinationType == .api {
                        Button(action: {
                            Task {
                                guard let registrationId = registrationViewModel.getRegistrationId() else {
                                    viewModel.testError = "Device not registered"
                                    return
                                }
                                
                                if destinationType == .email {
                                    await viewModel.testEmailConnection(registrationId: registrationId)
                                } else if destinationType == .phone {
                                    await viewModel.testPhoneConnection(registrationId: registrationId)
                                } else if destinationType == .slack || destinationType == .api {
                                    await viewModel.testWebhookConnection(
                                        registrationId: registrationId,
                                        destinationType: destinationType
                                    )
                                }
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
                    
                    if destinationType == .phone, let otpError = viewModel.otpError {
                        Text(otpError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
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
                            .foregroundColor(Color(UIColor.systemBackground))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
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
        .navigationTitle(destinationType == .email ? "Email Address" : (destinationType == .phone ? "Phone Number" : destinationType.rawValue.capitalized))
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
                .disabled(viewModel.isSaving || (destinationType == .phone ? viewModel.phoneNumber.isEmpty : viewModel.destination.isEmpty))
            }
        }
        .onAppear {
            if let rule = editingRule {
                viewModel.loadRule(rule)
            }
        }
        .alert("Alert", isPresented: $viewModel.showOTPAlert) {
            TextField("Enter OTP", text: $viewModel.otpCode)
                .keyboardType(.numberPad)
            Button("No", role: .cancel) {
                viewModel.otpCode = ""
                viewModel.showOTPAlert = false
            }
            Button("Yes") {
                Task {
                    await saveRule()
                }
            }
        } message: {
            Text("Enter OTP sent to your phone number")
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
        guard let registrationId = registrationViewModel.getRegistrationId() else {
            viewModel.saveError = "Device not registered"
            return
        }
        
        if let editingRule = editingRule {
            let newDestination: String
            if destinationType == .phone {
                newDestination = viewModel.fullPhoneNumber
            } else {
                newDestination = viewModel.destination
            }
            
            if editingRule.destination != newDestination {
                do {
                    if editingRule.type == .email {
                        _ = try await NetworkService.shared.saveEmail(
                            registrationId: registrationId,
                            emailAddress: editingRule.destination,
                            delete: true
                        )
                    } else if editingRule.type == .phone {
                        _ = try await NetworkService.shared.deletePhone(
                            registrationId: registrationId,
                            phoneNumber: editingRule.destination
                        )
                    } else if editingRule.type == .slack || editingRule.type == .api {
                        _ = try await NetworkService.shared.saveURL(
                            registrationId: registrationId,
                            url: editingRule.destination,
                            isSlack: editingRule.type == .slack,
                            delete: true
                        )
                    }
                } catch {
                    viewModel.saveError = "Failed to delete old destination: \(error.localizedDescription)"
                    return
                }
            }
        }
        
        if destinationType == .email {
            guard !viewModel.destination.isEmpty else { return }
            
            do {
                try await viewModel.saveEmail(registrationId: registrationId)
            } catch {
                return
            }
        }
        else if destinationType == .phone {
            guard !viewModel.phoneNumber.isEmpty else { return }
            
            let newDestination = viewModel.fullPhoneNumber
            let destinationChanged = editingRule?.destination != newDestination
            
            if destinationChanged {
                guard !viewModel.otpCode.isEmpty else {
                    await viewModel.requestOTP(registrationId: registrationId)
                    return
                }
            }
            
            if destinationChanged {
                do {
                    try await viewModel.savePhone(registrationId: registrationId)
                } catch {
                    return
                }
            }
        }
        else if destinationType == .slack || destinationType == .api {
            guard !viewModel.destination.isEmpty else { return }
            
            let destinationChanged = editingRule?.destination != viewModel.destination
            if destinationChanged {
                do {
                    try await viewModel.saveURL(registrationId: registrationId, destinationType: destinationType)
                } catch {
                    return
                }
            }
        }
        
        let rule = viewModel.createRule(type: destinationType)
        
        if let editingRule = editingRule {
            homeViewModel.updateRule(editingRule, with: rule)
        } else {
            homeViewModel.rules.append(rule)
        }
        
        StorageService.saveForwardingRules(homeViewModel.rules)
        
        dismiss()
        
        if editingRule == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSaveComplete?()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !SubscriptionService.shared.hasActiveSubscriptionSync {
                NotificationCenter.default.post(name: .showPaywall, object: nil)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SetupRuleView(destinationType: .email, homeViewModel: HomeViewModel())
    }
}
