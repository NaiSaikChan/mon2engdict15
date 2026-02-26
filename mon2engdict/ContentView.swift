//
//  ContentView.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var languageViewModel = LanguageViewModel()
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    var body: some View {
        TabView {
            DictionaryView()
                .tabItem {
                    Label(
                        NSLocalizedString("Dictionary", comment: "To view dictionary."),
                        systemImage: "character.book.closed.fill"
                    )
                }
            
            FavoritesView()
                .tabItem {
                    Label(
                        NSLocalizedString("Favorite", comment: "To view the saved favorite word."),
                        systemImage: "heart.fill"
                    )
                }
            
            SettingsView(languageViewModel: languageViewModel)
                .tabItem {
                    Label(
                        NSLocalizedString("Setting", comment: "Setting View"),
                        systemImage: "gearshape.fill"
                    )
                }
        }
        .tint(.blue)
        .environmentObject(languageViewModel)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageViewModel.currentLanguage = LanguageManager.shared.currentLanguage()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
