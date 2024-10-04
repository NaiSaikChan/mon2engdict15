//
//  DictionaryView.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI
import CoreData
import GoogleMobileAds

struct DictionaryView: View {
    @State private var searchText = ""
    @State private var words: [MonDic] = []
    @State private var isLoading: Bool = true
    @State private var showingAddWord = false
    
    @AppStorage("sortMode") private var sortMode: SortMode = .az
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    @StateObject var languageViewModel = LanguageViewModel()
    @StateObject var adManager = InterstitialAdManager()
    
    @Environment(\.fontSize) var fontSize
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizonalSize
    @Environment(\.verticalSizeClass) private var verticalSize
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .foregroundColor(.gray)
                    }
                } else {
                    List(sortedWords, id: \.self) { item in
                        NavigationLink(destination: DetailView(dict: item)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(highlightText(for: item.word ?? "No word"))
                                    .font(.custom("Pyidaungsu", size: fontSizeDouble+4))
                                    .bold()
                                Text(highlightText(for: item.def ?? "No Definition"))
                                    .font(.custom("Pyidaungsu", size: fontSizeDouble))
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: {
                if horizonalSize == .compact && verticalSize == .regular {
                    return .navigationBarDrawer(displayMode: .always)
                } else {
                    return .navigationBarDrawer(displayMode: .always)
                }
            }(), prompt: NSLocalizedString("Search word", comment: "for searching words"))
            .onChange(of: searchText) { newValue in
                fetchFilteredData(query: newValue)
            }
            .onAppear {
                loadDataIfNeeded(context: viewContext)
                fetchInitialData()
                
                // Show interstitial ad when data is loaded
                if adManager.isAdReady {
                    if let rootViewController = getRootViewController() {
                        adManager.showAd(from: rootViewController)
                    }
                } else {
                    print("Ad wasn't ready")
                    //adManager.loadInterstitialAd()
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text((NSLocalizedString("MEM Dictionary", comment: "the dictionary navigation title.")))
                        .font(.custom("Pyidaungsu", size:fontSizeDouble))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddWord = true
                    }) {
                        Label(NSLocalizedString("Add Word", comment: "add word button"), systemImage: "plus.app.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddWordView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    /// Apply sorting based on the user's setting
    var sortedWords: [MonDic] {
        let caseInsensitiveSort: (MonDic, MonDic) -> Bool = { ($0.word ?? "").lowercased() < ($1.word ?? "").lowercased() }
        switch sortMode {
        case .az:
            return words.sorted(by: caseInsensitiveSort) // Case-insensitive A-Z sort
        case .za:
            return words.sorted(by: { ($0.word ?? "").lowercased() > ($1.word ?? "").lowercased() }) // Case-insensitive Z-A sort
        case .random:
            return words.shuffled()
        }
    }
    
    /// Fetch initial data when the view appears
    private func fetchInitialData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            fetchFilteredData(query: "")
            isLoading = false
        }
    }
    
    /// Fetch data asynchronously based on the search query
    private func fetchFilteredData(query: String) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchRequest: NSFetchRequest<MonDic> = MonDic.fetchRequest()
            
            /// Apply a predicate based on search text
            if !query.isEmpty {
                let regex = try! NSRegularExpression(pattern: "^[A-Za-z]")
                let range = NSRange(location: 0, length: query.utf16.count)
                let startsWithLetter = regex.firstMatch(in: query, options: [], range: range) != nil
                
                if startsWithLetter {
                    // If query starts with [A-Za-z]
                    let beginsWithPredicate = NSPredicate(format: "word BEGINSWITH[cd] %@", query)
                    let containsInDefPredicate = NSPredicate(format: "def CONTAINS[cd] %@", query)
                    let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [beginsWithPredicate, containsInDefPredicate])
                    fetchRequest.predicate = compoundPredicate
                } else {
                    // If query doesn't start with [A-Za-z]
                    let exactMatchPredicate = NSPredicate(format: "word ==[cd] %@", query)
                    let containsInDefPredicate = NSPredicate(format: "def ==[cd] %@", query)
                    let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [exactMatchPredicate, containsInDefPredicate])
                    fetchRequest.predicate = compoundPredicate
                }
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
    
    /// Helper function to get the root view controller in iOS 15+
    func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared
            .connectedScenes
            .first as? UIWindowScene else {
            return nil
        }
        
        return windowScene.windows.first?.rootViewController
    }
}

struct DictionaryView_Previews: PreviewProvider {
    static var previews: some View {
        DictionaryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
