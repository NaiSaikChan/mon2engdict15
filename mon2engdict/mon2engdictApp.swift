//
//  mon2engdictApp.swift
//  mon2engdict
//
//  Created by Saik Chan on 18/9/24.
//

import SwiftUI
import GoogleMobileAds

@main
struct mon2engdictApp: App {
    @State private var currentLanguage = LanguageManager.shared.currentLanguage()
    
    init() {
        // Initialize SQLite database (copies bundle DB to Documents on first launch)
        _ = DatabaseManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                    currentLanguage = LanguageManager.shared.currentLanguage()
                }
                .onAppear {
                    // Defer AdMob SDK init until after the first frame renders.
                    // This prevents the heavy SDK setup from blocking app launch.
                    DispatchQueue.main.async {
                        GADMobileAds.sharedInstance().start { _ in
                            print("AdMob SDK initialized.")
                            NotificationCenter.default.post(name: .adMobSDKDidInitialize, object: nil)
                        }
                    }
                }
        }
    }
}

extension Notification.Name {
    static let adMobSDKDidInitialize = Notification.Name("adMobSDKDidInitialize")
}
