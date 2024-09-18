//
//  SettingsView.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("appLanguage") private var appLanguage = "en"
    
    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("Appearance", comment: "Appearance section header"))) {
                Toggle(isOn: $isDarkMode) {
                    Text(NSLocalizedString("Dark Mode", comment: "Switch to enable Dark Mode"))
                }
            }
            Section(header: Text(NSLocalizedString("Language", comment: "Language section header"))) {
                Picker(NSLocalizedString("App Language", comment: "Label for language picker"), selection: $appLanguage) {
                    Text(NSLocalizedString("English", comment: "English language")).tag("en")
                    Text(NSLocalizedString("Mon", comment: "Mon language")).tag("my-MM")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: appLanguage) { newValue in
                                    LanguageManager.shared.setLanguage(languageCode: newValue)
                                    // Optional: Trigger a UI refresh immediately
                                    exit(0) // This restarts the app to apply the language change
                                }
            }
            Section(header: Text(NSLocalizedString("About", comment: "About"))) {
                Text("Fruit and Vegetable App")
            }
        }
        .onChange(of: isDarkMode) { _ in
            // Change theme logic
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
