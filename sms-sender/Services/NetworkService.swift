//
//  NetworkService.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation
import os.log

class NetworkService {
    static let shared = NetworkService()
    private let logger = Logger(subsystem: "com.sms-sender", category: "NetworkService")
    
    private init() {}
    
    // MARK: - Generic Request Method
    private func performRequest<T: Codable, R: Codable>(
        url: URL,
        method: String = "POST",
        body: T?,
        responseType: R.Type
    ) async throws -> R {
        logger.info("🌐 Starting request to: \(url.absoluteString)")
        
        var request = Foundation.URLRequest(url: url)
        request.timeoutInterval = 60.0
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            let encoder = JSONEncoder()
            do {
                request.httpBody = try encoder.encode(body)
                if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                    logger.debug("📤 Request body: \(jsonString)")
                }
            } catch {
                logger.error("❌ Failed to encode request body: \(error.localizedDescription)")
                throw NetworkError.encodingError
            }
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            logger.error("❌ Network error: \(error.localizedDescription)")
            throw NetworkError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ Invalid response type")
            throw NetworkError.invalidResponse
        }
        
        logger.info("📥 Response status code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("❌ HTTP error with status: \(httpResponse.statusCode)")
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            logger.debug("📥 Response body: \(responseString)")
        }
        
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(responseType, from: data)
            logger.info("✅ Successfully decoded response")
            return decoded
        } catch {
            logger.error("❌ Failed to decode response: \(error.localizedDescription)")
            throw NetworkError.decodingError
        }
    }
    
    // MARK: - Registration
    func register(uuid: String, deviceDetails: DeviceDetails?) async throws -> RegistrationResponse {
        logger.info("📝 Starting registration for UUID: \(uuid)")
        guard let url = APIConstants.registerURL else {
            logger.error("❌ Invalid registration URL")
            throw NetworkError.invalidURL
        }
        
        let request = RegistrationRequest(uuid: uuid, details: deviceDetails)
        let response = try await performRequest(
            url: url,
            body: request,
            responseType: RegistrationResponse.self
        )
        
        if response.isSuccess, let registrationId = response.registrationId {
            logger.info("✅ Registration successful. Registration ID: \(registrationId)")
        } else {
            logger.error("❌ Registration failed: \(response.message ?? "Unknown error")")
            throw NetworkError.apiError(message: response.message ?? "Registration failed")
        }
        
        return response
    }
    
    // MARK: - Save Email
    func saveEmail(registrationId: String, emailAddress: String, delete: Bool = false) async throws -> EmailResponse {
        logger.info("📧 Saving email: \(emailAddress), delete: \(delete)")
        guard let url = APIConstants.saveEmailURL else {
            logger.error("❌ Invalid save email URL")
            throw NetworkError.invalidURL
        }
        
        let request = EmailRequest(
            registrationId: registrationId,
            emailAddress: emailAddress,
            delete: delete
        )
        
        let response = try await performRequest(
            url: url,
            body: request,
            responseType: EmailResponse.self
        )
        
        if response.isSuccess {
            logger.info("✅ Email saved successfully: \(response.message)")
        } else {
            logger.error("❌ Failed to save email: \(response.message)")
            throw NetworkError.apiError(message: response.message)
        }
        
        return response
    }
    
    // MARK: - Test Connection
    func testConnection(registrationId: String, type: String, target: String, message: String) async throws -> TestConnectionResponse {
        logger.info("🧪 Testing connection: type=\(type), target=\(target)")
        guard let url = APIConstants.testConnectionURL else {
            logger.error("❌ Invalid test connection URL")
            throw NetworkError.invalidURL
        }
        
        let request = TestConnectionRequest(
            registrationId: registrationId,
            type: type,
            target: target,
            message: message
        )
        
        let response = try await performRequest(
            url: url,
            body: request,
            responseType: TestConnectionResponse.self
        )
        
        if response.isSuccess {
            logger.info("✅ Test connection successful")
        } else {
            logger.error("❌ Test connection failed")
            throw NetworkError.apiError(message: "Test connection failed")
        }
        
        return response
    }
    
    // MARK: - Request OTP
    func requestOTP(registrationId: String, phoneNumber: String) async throws -> PhoneResponse {
        logger.info("📱 Requesting OTP for phone: \(phoneNumber)")
        guard let url = APIConstants.requestOTPURL else {
            logger.error("❌ Invalid request OTP URL")
            throw NetworkError.invalidURL
        }
        
        logger.info("🔗 Full OTP URL: \(url.absoluteString)")
        logger.info("🔗 Base URL: \(APIConstants.baseURL)")
        logger.info("🔗 Endpoint: \(APIConstants.requestOTP)")
        
        let request = PhoneOTPRequest(
            registrationId: registrationId,
            phoneNumber: phoneNumber
        )
        
        let response = try await performRequest(
            url: url,
            body: request,
            responseType: PhoneResponse.self
        )
        
        if response.isSuccess {
            logger.info("✅ OTP sent successfully: \(response.message)")
        } else {
            logger.error("❌ Failed to send OTP: \(response.message)")
            throw NetworkError.apiError(message: response.message)
        }
        
        return response
    }
    
    // MARK: - Save Phone Number
    func savePhone(registrationId: String, phoneNumber: String, otpCode: String) async throws -> PhoneResponse {
        logger.info("📱 Saving phone: \(phoneNumber) with OTP")
        guard let url = APIConstants.savePhoneURL else {
            logger.error("❌ Invalid save phone URL")
            throw NetworkError.invalidURL
        }
        
        let request = PhoneSaveRequest(
            registrationId: registrationId,
            phoneNumber: phoneNumber,
            otpCode: otpCode
        )
        
        let response = try await performRequest(
            url: url,
            body: request,
            responseType: PhoneResponse.self
        )
        
        if response.isSuccess {
            logger.info("✅ Phone saved successfully: \(response.message)")
        } else {
            logger.error("❌ Failed to save phone: \(response.message)")
            throw NetworkError.apiError(message: response.message)
        }
        
        return response
    }
    
    // MARK: - Delete Phone Number
    func deletePhone(registrationId: String, phoneNumber: String) async throws -> PhoneResponse {
        logger.info("📱 Deleting phone: \(phoneNumber)")
        guard let url = APIConstants.deletePhoneURL else {
            logger.error("❌ Invalid delete phone URL")
            throw NetworkError.invalidURL
        }
        
        let request = PhoneDeleteRequest(
            registrationId: registrationId,
            phoneNumber: phoneNumber
        )
        
        let response = try await performRequest(
            url: url,
            body: request,
            responseType: PhoneResponse.self
        )
        
        if response.isSuccess {
            logger.info("✅ Phone deleted successfully: \(response.message)")
        } else {
            logger.error("❌ Failed to delete phone: \(response.message)")
            throw NetworkError.apiError(message: response.message)
        }
        
        return response
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case encodingError
    case networkError(Error)
    case apiError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return message
        }
    }
}