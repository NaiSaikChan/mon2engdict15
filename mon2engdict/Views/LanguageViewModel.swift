//
//  LanguageViewModel.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import SwiftUI
import Combine

class LanguageViewModel: ObservableObject {
    @Published var currentLanguage: String

    init() {
        self.currentLanguage = LanguageManager.shared.currentLanguage()
    }

    func setLanguage(languageCode: String) {
        LanguageManager.shared.setLanguage(languageCode: languageCode)
        self.currentLanguage = languageCode
    }
}
