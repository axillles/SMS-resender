//
//  HomeViewModel.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var rules: [ForwardingRule] = []
    
    // Функция для имитации добавления (чтобы проверить смену экранов)
    func addTestRule() {
        let newRule = ForwardingRule(type: .email, destination: "test@example.com")
        rules.append(newRule)
    }
}
