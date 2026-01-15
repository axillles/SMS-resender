//
//  AddRuleViewModel.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

class SetupRuleViewModel: ObservableObject {
    @Published var destination: String = ""
    @Published var isScheduleEnabled: Bool = false
    @Published var isAllDay: Bool = true
    @Published var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var endTime: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var selectedDays: Set<Int> = [1, 2, 3, 4, 5]
    
    func createRule(type: DestinationType) -> ForwardingRule {
        return ForwardingRule(
            type: type,
            destination: destination,
            isScheduleEnabled: isScheduleEnabled,
            isAllDay: isAllDay,
            startTime: isScheduleEnabled && !isAllDay ? startTime : nil,
            endTime: isScheduleEnabled && !isAllDay ? endTime : nil,
            selectedDays: isScheduleEnabled ? selectedDays : []
        )
    }
}