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
    @State private var words: [MonDic] = []
    @State private var isLoading: Bool = false
    @State private var showingAddWord = false
    @StateObject var languageViewModel = LanguageViewModel()
    
    @Environment(\.fontSize) var fontSize
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizonalSize
    @Environment(\.verticalSizeClass) private var verticalSize
    
    var body: some View {
        NavigationView {
            List(words, id: \.self) { item in
                NavigationLink(destination: DetailView(dict: item)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(highlightText(for: item.word ?? ""))
                            .font(.custom("Pyidaungsu", size: fontSize+4))
                            .bold()
                        Text(highlightText(for: item.def ?? ""))
                            .font(.custom("Pyidaungsu", size: fontSize))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 5)
                }
            }
            .searchable(text: $searchText, placement: {
                if horizonalSize == .compact && verticalSize == .regular {
                    return .navigationBarDrawer(displayMode: .always)
                } else {
                    return .navigationBarDrawer(displayMode: .automatic)
                }
            }(), prompt: NSLocalizedString("Search word", comment: "for searching words"))
            .onChange(of: searchText) { newValue in
                fetchFilteredData(query: newValue)
            }
            .onAppear {
                loadDataIfNeeded(context: viewContext)
                fetchInitialData()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text((NSLocalizedString("MEM Dictionary", comment: "the dictionary navigation title.")))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddWord = true
                    }) {
                        Label(NSLocalizedString("Add Word", comment: "add word button"), systemImage: "plus.app.fill")
                    }
                }
            }.font(.custom("Pyidaungsu", size:fontSize+4))
            .sheet(isPresented: $showingAddWord) {
                AddWordView()
            }
        }
    }
    
    /// Fetch initial data when the view appears
    private func fetchInitialData() {
        fetchFilteredData(query: "")
    }
    
    /// Fetch data asynchronously based on the search query
    private func fetchFilteredData(query: String) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchRequest: NSFetchRequest<MonDic> = MonDic.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MonDic.word, ascending: true)]
            
            /// Apply a predicate if the search query is not empty
            if !query.isEmpty {
                fetchRequest.predicate = NSPredicate(format: "word BEGINSWITH[cd] %@", query)
            }
            
            do {
                let results = try viewContext.fetch(fetchRequest)
                
                /// Update the UI on the main thread
                DispatchQueue.main.async {
                    self.words = results
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch data: \(error)")
                
                DispatchQueue.main.async {
                    self.words = []
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Highlight search text in the displayed result
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
