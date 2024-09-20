//
//  SettingsView.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import SwiftUI

struct SettingsView: View {
    //@AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("appLanguage") private var appLanguage = "en"
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    @ObservedObject var languageViewModel: LanguageViewModel
    
    var fontSize: CGFloat {
        CGFloat(fontSizeDouble)
    }
    
    var body: some View {
        NavigationView {
            Form {
                ///Dark mode button
                Section(header: Text(NSLocalizedString("Appearance", comment: "Appearance section header"))) {
                    Picker("Theme", selection: $themeMode) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    //                Toggle(isOn: $isDarkMode) {
                    //                    Text(NSLocalizedString("Dark Mode", comment: "Switch to enable Dark Mode"))
                    //                }
                }
                .font(.custom("Pyidaungsu", size: 16))
                
                // Font Size Section
                Section(header: Text("Font Size")) {
                    Slider(value: $fontSizeDouble, in: 14...26, step: 1) {
                        Text("Font Size")
                    }
                    Text("Current Size: \(Int(fontSize))")
                }
                
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
                }.font(.custom("Pyidaungsu", size: 16))
                
                ///About app
                Section(header: Text(NSLocalizedString("About", comment: "About"))) {
                    Text(NSLocalizedString("Mon English Dictionary", comment: "About the App"))
                }.font(.custom("Pyidaungsu", size: 16))
            }
            //        .onChange(of: isDarkMode) { _ in
            //            // Change theme logic
            //            //UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            //            applyTheme()
            //        }
            .onAppear {
                applyTheme()
            }
            .toolbar{
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("Settings", comment: "setting title"))
                        .font(.custom("Pyidaungsu", size: 16))
                }
            }
        }
    }
    
    private func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        switch themeMode {
        case .light:
            keyWindow.overrideUserInterfaceStyle = .light
        case .dark:
            keyWindow.overrideUserInterfaceStyle = .dark
        case .system:
            keyWindow.overrideUserInterfaceStyle = .unspecified
        }
    }
}

// Enum for Theme Modes
enum ThemeMode: String, CaseIterable {
    case light
    case dark
    case system
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView(languageViewModel: languageViewModel)
//    }
//}
