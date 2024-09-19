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
    
    @ObservedObject var languageViewModel: LanguageViewModel
    
    var body: some View {
        Form {
            ///Dark mode button
            Section(header: Text(NSLocalizedString("Appearance", comment: "Appearance section header"))) {
                Toggle(isOn: $isDarkMode) {
                    Text(NSLocalizedString("Dark Mode", comment: "Switch to enable Dark Mode"))
                }
            }
            .font(.custom("Pyidaungsu", size: 14))
            
            ///Language switch
            Section(header: Text(NSLocalizedString("Language", comment: "Language section header"))) {
                Picker(NSLocalizedString("App Language", comment: "Language Picker label"), selection: $appLanguage) {
                    Text(NSLocalizedString("English", comment: "English language")).tag("en")
                    Text(NSLocalizedString("Mon", comment: "Mon language")).tag("my-MM")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: appLanguage) { newValue in
                    languageViewModel.setLanguage(languageCode: newValue)
                }
            }.font(.custom("Pyidaungsu", size: 14))
            
            ///About app
            Section(header: Text(NSLocalizedString("About", comment: "About"))) {
                Text("Fruit and Vegetable App")
            }.font(.custom("Pyidaungsu", size: 14))
        }
        .onChange(of: isDarkMode) { _ in
            // Change theme logic
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView(languageViewModel: languageViewModel)
//    }
//}
