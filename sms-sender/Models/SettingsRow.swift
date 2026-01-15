//
//  SettingsRow.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import SwiftUI

struct SettingsRow: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: SettingsAction
}

enum SettingsAction {
    case subscription
    case setup
    case restore
    case privacy
    case terms
    case deleteAccount
    case contact
}
