//
//  SettingsViewModel.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

final class SettingsViewModel: ObservableObject {

    // MARK: - Sections
    let subscriptionSection: [SettingsRow] = [
        SettingsRow(
            title: "Subscription plans",
            icon: "starburst.fill",
            action: .subscription
        )
    ]

    let instructionsSection: [SettingsRow] = [
        SettingsRow(
            title: "Setup Instructions",
            icon: "questionmark.circle",
            action: .setup
        ),
        SettingsRow(
            title: "Restore Purchase",
            icon: "person.crop.circle",
            action: .restore
        )
    ]

    let supportSection: [SettingsRow] = [
        SettingsRow(
            title: "Privacy Policy",
            icon: "lock.fill",
            action: .privacy
        ),
        SettingsRow(
            title: "Terms of Use",
            icon: "doc.text",
            action: .terms
        ),
        SettingsRow(
            title: "Delete Account",
            icon: "trash",
            action: .deleteAccount
        ),
        SettingsRow(
            title: "Contact Us",
            icon: "envelope",
            action: .contact
        )
    ]

    // MARK: - Navigation
    @Published var selectedAction: SettingsAction?
}
