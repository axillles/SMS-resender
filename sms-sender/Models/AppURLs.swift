//
//  AppURLs.swift
//  sms-sender
//
//  Ссылки на сайт AutoForward Text для настроек и Paywall.
//

import Foundation

enum AppURLs {
    private static let base = "https://www.autoforwardtext.com"

    static let website = URL(string: base)!
    static let privacyPolicy = URL(string: "\(base)/privacy-policy.php")!
    static let termsAndConditions = URL(string: "\(base)/terms-conditions.php")!
    static let contact = URL(string: "\(base)/contactus.php")!
    /// Support — страница поддержки (при необходимости заменить на отдельный путь)
    static let support = URL(string: "\(base)/contactus.php")!
}
