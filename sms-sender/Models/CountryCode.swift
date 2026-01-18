//
//  CountryCode.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 10.01.26.
//

import Foundation

struct CountryCode: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let country: String
    let flag: String
    
    var displayName: String {
        return "\(flag) \(code)"
    }
    
    var fullPhoneNumber: String {
        return code
    }
}

extension CountryCode {
    static let popularCodes: [CountryCode] = [
        CountryCode(code: "+1", country: "United States", flag: "🇺🇸"),
        CountryCode(code: "+44", country: "United Kingdom", flag: "🇬🇧"),
        CountryCode(code: "+33", country: "France", flag: "🇫🇷"),
        CountryCode(code: "+49", country: "Germany", flag: "🇩🇪"),
        CountryCode(code: "+39", country: "Italy", flag: "🇮🇹"),
        CountryCode(code: "+34", country: "Spain", flag: "🇪🇸"),
        CountryCode(code: "+7", country: "Russia", flag: "🇷🇺"),
        CountryCode(code: "+86", country: "China", flag: "🇨🇳"),
        CountryCode(code: "+81", country: "Japan", flag: "🇯🇵"),
        CountryCode(code: "+91", country: "India", flag: "🇮🇳"),
        CountryCode(code: "+61", country: "Australia", flag: "🇦🇺"),
        CountryCode(code: "+55", country: "Brazil", flag: "🇧🇷"),
        CountryCode(code: "+52", country: "Mexico", flag: "🇲🇽"),
        CountryCode(code: "+1", country: "Canada", flag: "🇨🇦"),
    ]
    
    static let allCodes: [CountryCode] = [
        CountryCode(code: "+1", country: "United States", flag: "🇺🇸"),
        CountryCode(code: "+1", country: "Canada", flag: "🇨🇦"),
        CountryCode(code: "+44", country: "United Kingdom", flag: "🇬🇧"),
        CountryCode(code: "+33", country: "France", flag: "🇫🇷"),
        CountryCode(code: "+49", country: "Germany", flag: "🇩🇪"),
        CountryCode(code: "+39", country: "Italy", flag: "🇮🇹"),
        CountryCode(code: "+34", country: "Spain", flag: "🇪🇸"),
        CountryCode(code: "+7", country: "Russia", flag: "🇷🇺"),
        CountryCode(code: "+86", country: "China", flag: "🇨🇳"),
        CountryCode(code: "+81", country: "Japan", flag: "🇯🇵"),
        CountryCode(code: "+91", country: "India", flag: "🇮🇳"),
        CountryCode(code: "+61", country: "Australia", flag: "🇦🇺"),
        CountryCode(code: "+55", country: "Brazil", flag: "🇧🇷"),
        CountryCode(code: "+52", country: "Mexico", flag: "🇲🇽"),
        CountryCode(code: "+31", country: "Netherlands", flag: "🇳🇱"),
        CountryCode(code: "+32", country: "Belgium", flag: "🇧🇪"),
        CountryCode(code: "+41", country: "Switzerland", flag: "🇨🇭"),
        CountryCode(code: "+46", country: "Sweden", flag: "🇸🇪"),
        CountryCode(code: "+47", country: "Norway", flag: "🇳🇴"),
        CountryCode(code: "+45", country: "Denmark", flag: "🇩🇰"),
        CountryCode(code: "+358", country: "Finland", flag: "🇫🇮"),
        CountryCode(code: "+351", country: "Portugal", flag: "🇵🇹"),
        CountryCode(code: "+353", country: "Ireland", flag: "🇮🇪"),
        CountryCode(code: "+48", country: "Poland", flag: "🇵🇱"),
        CountryCode(code: "+352", country: "Luxembourg", flag: "🇱🇺"),
        CountryCode(code: "+356", country: "Malta", flag: "🇲🇹"),
        CountryCode(code: "+357", country: "Cyprus", flag: "🇨🇾"),
        CountryCode(code: "+359", country: "Bulgaria", flag: "🇧🇬"),
        CountryCode(code: "+385", country: "Croatia", flag: "🇭🇷"),
        CountryCode(code: "+387", country: "Bosnia and Herzegovina", flag: "🇧🇦"),
        CountryCode(code: "+386", country: "Slovenia", flag: "🇸🇮"),
        CountryCode(code: "+381", country: "Serbia", flag: "🇷🇸"),
        CountryCode(code: "+380", country: "Ukraine", flag: "🇺🇦"),
        CountryCode(code: "+371", country: "Latvia", flag: "🇱🇻"),
        CountryCode(code: "+372", country: "Estonia", flag: "🇪🇪"),
        CountryCode(code: "+373", country: "Moldova", flag: "🇲🇩"),
        CountryCode(code: "+375", country: "Belarus", flag: "🇧🇾"),
        CountryCode(code: "+376", country: "Andorra", flag: "🇦🇩"),
        CountryCode(code: "+377", country: "Monaco", flag: "🇲🇨"),
        CountryCode(code: "+378", country: "San Marino", flag: "🇸🇲"),
        CountryCode(code: "+379", country: "Vatican City", flag: "🇻🇦"),
        CountryCode(code: "+382", country: "Montenegro", flag: "🇲🇪"),
        CountryCode(code: "+383", country: "Kosovo", flag: "🇽🇰"),
        CountryCode(code: "+384", country: "Côte d'Ivoire", flag: "🇨🇮"),
        CountryCode(code: "+388", country: "North Macedonia", flag: "🇲🇰"),
        CountryCode(code: "+421", country: "Slovakia", flag: "🇸🇰"),
        CountryCode(code: "+423", country: "Liechtenstein", flag: "🇱🇮"),
        CountryCode(code: "+425", country: "Estonia", flag: "🇪🇪"),
        CountryCode(code: "+426", country: "Latvia", flag: "🇱🇻"),
        CountryCode(code: "+427", country: "Lithuania", flag: "🇱🇹"),
        CountryCode(code: "+428", country: "Andorra", flag: "🇦🇩"),
        CountryCode(code: "+429", country: "Monaco", flag: "🇲🇨"),
        CountryCode(code: "+43", country: "Austria", flag: "🇦🇹"),
        CountryCode(code: "+36", country: "Hungary", flag: "🇭🇺"),
        CountryCode(code: "+420", country: "Czech Republic", flag: "🇨🇿"),
        CountryCode(code: "+36", country: "Hungary", flag: "🇭🇺"),
        CountryCode(code: "+40", country: "Romania", flag: "🇷🇴"),
        CountryCode(code: "+380", country: "Ukraine", flag: "🇺🇦"),
        CountryCode(code: "+90", country: "Turkey", flag: "🇹🇷"),
        CountryCode(code: "+82", country: "South Korea", flag: "🇰🇷"),
        CountryCode(code: "+65", country: "Singapore", flag: "🇸🇬"),
        CountryCode(code: "+852", country: "Hong Kong", flag: "🇭🇰"),
        CountryCode(code: "+886", country: "Taiwan", flag: "🇹🇼"),
        CountryCode(code: "+971", country: "UAE", flag: "🇦🇪"),
        CountryCode(code: "+966", country: "Saudi Arabia", flag: "🇸🇦"),
        CountryCode(code: "+972", country: "Israel", flag: "🇮🇱"),
        CountryCode(code: "+27", country: "South Africa", flag: "🇿🇦"),
        CountryCode(code: "+20", country: "Egypt", flag: "🇪🇬"),
        CountryCode(code: "+234", country: "Nigeria", flag: "🇳🇬"),
        CountryCode(code: "+54", country: "Argentina", flag: "🇦🇷"),
        CountryCode(code: "+56", country: "Chile", flag: "🇨🇱"),
        CountryCode(code: "+57", country: "Colombia", flag: "🇨🇴"),

    ]
}
