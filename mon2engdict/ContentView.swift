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
    
    ///Fatch Request for all dic word
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    //@State private var currentLanguage = LanguageManager.shared.currentLanguage()
    @StateObject var languageViewModel = LanguageViewModel()
    
    
    var body: some View {
        TabView {
            NavigationView {
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                        } label: {
                            Text(item.timestamp!, formatter: itemFormatter)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label(NSLocalizedString("Add Item", comment: "Add Item"), systemImage: "plus")
                                .font(.custom("Pyidaungsu", size: 14))
                        }
                    }
                }
                Text(NSLocalizedString(("Select an item"), comment: "Select item"))
                    .font(.custom("Pyidaungsu", size: 14))
            }
            .tabItem{
                Label(NSLocalizedString("Time", comment: "time show"), systemImage: "leaf")
                    .font(.custom("Pyidaungsu", size: 14))
            }
            
            DictionaryView()
                .tabItem{
                    Label(NSLocalizedString("Dictionary", comment: "To view dictionay."), systemImage: "book")
                        .font(.custom("Pyidaungsu", size: 14))
                }
            
            FavoritesView()
                .tabItem{
                    Label(NSLocalizedString("Favorite", comment: "To view the saved favorite word."), systemImage: "heart.fill")
                        .font(.custom("Pyidaungsu", size: 14))
                }
            
            
            SettingsView(languageViewModel: languageViewModel)
                .tabItem{
                    Label(NSLocalizedString("Setting", comment: "setting"), systemImage: "gearshape")
                        .font(.custom("Pyidaungsu", size: 14))
                }
        }
        .environmentObject(languageViewModel)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageViewModel.currentLanguage = LanguageManager.shared.currentLanguage()
                }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
