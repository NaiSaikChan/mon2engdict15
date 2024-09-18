//
//  LanguageManager.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import Foundation


///Language Manager
class LanguageManager {
    static let shared = LanguageManager()

    func setLanguage(languageCode: String) {
        Bundle.setLanguage(languageCode)
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
    }

    func currentLanguage() -> String {
        let languages = UserDefaults.standard.object(forKey: "AppleLanguages") as? [String] ?? ["en"]
        return languages.first ?? "en"
    }
}

