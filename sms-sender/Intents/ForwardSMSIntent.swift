//
//  ForwardSMSIntent.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import AppIntents
import Foundation
import os.log

private let forwardIntentLogger = Logger(subsystem: "com.sms-sender", category: "ForwardSMSIntent")

/// Принимает две строки от Shortcuts: текст сообщения и отправитель. Передаёт на бекенд без парсинга.
struct ForwardSMSIntent: AppIntent {
    static var title: LocalizedStringResource = "Forward SMS Message"
    static var description = IntentDescription("Forwards SMS message to server")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Message Text", description: "Content of the SMS (string)")
    var messageText: String

    @Parameter(title: "Sender", description: "Sender phone number or name (string)")
    var sender: String?

    func perform() async throws -> some IntentResult {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let senderString = (sender?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "Unknown"

        guard !message.isEmpty else {
            forwardIntentLogger.error("❌ IntentError 0 (missingInput): Message Text is empty.")
            throw IntentError.missingInput
        }

        await SMSForwardingService.shared.forwardSMS(
            message: message,
            sender: senderString,
            timestamp: Date(),
            subject: nil
        )

        return .result()
    }
}

enum IntentError: Error, CustomStringConvertible, LocalizedError {
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

    var errorDescription: String? {
        switch self {
        case .missingInput:
            return "Message not passed to app"
        case .invalidInput:
            return "Message or sender is missing"
        case .invalidFormat:
            return "Message format not supported"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingInput:
            return "Add action \"Get Contents of Message\" and pass its result to \"Message Text\"."
        case .invalidInput, .invalidFormat:
            return nil
        }
    }
}
