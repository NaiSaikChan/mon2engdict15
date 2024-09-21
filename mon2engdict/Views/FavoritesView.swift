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
    @Environment(\.fontSize) var fontSize
    
    ///Fatch Request for the favorite dic word
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MonDic.word, ascending: true)],
        predicate: NSPredicate(format: "isFavorite == true"),
        animation: .default)
    private var dictionary: FetchedResults<MonDic>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dictionary) { item in
                    VStack(alignment: .leading) {
                        Text(item.word ?? "")
                            .font(.custom("Pyidaungsu", size: fontSize+4))
                            .bold()
                        Text(item.def ?? "")
                            .font(.custom("Pyidaungsu", size: fontSize))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
            //.navigationTitle(NSLocalizedString("Favirotes Word", comment: "The word favirotes word."))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text((NSLocalizedString("Favirotes", comment: "the dictionary favirotes word.")))
                        .font(.custom("Pyidaungsu", size:fontSize+4))
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
