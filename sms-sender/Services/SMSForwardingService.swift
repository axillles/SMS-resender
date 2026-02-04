//
//  SMSForwardingService.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation
import os.log

class SMSForwardingService {
    static let shared = SMSForwardingService()
    private let logger = Logger(subsystem: "com.sms-sender", category: "SMSForwardingService")
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // MARK: - Forward SMS Message
    /// Обрабатывает входящее SMS сообщение от Shortcuts и пересылает на сервер
    /// - Parameters:
    ///   - message: Текст сообщения
    ///   - sender: Номер отправителя
    ///   - timestamp: Время получения сообщения
    ///   - subject: Опциональный заголовок
    func forwardSMS(message: String, sender: String, timestamp: Date, subject: String? = nil) async {
        logger.info("📨 Received SMS forwarding request: sender=\(sender), message length=\(message.count)")
        
        await SubscriptionService.shared.checkSubscriptionStatus()
        if await !SubscriptionService.shared.hasActiveSubscription {
            logger.error("❌ Cannot forward: No active subscription")
            return
        }
        
        guard let registrationId = StorageService.getRegistrationId() else {
            logger.error("❌ Cannot forward: Device not registered")
            return
        }
        
        let rules = StorageService.getForwardingRules()
        
        if rules.isEmpty {
            logger.warning("⚠️ No forwarding rules found. Message will not be forwarded.")
            return
        }
        
       
        let activeRules = filterRulesBySchedule(rules, currentTime: timestamp)
        
        if activeRules.isEmpty {
            
            logger.info("ℹ️ No active rules match current schedule. Message will not be forwarded.")
            return
        }
        
        logger.info("✅ Found \(activeRules.count) active rule(s) for forwarding")
        
        
        do {
            let response = try await networkService.forward(
                registrationId: registrationId,
                message: message,
                sender: sender,
                timestamp: timestamp,
                subject: subject
            )
            
            if response.isSuccess {
                if !StorageService.hasForwardedFirstMessage() {
                    StorageService.setHasForwardedFirstMessage(true)
                    logger.info("🎉 First message forwarded successfully!")
                    NotificationCenter.default.post(name: .firstMessageForwarded, object: nil)
                }
                
                if let details = response.details {
                    logger.info("✅ Message forwarded successfully. Sent: \(details.sent), Failed: \(details.failed)")
                } else {
                    logger.info("✅ Message forwarded successfully")
                }
            } else {
                logger.error("❌ Failed to forward message: \(response.message ?? "Unknown error")")
            }
        } catch {
            logger.error("❌ Error forwarding message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Schedule Filtering

    private func filterRulesBySchedule(_ rules: [ForwardingRule], currentTime: Date) -> [ForwardingRule] {
        return rules.filter { rule in
            guard rule.isScheduleEnabled else {
                return true
            }
            
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: currentTime)
            let currentMinute = calendar.component(.minute, from: currentTime)
            let currentDayOfWeek = calendar.component(.weekday, from: currentTime)
            let dayIndex = (currentDayOfWeek == 1) ? 0 : currentDayOfWeek - 1
            
            guard rule.selectedDays.contains(dayIndex) else {
                return false
            }
            
            if rule.isAllDay {
                return true
            }
            
            guard let startTime = rule.startTime,
                  let endTime = rule.endTime else {
                return true
            }
            
            let startHour = calendar.component(.hour, from: startTime)
            let startMinute = calendar.component(.minute, from: startTime)
            let endHour = calendar.component(.hour, from: endTime)
            let endMinute = calendar.component(.minute, from: endTime)
            
            let currentMinutes = currentHour * 60 + currentMinute
            let startMinutes = startHour * 60 + startMinute
            let endMinutes = endHour * 60 + endMinute
            
            if startMinutes <= endMinutes {
                return currentMinutes >= startMinutes && currentMinutes <= endMinutes
            } else {
                return currentMinutes >= startMinutes || currentMinutes <= endMinutes
            }
        }
    }
}
