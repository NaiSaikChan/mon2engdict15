//
//  mon2engdictApp.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import SwiftUI

@main
struct mon2engdictApp: App {
    @State private var currentLanguage = LanguageManager.shared.currentLanguage()
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    NotificationCenter.default.addObserver(forName: NSNotification.Name("LanguageChanged"), object: nil, queue: .main) { _ in
                        currentLanguage = LanguageManager.shared.currentLanguage()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                    currentLanguage = LanguageManager.shared.currentLanguage()
                }
        }
    }
}
