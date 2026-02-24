//
//  DataLoader.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI
import CoreData
import Foundation

struct DictionaryEntry: Codable {
    let word: String
    let def: String
}

struct DictionaryWarpper: Codable {
    let data: [DictionaryEntry]
}

/// Notification posted on the **main thread** after the background import finishes.
extension Notification.Name {
    static let dictionaryDataDidLoad = Notification.Name("dictionaryDataDidLoad")
}

/// Perform the heavy JSON-to-CoreData import on a **background context**
/// so the main thread (and UI) stays responsive.
func loadAllJSONFilesAndSaveToCoreData(container: NSPersistentContainer) {
    let backgroundContext = container.newBackgroundContext()
    backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    
    backgroundContext.perform {
        let fileNames = getJSONFileNames()
        
        for fileName in fileNames {
            let entries = loadJSON(form: fileName)
            saveEntriesToCoreData(entries: entries, context: backgroundContext)
        }
        
        print("All JSON data loaded and saved to CoreData successfully!")
        
        // Notify on the main thread so the UI can safely re-fetch
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dictionaryDataDidLoad, object: nil)
        }
    }
}

/// Function to retrieve all JSON file name matching a pattern
func getJSONFileNames() -> [String] {
    let fileManager = FileManager.default
    let bundleURL = Bundle.main.bundleURL
    
    do {
        let fileURLs = try fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
        
        let jsonFileNames = fileURLs
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix("mondict")}
            .map { $0.deletingPathExtension().lastPathComponent}
        return jsonFileNames
    } catch {
        print("Error retrieving JSON files: \(error)")
        return []
    }
}

/// Function to load JSON data from a specified file.
func loadJSON(form filename: String) -> [DictionaryEntry] {
    guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
        print("Failed to locate \(filename).json in bundle")
        return []
    }
    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let wapper = try decoder.decode(DictionaryWarpper.self, from: data)
        return wapper.data
    } catch {
        print("Error parsing JSON from \(filename): \(error)")
        return []
    }
}

/// Save loaded entries to CoreData in efficient batches using the provided
/// **background** context. Uses `autoreleasepool` + `reset()` to keep memory
/// low during 47 K+ inserts, and only resets the background context (never the
/// viewContext, which would invalidate UI-bound objects).
func saveEntriesToCoreData(entries: [DictionaryEntry], context: NSManagedObjectContext) {
    guard !entries.isEmpty else {
        print("No entries found in the provided JSON data.")
        return
    }
    
    let batchSize = 500
    
    for batchStart in stride(from: 0, to: entries.count, by: batchSize) {
        autoreleasepool {
            let batchEnd = min(batchStart + batchSize, entries.count)
            let batch = entries[batchStart..<batchEnd]
            
            for entry in batch {
                let dicWord = MonDic(context: context)
                dicWord.id = UUID()
                dicWord.word = entry.word
                dicWord.def = entry.def
                dicWord.isFavorite = false
                dicWord.lastViewed = nil
            }
            
            do {
                try context.save()
            } catch {
                print("Failed to save batch starting at \(batchStart): \(error)")
            }
            
            /// Reset the *background* context to free memory between batches
            context.reset()
        }
    }
    
    print("Data saved to CoreData successfully! (\(entries.count) entries)")
}


/// Check whether CoreData already contains dictionary data.
/// If empty, kick off a **background** import so the main thread is never blocked.
func loadDataIfNeeded(container: NSPersistentContainer) {
    let context = container.viewContext
    let fetchRequest: NSFetchRequest<MonDic> = MonDic.fetchRequest()
    fetchRequest.fetchLimit = 1
    
    do {
        let count = try context.count(for: fetchRequest)
        if count == 0 {
            // No data in CoreData — import on a background thread
            loadAllJSONFilesAndSaveToCoreData(container: container)
        } else {
            print("CoreData already has data, skipping JSON import.")
        }
    } catch {
        print("Failed to count CoreData entries: \(error)")
    }
}
