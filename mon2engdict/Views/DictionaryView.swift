//
//  DictionaryView.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI
import CoreData

// MARK: - First-letter avatar color helper
private let avatarColors: [Color] = [
    .blue, .purple, .orange, .pink, .teal, .indigo, .mint, .cyan, .brown, .green
]

private func avatarColor(for letter: Character) -> Color {
    let index = Int(letter.asciiValue ?? 0) % avatarColors.count
    return avatarColors[index]
}

// MARK: - Extracted Row View

struct DictionaryRowView: View, Equatable {
    let word: String
    let definition: String
    let searchText: String
    let fontSize: Double
    let isFavorite: Bool
    
    static func == (lhs: DictionaryRowView, rhs: DictionaryRowView) -> Bool {
        lhs.word == rhs.word &&
        lhs.definition == rhs.definition &&
        lhs.searchText == rhs.searchText &&
        lhs.fontSize == rhs.fontSize &&
        lhs.isFavorite == rhs.isFavorite
    }
    
    private var firstLetter: Character {
        word.first ?? "?"
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // First-letter circle avatar
            Text(String(firstLetter).uppercased())
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(avatarColor(for: firstLetter))
                .clipShape(Circle())
            
            // Word & definition
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if searchText.isEmpty {
                        Text(word)
                            .font(.custom("Pyidaungsu", size: fontSize + 2))
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    } else {
                        Text(highlightText(for: word))
                            .font(.custom("Pyidaungsu", size: fontSize + 2))
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.pink)
                    }
                }
                
                if searchText.isEmpty {
                    Text(definition)
                        .font(.custom("Pyidaungsu", size: fontSize - 1))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text(highlightText(for: definition))
                        .font(.custom("Pyidaungsu", size: fontSize - 1))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    private func highlightText(for text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        if let range = attributedString.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) {
            attributedString[range].foregroundColor = .blue
            attributedString[range].font = .custom("Pyidaungsu", size: fontSize + 2).bold()
        }
        return attributedString
    }
}

// MARK: - Empty State View

struct EmptySearchStateView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: query.isEmpty ? "text.book.closed" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            
            if query.isEmpty {
                Text(NSLocalizedString("No words available", comment: "Empty dictionary state"))
                    .font(.custom("Pyidaungsu", size: 16))
                    .foregroundStyle(.secondary)
            } else {
                Text(NSLocalizedString("No results for", comment: "No search results prefix") + " \"\(query)\"")
                    .font(.custom("Pyidaungsu", size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(NSLocalizedString("Try a different spelling", comment: "Search suggestion"))
                    .font(.custom("Pyidaungsu", size: 14))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Dictionary View

struct DictionaryView: View {
    @State private var searchText = ""
    @State private var words: [MonDic] = []
    @State private var isLoading: Bool = true
    @State private var showingAddWord = false
    @State private var hasLoadedInitialData = false
    @State private var searchTask: DispatchWorkItem?
    
    @AppStorage("sortMode") private var sortMode: SortMode = .az
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    @EnvironmentObject var languageViewModel: LanguageViewModel
    @StateObject var adManager = InterstitialAdManager()
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    // Loading placeholder
                    List {
                        ForEach(0..<8, id: \.self) { _ in
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 42, height: 42)
                                VStack(alignment: .leading, spacing: 8) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 140, height: 14)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.10))
                                        .frame(width: 200, height: 12)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                    .redacted(reason: .placeholder)
                } else if words.isEmpty {
                    EmptySearchStateView(query: searchText)
                } else {
                    List(words, id: \.objectID) { item in
                        NavigationLink {
                            DetailView(dict: item)
                        } label: {
                            DictionaryRowView(
                                word: item.word ?? "No word",
                                definition: item.def ?? "No Definition",
                                searchText: searchText,
                                fontSize: fontSizeDouble,
                                isFavorite: item.isFavorite
                            )
                            .equatable()
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always),
                         prompt: NSLocalizedString("Search word", comment: "for searching words"))
            .onChange(of: searchText) { newValue in
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if adManager.isAdReady, let rootVC = getRootViewController() {
                        adManager.showAd(from: rootVC)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dictionaryDataDidLoad)
                .receive(on: DispatchQueue.main)) { _ in
                fetchFilteredData(query: searchText)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(NSLocalizedString("MEM Dictionary", comment: "the dictionary navigation title."))
                            .font(.custom("Pyidaungsu", size: fontSizeDouble))
                            .fontWeight(.semibold)
                        if !isLoading && !words.isEmpty {
                            Text("\(words.count) " + NSLocalizedString("words", comment: "result count label"))
                                .font(.custom("Pyidaungsu", size: fontSizeDouble - 4))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddWord = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
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
        fetchRequest.fetchBatchSize = 20
        
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
