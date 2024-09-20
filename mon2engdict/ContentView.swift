//
//  ContentView.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject var languageViewModel = LanguageViewModel()
    
    
    var body: some View {
        TabView {
            
            DictionaryView()
                .tabItem{
                    Label(NSLocalizedString("Dictionary", comment: "To view dictionay."), systemImage: "book")
                        .font(.custom("Pyidaungsu", size: 16))
                }
            
            FavoritesView()
                .tabItem{
                    Label(NSLocalizedString("Favorite", comment: "To view the saved favorite word."), systemImage: "heart.fill")
                        .font(.custom("Pyidaungsu", size: 16))
                }
            
            
            SettingsView(languageViewModel: languageViewModel)
                .tabItem{
                    Label(NSLocalizedString("Setting", comment: "setting"), systemImage: "gearshape")
                        .font(.custom("Pyidaungsu", size: 16))
                }
        }
        .environmentObject(languageViewModel)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageViewModel.currentLanguage = LanguageManager.shared.currentLanguage()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
