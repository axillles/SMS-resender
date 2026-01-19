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
        
        // 1. Получаем registration_id
        guard let registrationId = StorageService.getRegistrationId() else {
            logger.error("❌ Cannot forward: Device not registered")
            return
        }
        
        // 2. Получаем все правила пересылки
        let rules = StorageService.getForwardingRules()
        
        if rules.isEmpty {
            logger.warning("⚠️ No forwarding rules found. Message will not be forwarded.")
            return
        }
        
        // 3. Фильтруем правила по расписанию (schedule feature)
        // Schedule feature must be handled at the iOS App End
        // Если у правила включено расписание, но текущее время не попадает в диапазон,
        // правило считается неактивным и не используется для пересылки
        let activeRules = filterRulesBySchedule(rules, currentTime: timestamp)
        
        if activeRules.isEmpty {
            // Если все правила неактивны по расписанию (например, сейчас ночь, 
            // а правила работают только днем), сообщение не отправляется на сервер
            logger.info("ℹ️ No active rules match current schedule. Message will not be forwarded.")
            return
        }
        
        logger.info("✅ Found \(activeRules.count) active rule(s) for forwarding")
        
        // 4. Отправляем на сервер
        // Сервер сам обработает все активные правила и перешлет на все destinations
        // (email, phone, slack, api) согласно настройкам пользователя
        do {
            let response = try await networkService.forward(
                registrationId: registrationId,
                message: message,
                sender: sender,
                timestamp: timestamp,
                subject: subject
            )
            
            if response.isSuccess {
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
    /// Фильтрует правила по расписанию (schedule feature)
    /// Schedule feature must be handled at the iOS App End
    private func filterRulesBySchedule(_ rules: [ForwardingRule], currentTime: Date) -> [ForwardingRule] {
        return rules.filter { rule in
            // Если расписание не включено, правило всегда активно
            guard rule.isScheduleEnabled else {
                return true
            }
            
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: currentTime)
            let currentMinute = calendar.component(.minute, from: currentTime)
            let currentDayOfWeek = calendar.component(.weekday, from: currentTime)
            // Calendar.weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
            // Наш selectedDays: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
            let dayIndex = (currentDayOfWeek == 1) ? 0 : currentDayOfWeek - 1
            
            // Проверяем день недели
            guard rule.selectedDays.contains(dayIndex) else {
                return false
            }
            
            // Если весь день, правило активно
            if rule.isAllDay {
                return true
            }
            
            // Проверяем время
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
            
            // Проверяем, попадает ли текущее время в диапазон
            if startMinutes <= endMinutes {
                // Обычный случай: начало < конец (например, 9:00 - 17:00)
                return currentMinutes >= startMinutes && currentMinutes <= endMinutes
            } else {
                // Переход через полночь (например, 22:00 - 6:00)
                return currentMinutes >= startMinutes || currentMinutes <= endMinutes
            }
        }
    }
}
