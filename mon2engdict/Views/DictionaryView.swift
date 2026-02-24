//
//  DictionaryView.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI
import CoreData

// MARK: - Extracted Row View
/// Separate struct so SwiftUI can skip re-rendering rows whose data hasn't changed.
/// Using Equatable conformance lets SwiftUI short-circuit its diff for unchanged rows.
struct DictionaryRowView: View, Equatable {
    let word: String
    let definition: String
    let searchText: String
    let fontSize: Double
    
    static func == (lhs: DictionaryRowView, rhs: DictionaryRowView) -> Bool {
        lhs.word == rhs.word &&
        lhs.definition == rhs.definition &&
        lhs.searchText == rhs.searchText &&
        lhs.fontSize == rhs.fontSize
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if searchText.isEmpty {
                // Fast path: plain Text — no AttributedString allocation
                Text(word)
                    .font(.custom("Pyidaungsu", size: fontSize + 4))
                    .bold()
                Text(definition)
                    .font(.custom("Pyidaungsu", size: fontSize))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            } else {
                // Slow path: only used when user is actively searching
                Text(highlightText(for: word))
                    .font(.custom("Pyidaungsu", size: fontSize + 4))
                    .bold()
                Text(highlightText(for: definition))
                    .font(.custom("Pyidaungsu", size: fontSize))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 5)
    }
    
    private func highlightText(for text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        if let range = attributedString.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) {
            attributedString[range].foregroundColor = .blue
            attributedString[range].font = .bold(.body)()
        }
        return attributedString
    }
}

// MARK: - Dictionary View

struct DictionaryView: View {
    @State private var searchText = ""
    @State private var words: [MonDic] = []
    @State private var isLoading: Bool = true
    @State private var showingAddWord = false
    @State private var hasLoadedInitialData = false
    
    /// Debounce: cancel the previous search task when a new keystroke arrives
    @State private var searchTask: DispatchWorkItem?
    
    @AppStorage("sortMode") private var sortMode: SortMode = .az
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    @EnvironmentObject var languageViewModel: LanguageViewModel
    @StateObject var adManager = InterstitialAdManager()
    
    @Environment(\.fontSize) var fontSize
    @Environment(\.managedObjectContext) private var viewContext
    
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
                    List(words, id: \.objectID) { item in
                        /// Lazy NavigationLink: DetailView is only created when the user taps
                        NavigationLink {
                            DetailView(dict: item)
                        } label: {
                            DictionaryRowView(
                                word: item.word ?? "No word",
                                definition: item.def ?? "No Definition",
                                searchText: searchText,
                                fontSize: fontSizeDouble
                            )
                            .equatable()
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always),
                         prompt: NSLocalizedString("Search word", comment: "for searching words"))
            .onChange(of: searchText) { newValue in
                /// Debounce search — wait 300ms after last keystroke before fetching
                searchTask?.cancel()
                let task = DispatchWorkItem {
                    fetchFilteredData(query: newValue)
                }
                searchTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
            }
            .onChange(of: sortMode) { _ in
                fetchFilteredData(query: searchText)
            }
            .onAppear {
                guard !hasLoadedInitialData else { return }
                hasLoadedInitialData = true
                fetchFilteredData(query: "")
                
                // Show an interstitial ad after a delay — NOT during launch.
                // This gives the UI time to fully render before presenting a full-screen ad.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if adManager.isAdReady, let rootVC = getRootViewController() {
                        adManager.showAd(from: rootVC)
                    }
                }
            }
            // Re-fetch when the background JSON import finishes
            .onReceive(NotificationCenter.default.publisher(for: .dictionaryDataDidLoad)
                .receive(on: DispatchQueue.main)) { _ in
                fetchFilteredData(query: searchText)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("MEM Dictionary", comment: "the dictionary navigation title."))
                        .font(.custom("Pyidaungsu", size: fontSizeDouble))
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
    
    // MARK: - Data Fetching
    
    private func fetchFilteredData(query: String) {
        let fetchRequest: NSFetchRequest<MonDic> = MonDic.fetchRequest()
        
        /// Performance: Only materialize 20 objects at a time (the rest stay as faults)
        fetchRequest.fetchBatchSize = 20
        
        /// Performance: Reduced limits — keeps SwiftUI diffing fast
        if query.isEmpty {
            fetchRequest.fetchLimit = 100
        } else {
            fetchRequest.fetchLimit = 100
        }
        
        switch sortMode {
        case .az:
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "word", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
            ]
        case .za:
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "word", ascending: false, selector: #selector(NSString.caseInsensitiveCompare(_:)))
            ]
        case .random:
            fetchRequest.sortDescriptors = []
        }
        
        if !query.isEmpty {
            let beginsWithPredicate = NSPredicate(format: "word BEGINSWITH[cd] %@", query)
            let containsInDefPredicate = NSPredicate(format: "def CONTAINS[cd] %@", query)
            fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [beginsWithPredicate, containsInDefPredicate])
        }
        
        do {
            var results = try viewContext.fetch(fetchRequest)
            
            if sortMode == .random {
                results.shuffle()
            } else if !query.isEmpty {
                // Prioritize words that BEGIN WITH the query over definition-only matches.
                // CoreData can't express this ordering, so we partition after the fetch.
                let lowercasedQuery = query.lowercased()
                let beginsWith = results.filter { ($0.word ?? "").lowercased().hasPrefix(lowercasedQuery) }
                let others = results.filter { !($0.word ?? "").lowercased().hasPrefix(lowercasedQuery) }
                results = beginsWith + others
            }
            
            self.words = results
        } catch {
            print("Failed to fetch data: \(error)")
            self.words = []
        }
        
        self.isLoading = false
    }
    
    // MARK: - Helpers
    
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
        DictionaryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(LanguageViewModel())
    }
}
