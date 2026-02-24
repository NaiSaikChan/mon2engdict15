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
                // MARK: - Appearance
                Section(header: Text(NSLocalizedString("Appearance", comment: "Appearance section header"))
                    .font(.custom("Pyidaungsu", size: fontSize))) {
                    // Theme picker
                    HStack {
                        Label {
                            Text(NSLocalizedString("Appearance", comment: "Appearance label"))
                                .font(.custom("Pyidaungsu", size: fontSize))
                        } icon: {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundColor(.purple)
                        }
                    }
                    
                    Picker("", selection: $themeMode) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                                .font(.custom("Pyidaungsu", size: fontSize))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // MARK: - Sort Order
                Section(header: Text(NSLocalizedString("Sort Order", comment: "Sort Order section header"))
                    .font(.custom("Pyidaungsu", size: fontSize))) {
                    HStack {
                        Label {
                            Text(NSLocalizedString("Sort Order", comment: "for sorting"))
                                .font(.custom("Pyidaungsu", size: fontSize))
                        } icon: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Picker("", selection: $sortMode) {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Text(mode.disName).tag(mode)
                                .font(.custom("Pyidaungsu", size: fontSize))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // MARK: - Font Size
                Section(header: Text(NSLocalizedString("Font Size", comment: "font size header"))
                    .font(.custom("Pyidaungsu", size: fontSize))) {
                    Toggle(isOn: $useDefaultFontSize) {
                        Label {
                            Text(NSLocalizedString("Use Default", comment: "use default size"))
                                .font(.custom("Pyidaungsu", size: fontSize))
                        } icon: {
                            Image(systemName: "textformat.size")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if !useDefaultFontSize {
                        VStack(alignment: .leading, spacing: 8) {
                            Slider(value: $fontSizeDouble, in: 14...26, step: 1)
                                .tint(.orange)
                            
                            HStack {
                                Text("A")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(NSLocalizedString("Current Size", comment: "change the font size") + ": \(Int(fontSize))")
                                    .font(.custom("Pyidaungsu", size: 13))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("A")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Live preview
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Preview", comment: "Font preview label"))
                                .font(.custom("Pyidaungsu", size: 13))
                                .foregroundStyle(.tertiary)
                            Text("Hello - မ္ၚဵုရအဴ")
                                .font(.custom("Pyidaungsu", size: fontSize))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                
                // MARK: - Language
                Section(header: Text(NSLocalizedString("Language", comment: "Language section header"))
                    .font(.custom("Pyidaungsu", size: fontSize))) {
                    HStack {
                        Label {
                            Text(NSLocalizedString("App Language", comment: "Language Picker label"))
                                .font(.custom("Pyidaungsu", size: fontSize))
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Picker("", selection: $appLanguage) {
                        Text(NSLocalizedString("English", comment: "English language")).font(.custom("Pyidaungsu", size: fontSize)).tag("en")
                        Text(NSLocalizedString("Mon", comment: "Mon language")).font(.custom("Pyidaungsu", size: fontSize)).tag("my-MM")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: appLanguage) { newValue in
                        languageViewModel.setLanguage(languageCode: newValue)
                    }
                }
                
                // MARK: - About
                Section(header: Text(NSLocalizedString("About", comment: "About"))
                    .font(.custom("Pyidaungsu", size: fontSize))) {
                    // Credit
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text(NSLocalizedString("About", comment: "About"))
                                .font(.custom("Pyidaungsu", size: fontSize))
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.teal)
                        }
                        
                        Text(NSLocalizedString("About App", comment: "About the App"))
                            .font(.custom("Pyidaungsu", size: fontSize - 2))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 4)
                    
                    // App version
                    HStack {
                        Label {
                            Text(NSLocalizedString("Version", comment: "App version label"))
                                .font(.custom("Pyidaungsu", size: fontSize))
                        } icon: {
                            Image(systemName: "app.badge")
                                .foregroundColor(.indigo)
                        }
                        
                        Spacer()
                        
                        Text(appVersion)
                            .font(.custom("Pyidaungsu", size: fontSize - 1))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: themeMode) { _ in
                applyTheme()
            }
            .onChange(of: useDefaultFontSize) { newValue in
                if newValue {
                    fontSizeDouble = 16
                }
            }
            .onAppear {
                applyTheme()
            }
            .environment(\.fontSize, fontSize)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("Settings", comment: "setting title"))
                        .font(.custom("Pyidaungsu", size: fontSize))
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Helpers
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
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

// MARK: - Environment Key & Enums

struct FontSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 16
}

extension EnvironmentValues {
    var fontSize: CGFloat {
        get { self[FontSizeKey.self] }
        set { self[FontSizeKey.self] = newValue }
    }
}

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
