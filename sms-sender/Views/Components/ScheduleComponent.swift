//
//  ScheduleComponent.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import SwiftUI

struct ScheduleComponent: View {
    @Binding var isScheduleEnabled: Bool
    @Binding var isAllDay: Bool
    @Binding var startTime: Date
    @Binding var endTime: Date
    @Binding var selectedDays: Set<Int>
    
    private let daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"]
    private let dayIndices = [2, 3, 4, 5, 6, 7, 1] // Monday = 2, Sunday = 1 (Calendar standard)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SCHEDULE")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Enable Schedule Toggle
            HStack {
                Text("Enable Schedule")
                    .font(.body)
                Spacer()
                Toggle("", isOn: $isScheduleEnabled)
                    .labelsHidden()
            }
            
            if isScheduleEnabled {
                // All Day Toggle
                HStack {
                    Text("All Day")
                        .font(.body)
                    Spacer()
                    Toggle("", isOn: $isAllDay)
                        .labelsHidden()
                }
                
                // Start Time
                if !isAllDay {
                    HStack {
                        Text("Start Time")
                            .font(.body)
                        Spacer()
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    // End Time
                    HStack {
                        Text("End Time")
                            .font(.body)
                        Spacer()
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
                
                // Days of Week
                HStack(spacing: 12) {
                    ForEach(0..<7) { index in
                        DayButton(
                            day: daysOfWeek[index],
                            dayIndex: dayIndices[index],
                            isSelected: selectedDays.contains(dayIndices[index])
                        ) {
                            if selectedDays.contains(dayIndices[index]) {
                                selectedDays.remove(dayIndices[index])
                            } else {
                                selectedDays.insert(dayIndices[index])
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct DayButton: View {
    let day: String
    let dayIndex: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.black : Color.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                )
        }
    }
}

#Preview {
    ScheduleComponent(
        isScheduleEnabled: .constant(true),
        isAllDay: .constant(true),
        startTime: .constant(Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()),
        endTime: .constant(Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()),
        selectedDays: .constant([2, 3, 4, 5, 6])
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
