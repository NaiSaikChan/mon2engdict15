//
//  DictionaryView.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI
import CoreData

struct DictionaryView: View {
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var isNavBarHidden = false
    @State private var showingAddWord = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizonalSize
    @Environment(\.verticalSizeClass) private var verticalSize
    
    ///Fetch Request to get words from CoreDate
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MonDic.word, ascending: true)],
        animation: .default)
    private var dictionary: FetchedResults<MonDic>
    
    var body: some View {
        NavigationView {
            List(dictionary) { item in
                NavigationLink(destination: DetailView(dict: item)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(highlightText(for: item.word ?? ""))
                            .font(.custom("Mon3Anont1", size: 20))
                            .bold()
                        Text(highlightText(for: item.def ?? ""))
                            .font(.custom("Pyidaungsu", size: 16))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle(NSLocalizedString("MEM Dictionary", comment: "navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: {
                if horizonalSize == .compact && verticalSize == .regular {
                    return .navigationBarDrawer(displayMode: .always)
                } else {
                    return .navigationBarDrawer(displayMode: .automatic)
                }
            }(), prompt: NSLocalizedString("Search word", comment: "for searching words")
            )
            .onChange(of: searchText) { newValue in
                updateFetchRequest(for: newValue)
            }
            .onAppear{
                // check and load data if need
                loadDataIfNeeded(context: viewContext)
            }
        }
    }
    
    ///Functions
    ///Update the FetchRequest's predicate base on the search text
    private func updateFetchRequest(for query: String) {
        if query.isEmpty {
            dictionary.nsPredicate = nil
        } else {
            dictionary.nsPredicate = NSPredicate(format: "word BEGINSWITH[cd] %@", query)
        }
    }
    
    ///HighLight the search text
    private func highlightText(for text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if let range = attributedString.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) {
            attributedString[range].foregroundColor = .blue
            attributedString[range].font = .bold(.body)()
        }
        return attributedString
    }
}

struct DictionaryView_Previews: PreviewProvider {
    static var previews: some View {
        DictionaryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
