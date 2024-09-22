//
//  SettingsView.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("sortMode") private var sortMode: SortMode = .az
    @AppStorage("appLanguage") private var appLanguage = "en"
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    @AppStorage("useDefaultFontSize") private var useDefaultFontSize: Bool = true
    
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
                            Text(mode.displayName).tag(mode).font(.custom("Pyidaungsu", size: fontSize))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .font(.custom("Pyidaungsu", size: fontSize))
                
                /// Sorting Option
                Section(header: Text(NSLocalizedString("Sort Order", comment: "for sorting"))) {
                    Picker("Sort", selection: $sortMode) {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Text(mode.disName).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }.font(.custom("Pyidaungsu", size: fontSize))
                
                /// Font Size Section
                Section(header: Text(NSLocalizedString("Font Size", comment: "fon size header"))) {
                    /// Toggle to use default font size
                    Toggle(isOn: $useDefaultFontSize) {
                        Text(NSLocalizedString("Use Default", comment: "use default size"))
                    }
                    /// Conditionally enable the slider based on the toggle
                    if !useDefaultFontSize {
                        Slider(value: $fontSizeDouble, in: 14...26, step: 1) {
                            Text(NSLocalizedString("Font Size", comment: "fon size header"))
                                .font(.custom("Pyidaungsu", size: fontSize))
                        }
                        Text(NSLocalizedString("Current Size", comment: "change the font size")+": \(Int(fontSize))")
                            .font(.custom("Pyidaungsu", size: fontSize))
                    }
                }.font(.custom("Pyidaungsu", size: fontSize))
                
                ///Language switch
                Section(header: Text(NSLocalizedString("Language", comment: "Language section header"))) {
                    Picker(NSLocalizedString("App Language", comment: "Language Picker label"), selection: $appLanguage) {
                        Text(NSLocalizedString("English", comment: "English language")).tag("en")
                            .font(.custom("Pyidaungsu", size: fontSize))
                        Text(NSLocalizedString("Mon", comment: "Mon language")).tag("my-MM")
                            .font(.custom("Pyidaungsu", size: fontSize))
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: appLanguage) { newValue in
                        languageViewModel.setLanguage(languageCode: newValue)
                    }
                }.font(.custom("Pyidaungsu", size: fontSize))
                
                ///About app
                Section(header: Text(NSLocalizedString("About", comment: "About"))) {
                    Text(NSLocalizedString("About App", comment: "About the App"))
                }.font(.custom("Pyidaungsu", size: fontSize))
            }
            .onChange(of: themeMode) { _ in
                applyTheme()
            }
            .onChange(of: useDefaultFontSize) { newValue in
                if newValue {
                    fontSizeDouble = 16 // Reset to default when toggle is on
                }
            }
            .onAppear {
                applyTheme()
            }
            .environment(\.fontSize, fontSize)
            .toolbar{
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("Settings", comment: "setting title"))
                        .font(.custom("Pyidaungsu", size: fontSize))
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
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

struct FontSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 16 // Default font size
}

extension EnvironmentValues {
    var fontSize: CGFloat {
        get { self[FontSizeKey.self] }
        set { self[FontSizeKey.self] = newValue }
    }
}

/// Enum for Theme Modes
enum ThemeMode: String, CaseIterable {
    case light
    case dark
    case system
    
    var displayName: String {
        switch self {
        case .light: return NSLocalizedString("Light", comment: "light mode")
        case .dark: return NSLocalizedString("Dark", comment: "dark mode")
        case .system: return NSLocalizedString("System", comment: "system auto mode")
        }
    }
}

/// Sort the word
enum SortMode: String, CaseIterable {
    case az
    case za
    case random
    
    var disName: String {
        switch self {
        case .az: return NSLocalizedString("A-Z", comment: "a to z")
        case .za: return NSLocalizedString("Z-A", comment: "z to a")
        case .random: return NSLocalizedString("Random", comment: "random")
        }
    }
}
