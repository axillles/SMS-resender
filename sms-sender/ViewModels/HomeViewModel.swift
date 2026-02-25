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
    
    func loadRules() {
        let localRules = StorageService.getForwardingRules()
        self.rules = localRules
        
        logger.info("📦 Loaded \(localRules.count) rules from local storage")
        
        Task {
            await syncWithServer()
        }
    }
    
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
            
            let serverRules = profile.toForwardingRules()
            logger.info("📡 Received \(serverRules.count) rules from server")
            
            await MainActor.run {
                let mergedRules = mergeRules(localRules: self.rules, serverRules: serverRules)
                self.rules = mergedRules
                
                StorageService.saveForwardingRules(mergedRules)
                logger.info("✅ Synced and saved \(mergedRules.count) rules")
            }
        } catch {
            logger.error("❌ Failed to sync with server: \(error.localizedDescription)")
        }
    }
    
    private func mergeRules(localRules: [ForwardingRule], serverRules: [ForwardingRule]) -> [ForwardingRule] {
        var merged: [ForwardingRule] = []
        
        var localRulesMap: [String: ForwardingRule] = [:]
        for rule in localRules {
            let key = "\(rule.type.rawValue):\(rule.destination)"
            localRulesMap[key] = rule
        }
        
        for serverRule in serverRules {
            let key = "\(serverRule.type.rawValue):\(serverRule.destination)"
            
            if let localRule = localRulesMap[key] {
                var mergedRule = serverRule
                mergedRule.isScheduleEnabled = localRule.isScheduleEnabled
                mergedRule.isAllDay = localRule.isAllDay
                mergedRule.startTime = localRule.startTime
                mergedRule.endTime = localRule.endTime
                mergedRule.selectedDays = localRule.selectedDays
                merged.append(mergedRule)
            } else {
                merged.append(serverRule)
            }
        }
        
        return merged
    }
    
    func addTestRule() {
        let newRule = ForwardingRule(type: .email, destination: "test@example.com")
        rules.append(newRule)
    }
    
    // MARK: - Update Rule
    func updateRule(_ oldRule: ForwardingRule, with newRule: ForwardingRule) {
        guard let index = rules.firstIndex(where: { $0.id == oldRule.id }) else {
            logger.warning("⚠️ Rule not found for update")
            return
        }
        
        let updatedRule = ForwardingRule(
            id: oldRule.id,
            type: newRule.type,
            destination: newRule.destination,
            isScheduleEnabled: newRule.isScheduleEnabled,
            isAllDay: newRule.isAllDay,
            startTime: newRule.startTime,
            endTime: newRule.endTime,
            selectedDays: newRule.selectedDays
        )
        
        rules[index] = updatedRule
        
        StorageService.saveForwardingRules(rules)
        logger.info("✅ Rule updated successfully")
    }

    // MARK: - Delete Rule
    func deleteRule(at offsets: IndexSet) {
        let toRemove = offsets.map { rules[$0] }
        rules.remove(atOffsets: offsets)
        StorageService.saveForwardingRules(rules)
        for rule in toRemove {
            Task { await deleteRuleOnServer(rule) }
        }
        logger.info("✅ Rule(s) deleted locally")
    }

    private func deleteRuleOnServer(_ rule: ForwardingRule) async {
        guard let registrationId = StorageService.getRegistrationId() else { return }
        do {
            switch rule.type {
            case .email:
                _ = try await NetworkService.shared.saveEmail(
                    registrationId: registrationId,
                    emailAddress: rule.destination,
                    delete: true
                )
            case .phone:
                _ = try await NetworkService.shared.deletePhone(
                    registrationId: registrationId,
                    phoneNumber: rule.destination
                )
            case .slack, .api:
                _ = try await NetworkService.shared.saveURL(
                    registrationId: registrationId,
                    url: rule.destination,
                    isSlack: rule.type == .slack,
                    delete: true
                )
            }
            logger.info("✅ Deleted \(rule.type.rawValue) on server")
        } catch {
            logger.error("❌ Failed to delete on server: \(error.localizedDescription)")
        }
    }
}
