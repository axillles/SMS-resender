//
//  APIResponse.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

// MARK: - Base API Response
struct APIResponse<T: Codable>: Codable {
    let status: String
    let message: String?
    let data: T?
    
    var isSuccess: Bool {
        return status == "success"
    }
}

// MARK: - Simple API Response (without data)
struct SimpleAPIResponse: Codable {
    let status: String
    let message: String?
    
    var isSuccess: Bool {
        return status == "success"
    }
}

// MARK: - API Error
struct APIError: Codable, Error {
    let status: String
    let message: String
    
    var localizedDescription: String {
        return message
    }
}
