//
//  NetworkService.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    // MARK: - Generic Request Method
    private func performRequest<T: Codable, R: Codable>(
        url: URL,
        method: String = "POST",
        body: T?,
        responseType: R.Type
    ) async throws -> R {
        var request = Foundation.URLRequest(url: url)
        request.timeoutInterval = 60.0
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(responseType, from: data)
    }
    
    // MARK: - Registration
    func register(uuid: String, deviceDetails: DeviceDetails?) async throws -> RegistrationResponse {
        guard let url = APIConstants.registerURL else {
            throw NetworkError.invalidURL
        }
        
        let request = RegistrationRequest(uuid: uuid, details: deviceDetails)
        return try await performRequest(
            url: url,
            body: request,
            responseType: RegistrationResponse.self
        )
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case encodingError
    
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
        }
    }
}