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

func loadAllJSONFilesAndSaveToCoreData(context: NSManagedObjectContext) {
    // Get all filenames that match the dictionary JSON naming pattern
    let fileNames = getJSONFileNames()
    
    for fileName in fileNames {
        let entries = loadJSON(form: fileName)
        saveEntriesToCoreData(entries: entries, context: context)
    }
    
    print("All JSON data loaded and saved to CoreData successfully!")
}

///Function to retrieve all JSON file name matching a pattern
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

/// Function to load JSON data from aspecified file.
func loadJSON(form filename: String) -> [DictionaryEntry] {
    guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
        print("Failed to loacate \(filename).json in bundel")
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

/// Function to save loaded entries to CoreData.
func saveEntriesToCoreData(entries: [DictionaryEntry], context: NSManagedObjectContext) {
    guard !entries.isEmpty else {
        print("No entries found in the provided JSON data.")
        return
    }
    
    for entry in entries {
        let DicWord = MonDic(context: context)
        DicWord.id = UUID()
        DicWord.word = entry.word
        DicWord.def = entry.def
        DicWord.isFavorite = false
        DicWord.lastViewed = nil
    }
    do {
        try context.save()
        print("Data saved to CoreData successfully!")
    } catch {
        print("Failed to save data to CoreDate!: \(error)")
    }
}


func loadDataIfNeeded(context: NSManagedObjectContext) {
    // Check if CoreData already has data
    let fetchRequest: NSFetchRequest<MonDic> = MonDic.fetchRequest()
    fetchRequest.fetchLimit = 1 // Limit to 1 to improve performance
    
    do {
        let count = try context.count(for: fetchRequest)
        if count == 0 {
            // No data in CoreData, so load from JSON
            //loadJSONAndSaveToCoreData(context: context)
            loadAllJSONFilesAndSaveToCoreData(context: context)
        } else {
            print("CoreData already has data, skipping JSON import.")
        }
    } catch {
        print("Failed to count CoreData entries: \(error)")
    }
}
