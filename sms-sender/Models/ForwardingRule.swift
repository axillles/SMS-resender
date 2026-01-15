//
//  ForwardingRules.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import Foundation

struct ForwardingRule: Identifiable, Codable {
    let id: UUID
    let type: DestinationType
    let destination: String
    var isScheduleEnabled: Bool = false
    var isAllDay: Bool = true
    var startTime: Date?
    var endTime: Date?
    var selectedDays: Set<Int> = []
    
    enum CodingKeys: String, CodingKey {
        case id, type, destination, isScheduleEnabled, isAllDay, startTime, endTime, selectedDays
    }
    
    init(type: DestinationType, destination: String, isScheduleEnabled: Bool = false, isAllDay: Bool = true, startTime: Date? = nil, endTime: Date? = nil, selectedDays: Set<Int> = []) {
        self.id = UUID()
        self.type = type
        self.destination = destination
        self.isScheduleEnabled = isScheduleEnabled
        self.isAllDay = isAllDay
        self.startTime = startTime
        self.endTime = endTime
        self.selectedDays = selectedDays
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(DestinationType.self, forKey: .type)
        destination = try container.decode(String.self, forKey: .destination)
        isScheduleEnabled = try container.decodeIfPresent(Bool.self, forKey: .isScheduleEnabled) ?? false
        isAllDay = try container.decodeIfPresent(Bool.self, forKey: .isAllDay) ?? true
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        let daysArray = try container.decodeIfPresent([Int].self, forKey: .selectedDays) ?? []
        selectedDays = Set(daysArray)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(destination, forKey: .destination)
        try container.encode(isScheduleEnabled, forKey: .isScheduleEnabled)
        try container.encode(isAllDay, forKey: .isAllDay)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(Array(selectedDays), forKey: .selectedDays)
    }
}

