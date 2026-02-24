//
//  Bundle+Extensions.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import Foundation

extension Bundle {
    private static var onLanguageDispatchOnce: () = {
        object_setClass(Bundle.main, BundleEx.self)
    }()
    
    @objc class BundleEx: Bundle, @unchecked Sendable {
        override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
            if let path = Bundle.main.path(forResource: LanguageManager.shared.currentLanguage(), ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle.localizedString(forKey: key, value: value, table: tableName)
            }
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
    }
    
    public static func setLanguage(_ language: String) {
        _ = Bundle.onLanguageDispatchOnce
        // Ensure the language bundle is loaded.
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}

