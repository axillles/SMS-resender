//
//  StorageService.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

class StorageService {
    private static let userDefaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let registrationId = "registration_id"
        static let deviceName = "device_name"
        static let iosVersion = "ios_version"
        static let appVersion = "app_version"
        static let isRegistered = "is_registered"
        static let lastProfileSync = "last_profile_sync"
        static let forwardingRules = "forwarding_rules"
    }
    
    // MARK: - Registration ID
    static func saveRegistrationId(_ id: String) {
        userDefaults.set(id, forKey: Keys.registrationId)
    }
    
    static func getRegistrationId() -> String? {
        return userDefaults.string(forKey: Keys.registrationId)
    }
    
    static func deleteRegistrationId() {
        userDefaults.removeObject(forKey: Keys.registrationId)
    }
    
    // MARK: - Device Info
    static func saveDeviceInfo(name: String, iosVersion: String, appVersion: String) {
        userDefaults.set(name, forKey: Keys.deviceName)
        userDefaults.set(iosVersion, forKey: Keys.iosVersion)
        userDefaults.set(appVersion, forKey: Keys.appVersion)
    }
    
    static func getDeviceInfo() -> (name: String?, iosVersion: String?, appVersion: String?) {
        return (
            userDefaults.string(forKey: Keys.deviceName),
            userDefaults.string(forKey: Keys.iosVersion),
            userDefaults.string(forKey: Keys.appVersion)
        )
    }
    
    // MARK: - Registration Status
    static func setRegistered(_ isRegistered: Bool) {
        userDefaults.set(isRegistered, forKey: Keys.isRegistered)
    }
    
    static func isRegistered() -> Bool {
        return userDefaults.bool(forKey: Keys.isRegistered)
    }
    
    // MARK: - Profile Sync
    static func setLastProfileSync(_ date: Date) {
        userDefaults.set(date, forKey: Keys.lastProfileSync)
    }
    
    static func getLastProfileSync() -> Date? {
        return userDefaults.object(forKey: Keys.lastProfileSync) as? Date
    }
    
    // MARK: - Forwarding Rules
    static func saveForwardingRules(_ rules: [ForwardingRule]) {
        if let encoded = try? JSONEncoder().encode(rules) {
            userDefaults.set(encoded, forKey: Keys.forwardingRules)
        }
    }
    
    static func getForwardingRules() -> [ForwardingRule] {
        guard let data = userDefaults.data(forKey: Keys.forwardingRules),
              let rules = try? JSONDecoder().decode([ForwardingRule].self, from: data) else {
            return []
        }
        return rules
    }
    
    static func deleteForwardingRules() {
        userDefaults.removeObject(forKey: Keys.forwardingRules)
    }
    
    // MARK: - Clear All Data
    static func clearAll() {
        userDefaults.removeObject(forKey: Keys.registrationId)
        userDefaults.removeObject(forKey: Keys.deviceName)
        userDefaults.removeObject(forKey: Keys.iosVersion)
        userDefaults.removeObject(forKey: Keys.appVersion)
        userDefaults.removeObject(forKey: Keys.isRegistered)
        userDefaults.removeObject(forKey: Keys.lastProfileSync)
        userDefaults.removeObject(forKey: Keys.forwardingRules)
    }
}
