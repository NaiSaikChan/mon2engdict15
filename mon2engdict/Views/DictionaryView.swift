//
//  DictionaryView.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI

// MARK: - First-letter avatar color helper (shared across views)
let avatarColors: [Color] = [
    .blue, .purple, .orange, .pink, .teal, .indigo, .mint, .cyan, .brown, .green
]

func avatarColor(for letter: Character) -> Color {
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
    @State private var words: [DictionaryEntry] = []
    @State private var isLoading: Bool = true
    @State private var showingAddWord = false
    @State private var hasLoadedInitialData = false
    @State private var searchTask: Task<Void, Never>?
    
    @AppStorage("sortMode") private var sortMode: SortMode = .az
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    @EnvironmentObject var languageViewModel: LanguageViewModel
    @StateObject var adManager = InterstitialAdManager()
    
    private let dbManager = DatabaseManager.shared
    
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
                    List(words) { item in
                        NavigationLink {
                            DetailView(entry: item)
                        } label: {
                            DictionaryRowView(
                                word: item.word,
                                definition: item.definition,
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
                // Cancel previous search and debounce with async Task
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                    guard !Task.isCancelled else { return }
                    await fetchData(query: newValue)
                }
            }
            .onChange(of: sortMode) { _ in
                Task {
                    await fetchData(query: searchText)
                }
            }
            .onAppear {
                guard !hasLoadedInitialData else { return }
                hasLoadedInitialData = true
                Task {
                    await fetchData(query: "")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if adManager.isAdReady, let rootVC = getRootViewController() {
                        adManager.showAd(from: rootVC)
                    }
                }
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
            .sheet(isPresented: $showingAddWord, onDismiss: {
                // Refresh list after adding a new word
                Task {
                    await fetchData(query: searchText)
                }
            }) {
                AddWordView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Data Fetching (async, off main thread)
    
    @MainActor
    private func fetchData(query: String) async {
        if query.isEmpty {
            switch sortMode {
            case .az:
                words = await dbManager.fetchAllAsync(limit: 500, sortAZ: true)
            case .za:
                words = await dbManager.fetchAllAsync(limit: 500, sortAZ: false)
            case .random:
                var results = await dbManager.fetchAllAsync(limit: 500, sortAZ: true)
                results.shuffle()
                words = results
            }
        } else {
            words = await dbManager.searchAsync(query: query, limit: 500)
            if sortMode == .random {
                words.shuffle()
            }
        }
        isLoading = false
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
            .environmentObject(LanguageViewModel())
    }
}
