//
//  ContentView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var registrationViewModel: RegistrationViewModel
    
    var body: some View {
        Group {
            if registrationViewModel.isRegistering {
                RegistrationLoadingView()
            } else if let error = registrationViewModel.registrationError {
                RegistrationErrorView(error: error) {
                    Task {
                        await registrationViewModel.register()
                    }
                }
            } else {
                HomeView()
            }
        }
    }
}

// MARK: - Registration Loading View
struct RegistrationLoadingView: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Registering device...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Registration Error View
struct RegistrationErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("Registration Failed")
                    .font(.headline)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RegistrationViewModel())
}
