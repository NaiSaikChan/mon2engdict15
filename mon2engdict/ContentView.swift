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
    @Environment(\.fontSize) var fontSize
    @StateObject var languageViewModel = LanguageViewModel()
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    var body: some View {
        TabView {
            DictionaryView()
                .tabItem{
                    VStack {
                        Image(systemName: "book")
                        Text(NSLocalizedString("Dictionary", comment: "To view dictionay."))
                            .font(.custom("Pyidaungsu", size: 16))
                    }
                }
            
            FavoritesView()
                .tabItem{
                    VStack {
                        Image(systemName: "heart.fill")
                        Text(NSLocalizedString("Favorite", comment: "To view the saved favorite word."))
                            .font(.custom("Pyidaungsu", size: 16))
                    }
                }
            
            
            SettingsView(languageViewModel: languageViewModel)
                .tabItem{
                    VStack {
                        Image(systemName: "gearshape")
                        Text(NSLocalizedString("Setting", comment: "Setting View"))
                            .font(.custom("Pyidaungsu", size: 16))
                    }
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
