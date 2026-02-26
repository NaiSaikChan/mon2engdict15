//
//  FavoritesView.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI

struct FavoritesView: View {
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    @State private var favorites: [DictionaryEntry] = []
    
    private let dbManager = DatabaseManager.shared
    
    var body: some View {
        NavigationView {
            Group {
                if favorites.isEmpty {
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
                        ForEach(favorites) { item in
                            NavigationLink {
                                DetailView(entry: item)
                            } label: {
                                DictionaryRowView(
                                    word: item.word,
                                    definition: item.definition,
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
                        if !favorites.isEmpty {
                            Text("\(favorites.count) " + NSLocalizedString("words", comment: "result count label"))
                                .font(.custom("Pyidaungsu", size: fontSizeDouble - 4))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await loadFavorites()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Data
    
    @MainActor
    private func loadFavorites() async {
        favorites = await dbManager.fetchFavoritesAsync()
    }
    
    private func unfavoriteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = favorites[index]
            dbManager.setFavorite(id: item.id, value: false)
        }
        favorites.remove(atOffsets: offsets)
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
