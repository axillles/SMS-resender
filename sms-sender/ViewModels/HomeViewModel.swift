//
//  HomeViewModel.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI
import os.log

class HomeViewModel: ObservableObject {
    @Published var rules: [ForwardingRule] = []
    private let logger = Logger(subsystem: "com.sms-sender", category: "HomeViewModel")
    
    init() {
        loadRules()
    }
    
    // Загружает правила из локального хранилища и синхронизирует с сервером
    func loadRules() {
        // Сначала загружаем из локального хранилища
        let localRules = StorageService.getForwardingRules()
        self.rules = localRules
        
        logger.info("📦 Loaded \(localRules.count) rules from local storage")
        
        // Затем синхронизируем с сервером
        Task {
            await syncWithServer()
        }
    }
    
    // Синхронизирует правила с сервером
    private func syncWithServer() async {
        guard let registrationId = StorageService.getRegistrationId() else {
            logger.warning("⚠️ Cannot sync: Device not registered")
            return
        }
        
        do {
            let profileResponse = try await NetworkService.shared.getProfile(registrationId: registrationId)
            
            guard profileResponse.isSuccess, let profile = profileResponse.profile else {
                logger.warning("⚠️ Failed to get profile from server")
                return
            }
            
            // Преобразуем destinations из профиля в правила
            let serverRules = profile.toForwardingRules()
            logger.info("📡 Received \(serverRules.count) rules from server")
            
            // Объединяем правила: приоритет серверным, но сохраняем локальные настройки расписания
            await MainActor.run {
                let mergedRules = mergeRules(localRules: self.rules, serverRules: serverRules)
                self.rules = mergedRules
                
                // Сохраняем объединенные правила
                StorageService.saveForwardingRules(mergedRules)
                logger.info("✅ Synced and saved \(mergedRules.count) rules")
            }
        } catch {
            logger.error("❌ Failed to sync with server: \(error.localizedDescription)")
        }
    }
    
    // Объединяет локальные и серверные правила
    private func mergeRules(localRules: [ForwardingRule], serverRules: [ForwardingRule]) -> [ForwardingRule] {
        var merged: [ForwardingRule] = []
        
        // Создаем словарь локальных правил по типу и destination для быстрого поиска
        var localRulesMap: [String: ForwardingRule] = [:]
        for rule in localRules {
            let key = "\(rule.type.rawValue):\(rule.destination)"
            localRulesMap[key] = rule
        }
        
        // Добавляем серверные правила, сохраняя локальные настройки расписания если они есть
        for serverRule in serverRules {
            let key = "\(serverRule.type.rawValue):\(serverRule.destination)"
            
            if let localRule = localRulesMap[key] {
                // Если правило есть локально, сохраняем настройки расписания
                var mergedRule = serverRule
                mergedRule.isScheduleEnabled = localRule.isScheduleEnabled
                mergedRule.isAllDay = localRule.isAllDay
                mergedRule.startTime = localRule.startTime
                mergedRule.endTime = localRule.endTime
                mergedRule.selectedDays = localRule.selectedDays
                merged.append(mergedRule)
            } else {
                // Новое правило с сервера
                merged.append(serverRule)
            }
        }
        
        return merged
    }
    
    // Функция для имитации добавления (чтобы проверить смену экранов)
    func addTestRule() {
        let newRule = ForwardingRule(type: .email, destination: "test@example.com")
        rules.append(newRule)
    }
}
