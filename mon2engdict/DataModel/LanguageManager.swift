//
//  LanguageManager.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import Foundation

class LanguageManager {
    static let shared = LanguageManager()

    func setLanguage(languageCode: String) {
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Post notification to reload the app’s UI
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
    }

    func currentLanguage() -> String {
        let languages = UserDefaults.standard.object(forKey: "AppleLanguages") as? [String] ?? ["en"]
        return languages.first ?? "en"
    }
}

