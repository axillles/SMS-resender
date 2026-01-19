//
//  ForwardSMSIntent.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import AppIntents
import Foundation

/// App Intent для получения данных от Shortcuts через "Forward Shortcut input"
/// Shortcuts передает данные SMS сообщения через входной параметр
struct ForwardSMSIntent: AppIntent {
    static var title: LocalizedStringResource = "Forward SMS Message"
    static var description = IntentDescription("Forwards SMS message to server")
    static var openAppWhenRun: Bool = false // Работает в бекграунде
    
    // Входной параметр от Shortcuts "Forward Shortcut input"
    // Shortcuts передает данные как словарь или JSON строку
    @Parameter(title: "Shortcut Input", description: "SMS data from Shortcuts")
    var shortcutInput: String?
    
    func perform() async throws -> some IntentResult {
        // Парсим данные от Shortcuts
        guard let input = shortcutInput else {
            throw IntentError.missingInput
        }
        
        // Пытаемся распарсить как JSON
        if let jsonData = input.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            
            // Извлекаем данные из JSON
            let message = json["message"] as? String ?? json["text"] as? String ?? json["body"] as? String ?? ""
            let sender = json["sender"] as? String ?? json["from"] as? String ?? json["phoneNumber"] as? String ?? ""
            let timestampString = json["timestamp"] as? String ?? json["date"] as? String
            let subject = json["subject"] as? String
            
            guard !message.isEmpty, !sender.isEmpty else {
                throw IntentError.invalidInput
            }
            
            let timestamp = parseTimestamp(timestampString) ?? Date()
            
            await SMSForwardingService.shared.forwardSMS(
                message: message,
                sender: sender,
                timestamp: timestamp,
                subject: subject
            )
            
            return .result()
        }
        
        // Если это не JSON, возможно это просто текст сообщения
        // В этом случае пытаемся извлечь данные из других параметров
        // или используем дефолтные значения
        throw IntentError.invalidFormat
    }
    
    private func parseTimestamp(_ timestampString: String?) -> Date? {
        guard let timestampString = timestampString else { return nil }
        
        // Пробуем разные форматы
        let formatters = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss Z"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: timestampString) {
                return date
            }
        }
        
        return nil
    }
}

enum IntentError: Error, CustomStringConvertible {
    case missingInput
    case invalidInput
    case invalidFormat
    
    var description: String {
        switch self {
        case .missingInput:
            return "No input data received from Shortcuts"
        case .invalidInput:
            return "Invalid input data: missing message or sender"
        case .invalidFormat:
            return "Input data format is not supported"
        }
    }
}
