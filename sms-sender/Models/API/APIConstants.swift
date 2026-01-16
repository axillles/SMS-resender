//
//  APIConstants.swift
//  sms-sender
//
//  Created by Артем Гавrilов on 10.01.26.
//

import Foundation

struct APIConstants {
    static let baseURL = "https://www.autoforwardtext.com/api"
    
    // MARK: - Endpoints
    static let register = "/aft_register.php"
    static let saveEmail = "/aft_saveemail.php"
    static let requestOTP = "/aft_reqotp.php"
    static let savePhone = "/aft_savenumber.php"
    static let deletePhone = "/aft_delnumber.php"
    static let saveURL = "/aft_saveurl.php"
    static let forward = "/aft_forward.php"
    static let testConnection = "/aft_test_connection.php"
    static let getProfile = "/aft_getprofile.php"
    
    // MARK: - Full URLs
    static var registerURL: URL? {
        return URL(string: baseURL + register)
    }
    
    static var saveEmailURL: URL? {
        return URL(string: baseURL + saveEmail)
    }
    
    static var requestOTPURL: URL? {
        return URL(string: baseURL + requestOTP)
    }
    
    static var savePhoneURL: URL? {
        return URL(string: baseURL + savePhone)
    }
    
    static var deletePhoneURL: URL? {
        return URL(string: baseURL + deletePhone)
    }
    
    static var saveURLURL: URL? {
        return URL(string: baseURL + saveURL)
    }
    
    static var forwardURL: URL? {
        return URL(string: baseURL + forward)
    }
    
    static var testConnectionURL: URL? {
        return URL(string: baseURL + testConnection)
    }
    
    static var getProfileURL: URL? {
        return URL(string: baseURL + getProfile)
    }
}
