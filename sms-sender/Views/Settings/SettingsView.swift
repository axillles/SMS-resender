//
//  SettingsView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    settingsSection(
                        title: nil,
                        rows: viewModel.subscriptionSection
                    )

                    settingsSection(
                        title: "Instructions",
                        rows: viewModel.instructionsSection
                    )

                    settingsSection(
                        title: "Support",
                        rows: viewModel.supportSection
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationDestination(item: $viewModel.selectedAction) { action in
                destinationView(for: action)
            }
            .onChange(of: viewModel.selectedAction) { oldValue, newValue in
                if newValue == .showOnboarding {
                    // Post notification to show onboarding
                    NotificationCenter.default.post(name: .showOnboarding, object: nil)
                    // Reset selection after a moment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.selectedAction = nil
                    }
                }
            }
        }
    }

    // MARK: - Section
    private func settingsSection(
        title: String?,
        rows: [SettingsRow]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            if let title {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
            }

            VStack(spacing: 1) {
                ForEach(rows) { row in
                    Button {
                        viewModel.selectedAction = row.action
                    } label: {
                        SettingsRowView(row: row)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 1)
        }
    }

    // MARK: - Navigation
    @ViewBuilder
    private func destinationView(for action: SettingsAction) -> some View {
        switch action {
        case .subscription:
            Text("Subscription plans")

        case .setup:
            Text("Setup Instructions")

        case .restore:
            Text("Restore Purchase")
            
        case .showOnboarding:
            // This case is handled in onChange, but we need it for the switch
            EmptyView()

        case .privacy:
            Text("Privacy Policy")

        case .terms:
            Text("Terms of Use")

        case .deleteAccount:
            Text("Delete Account")

        case .contact:
            Text("Contact Us")
        }
    }
}

struct SettingsRowView: View {
    let row: SettingsRow

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: row.icon)
                .frame(width: 24)
                .foregroundColor(.gray)

            Text(row.title)
                .foregroundColor(.black)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
    }
}

#Preview {
    SettingsView()
}
