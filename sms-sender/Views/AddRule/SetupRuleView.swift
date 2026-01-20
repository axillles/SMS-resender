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
                                .keyboardType(.emailAddress)
                        } else if destinationType == .phone {
                            Text("PROVIDE THE PHONE NUMBER YOU WISH TO FORWARD TO")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Country Code Picker
                            HStack(spacing: 12) {
                                Menu {
                                    ForEach(CountryCode.allCodes) { countryCode in
                                        Button(action: {
                                            viewModel.selectedCountryCode = countryCode
                                        }) {
                                            HStack {
                                                Text(countryCode.displayName)
                                                if viewModel.selectedCountryCode.code == countryCode.code {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedCountryCode.displayName)
                                            .foregroundColor(.primary)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                            
                            // Phone Number Input
                            TextField("5551234567", text: $viewModel.phoneNumber)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                                .keyboardType(.phonePad)
                        } else {
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
                                .autocapitalization(.none)
                                .keyboardType(.default)
                        }
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
                    
                    // Test Message Button (for email, phone, slack, api)
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
                    
                    // OTP Error for phone
                    if destinationType == .phone, let otpError = viewModel.otpError {
                        Text(otpError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
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
        
        // For email, save to backend first
        if destinationType == .email {
            guard !viewModel.destination.isEmpty else { return }
            
            do {
                try await viewModel.saveEmail(registrationId: registrationId)
            } catch {
                // Error is already set in viewModel
                return
            }
        }
        // For phone, save with OTP
        else if destinationType == .phone {
            guard !viewModel.phoneNumber.isEmpty else { return }
            guard !viewModel.otpCode.isEmpty else {
                // Request OTP first if not already requested
                await viewModel.requestOTP(registrationId: registrationId)
                return // Don't dismiss, wait for OTP
            }
            
            do {
                try await viewModel.savePhone(registrationId: registrationId)
            } catch {
                // Error is already set in viewModel
                return
            }
        }
        // For Slack/API, save to backend
        else if destinationType == .slack || destinationType == .api {
            guard !viewModel.destination.isEmpty else { return }
            
            do {
                try await viewModel.saveURL(registrationId: registrationId, destinationType: destinationType)
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
        
        // Show paywall after adding rule if no active subscription
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !SubscriptionService.shared.hasActiveSubscription {
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
