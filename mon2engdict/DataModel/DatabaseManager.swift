//
//  DatabaseManager.swift
//  mon2engdict
//
//  Created by Saik Chan on 26/02/2026.
//

import Foundation
import SQLite

// MARK: - Model

struct DictionaryEntry: Identifiable {
    let id: Int64
    let word: String
    let definition: String
    var isFavorite: Bool
}

// MARK: - Database Manager

class DatabaseManager: ObservableObject {
    
    static let shared = DatabaseManager()
    
    private var db: Connection?
    
    // Table & columns
    private let table = Table("monengdict")
    private let colId = Expression<Int64>("id")
    private let colWord = Expression<String>("word")
    private let colDef = Expression<String>("defination")  // matches DB column spelling
    private let colFav = Expression<Int64>("isFavorite")
    
    // MARK: - Init (copy bundle DB → writable Documents)
    
    private init() {
        do {
            let dbPath = try Self.writableDatabasePath()
            db = try Connection(dbPath)
            print("SQLite DB opened at: \(dbPath)")
            ensureIndexes()
        } catch {
            print("Failed to open database: \(error)")
        }
    }
    
    /// Copies the bundle DB to Documents on first launch so it's writable.
    private static func writableDatabasePath() throws -> String {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(for: .documentDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true)
        let destURL = documentsURL.appendingPathComponent("engmondict.db")
        
        if !fileManager.fileExists(atPath: destURL.path) {
            guard let bundleURL = Bundle.main.url(forResource: "engmondict", withExtension: "db") else {
                fatalError("engmondict.db not found in app bundle.")
            }
            try fileManager.copyItem(at: bundleURL, to: destURL)
            print("Database copied to Documents.")
        }
        
        return destURL.path
    }
    
    // MARK: - Search (raw SQL with CASE WHEN ordering)
    
    func search(query: String, limit: Int = 100) -> [DictionaryEntry] {
        guard let db = db else { return [] }
        guard !query.isEmpty else { return fetchAll(limit: limit) }
        
        let sql = """
            SELECT id, word, defination, isFavorite FROM monengdict
            WHERE word = ?1
               OR word LIKE ?1 || '%'
               OR word LIKE '%' || ?1 || '%'
               OR defination LIKE '%' || ?1 || '%'
            ORDER BY CASE
                WHEN word = ?1 THEN 1
                WHEN word LIKE ?1 || '%' THEN 2
                WHEN word LIKE '%' || ?1 || '%' THEN 3
                WHEN defination LIKE '%' || ?1 || '%' THEN 4
                ELSE 5
            END, word
            LIMIT ?2
            """
        
        do {
            let stmt = try db.prepare(sql)
            var entries: [DictionaryEntry] = []
            for row in try stmt.bind(query, limit) {
                guard let id = row[0] as? Int64,
                      let word = row[1] as? String,
                      let def = row[2] as? String,
                      let fav = row[3] as? Int64 else { continue }
                entries.append(DictionaryEntry(id: id, word: word, definition: def, isFavorite: fav != 0))
            }
            return entries
        } catch {
            print("Search query failed: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch All (default list, A-Z)
    
    func fetchAll(limit: Int = 500, sortAZ: Bool = true) -> [DictionaryEntry] {
        guard let db = db else { return [] }
        
        let order = sortAZ ? "ASC" : "DESC"
        let sql = "SELECT id, word, defination, isFavorite FROM monengdict ORDER BY word COLLATE NOCASE \(order) LIMIT ?"
        
        do {
            let stmt = try db.prepare(sql)
            var entries: [DictionaryEntry] = []
            for row in try stmt.bind(limit) {
                guard let id = row[0] as? Int64,
                      let word = row[1] as? String,
                      let def = row[2] as? String,
                      let fav = row[3] as? Int64 else { continue }
                entries.append(DictionaryEntry(id: id, word: word, definition: def, isFavorite: fav != 0))
            }
            return entries
        } catch {
            print("Fetch all failed: \(error)")
            return []
        }
    }
    
    // MARK: - Favorites
    
    func fetchFavorites() -> [DictionaryEntry] {
        guard let db = db else { return [] }
        
        let sql = "SELECT id, word, defination, isFavorite FROM monengdict WHERE isFavorite = 1 ORDER BY word COLLATE NOCASE ASC"
        
        do {
            let stmt = try db.prepare(sql)
            var entries: [DictionaryEntry] = []
            for row in stmt {
                guard let id = row[0] as? Int64,
                      let word = row[1] as? String,
                      let def = row[2] as? String,
                      let fav = row[3] as? Int64 else { continue }
                entries.append(DictionaryEntry(id: id, word: word, definition: def, isFavorite: fav != 0))
            }
            return entries
        } catch {
            print("Fetch favorites failed: \(error)")
            return []
        }
    }
    
    func toggleFavorite(id: Int64, currentValue: Bool) -> Bool {
        guard let db = db else { return currentValue }
        
        let newValue: Int64 = currentValue ? 0 : 1
        let row = table.filter(colId == id)
        
        do {
            try db.run(row.update(colFav <- newValue))
            return !currentValue
        } catch {
            print("Toggle favorite failed: \(error)")
            return currentValue
        }
    }
    
    func setFavorite(id: Int64, value: Bool) {
        guard let db = db else { return }
        
        let row = table.filter(colId == id)
        do {
            try db.run(row.update(colFav <- (value ? 1 : 0)))
        } catch {
            print("Set favorite failed: \(error)")
        }
    }
    
    // MARK: - Add Word
    
    func addWord(word: String, definition: String) -> DictionaryEntry? {
        guard let db = db else { return nil }
        
        do {
            let rowId = try db.run(table.insert(
                colWord <- word,
                colDef <- definition,
                colFav <- 1  // auto-favorite user-added words
            ))
            return DictionaryEntry(id: rowId, word: word, definition: definition, isFavorite: true)
        } catch {
            print("Add word failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Ensure Indexes (call once on init for performance)
    
    func ensureIndexes() {
        guard let db = db else { return }
        do {
            try db.run("CREATE INDEX IF NOT EXISTS idx_word ON monengdict(word COLLATE NOCASE)")
            try db.run("CREATE INDEX IF NOT EXISTS idx_favorite ON monengdict(isFavorite)")
        } catch {
            print("Index creation failed: \(error)")
        }
    }
    
    // MARK: - Async Wrappers (off main thread)
    
    func searchAsync(query: String, limit: Int = 100) async -> [DictionaryEntry] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let results = self?.search(query: query, limit: limit) ?? []
                continuation.resume(returning: results)
            }
        }
    }
    
    func fetchAllAsync(limit: Int = 500, sortAZ: Bool = true) async -> [DictionaryEntry] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let results = self?.fetchAll(limit: limit, sortAZ: sortAZ) ?? []
                continuation.resume(returning: results)
            }
        }
    }
    
    func fetchFavoritesAsync() async -> [DictionaryEntry] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let results = self?.fetchFavorites() ?? []
                continuation.resume(returning: results)
            }
        }
    }
}
