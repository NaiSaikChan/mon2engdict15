//
//  FavoritesView.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI
import CoreData

struct FavoritesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MonDic.word, ascending: true)],
        predicate: NSPredicate(format: "isFavorite == true"),
        animation: .default)
    private var dictionary: FetchedResults<MonDic>
    
    var body: some View {
        NavigationView {
            Group {
                if dictionary.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "heart.slash")
                            .font(.system(size: 52))
                            .foregroundStyle(.quaternary)
                        Text(NSLocalizedString("No favorites yet", comment: "Empty favorites state title"))
                            .font(.custom("Pyidaungsu", size: 17))
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(NSLocalizedString("Tap the heart icon on any word to save it here", comment: "Empty favorites hint"))
                            .font(.custom("Pyidaungsu", size: 14))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(dictionary) { item in
                            NavigationLink {
                                DetailView(dict: item)
                            } label: {
                                DictionaryRowView(
                                    word: item.word ?? "",
                                    definition: item.def ?? "",
                                    searchText: "",
                                    fontSize: fontSizeDouble,
                                    isFavorite: item.isFavorite
                                )
                            }
                        }
                        .onDelete(perform: unfavoriteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(NSLocalizedString("Favorites", comment: "Favorites navigation title"))
                            .font(.custom("Pyidaungsu", size: fontSizeDouble))
                            .fontWeight(.semibold)
                        if !dictionary.isEmpty {
                            Text("\(dictionary.count) " + NSLocalizedString("words", comment: "result count label"))
                                .font(.custom("Pyidaungsu", size: fontSizeDouble - 4))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Swipe to Unfavorite
    
    private func unfavoriteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = dictionary[index]
            item.isFavorite = false
        }
        do {
            try viewContext.save()
        } catch {
            print("Failed to unfavorite: \(error)")
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

