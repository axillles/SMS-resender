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
    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreResult: RestoreResult?

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
            .sheet(isPresented: $showPaywall) {
                PaywallView(isPresented: $showPaywall)
            }
            .overlay {
                if isRestoring {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Restoring…")
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .disabled(isRestoring)
            .onChange(of: viewModel.selectedAction) { oldValue, newValue in
                guard let newValue else { return }
                switch newValue {
                case .subscription:
                    showPaywall = true
                    viewModel.selectedAction = nil
                case .restore:
                    viewModel.selectedAction = nil
                    runRestorePurchases()
                case .showOnboarding:
                    NotificationCenter.default.post(name: .showOnboarding, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.selectedAction = nil
                    }
                default:
                    break
                }
            }
            .alert("Restore Purchase", isPresented: Binding(
                get: { restoreResult != nil },
                set: { if !$0 { restoreResult = nil } }
            )) {
                Button("OK", role: .cancel) {
                    restoreResult = nil
                }
            } message: {
                if let result = restoreResult {
                    Text(restoreMessage(for: result))
                }
            }
        }
    }

    private func runRestorePurchases() {
        isRestoring = true
        Task { @MainActor in
            let result = await SubscriptionService.shared.restorePurchases()
            isRestoring = false
            restoreResult = result
        }
    }

    private func restoreMessage(for result: RestoreResult) -> String {
        switch result {
        case .success:
            return "Your subscription has been restored."
        case .noPurchasesFound:
            return "No previous purchases found for this Apple ID."
        case .failure(let error):
            return "Restore failed: \(error.localizedDescription)"
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
                    .foregroundColor(.secondary)
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
            EmptyView()

        case .restore:
            EmptyView()
            
        case .showOnboarding:
            EmptyView()

        case .privacy:
            Text("Privacy Policy")

        case .terms:
            Text("Terms of Use")

        case .deleteAccount:
            Text("Delete Account")

        case .contact:
            Text("Contact Us")
            
        case .setup:
            EmptyView()
        }
    }
}

struct SettingsRowView: View {
    let row: SettingsRow

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: row.icon)
                .frame(width: 24)
                .foregroundColor(.secondary)

            Text(row.title)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}

#Preview {
    SettingsView()
}
