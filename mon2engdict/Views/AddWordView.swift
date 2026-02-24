//
//  AddWordView.swift
//  mon2engdict
//
//  Created by SaikChan on 21/09/2024.
//

import SwiftUI

///Add word view
struct AddWordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.fontSize) var fontSize
    @EnvironmentObject var languageViewModel: LanguageViewModel
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    @State private var wordAdd = ""
    @State private var defAdd = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Add Word", comment: "Title of the new word"))) {
                    TextField(NSLocalizedString("English or Mon", comment: "add word"), text: $wordAdd)
                        .font(.custom("Pyidaungsu", size: fontSizeDouble))
                        .textFieldStyle(RoundedBorderTextFieldStyle()) // Optional: Adds a border for visual consistency
                    
                    // Multiline input for Mon text
                    VStack(alignment: .leading) {
                        Text(NSLocalizedString("Definition", comment: "Def subtitle"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $defAdd)
                            .frame(minHeight: 300) // Adjust the height as needed
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary, lineWidth: 0.5) // Adds a border
                            )
                            .font(.custom("Pyidaungsu", size: fontSizeDouble))
                        Text(NSLocalizedString("Own add Word", comment: "notice for add new own word."))
                            .font(.custom("Pyidaungsu", size: fontSizeDouble))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text((NSLocalizedString("New Word", comment: "the dictionary new word navi.")))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "cancel button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "save button")) {
                        addWord()
                        dismiss()
                    }
                    .disabled(wordAdd.isEmpty || defAdd.isEmpty) // Disable save if fields are empty
                }
            }.font(.custom("Pyidaungsu", size: fontSizeDouble))
        }
    }
    
    private func addWord() {
        let newWord = MonDic(context: viewContext)
        newWord.id = UUID()
        newWord.word = wordAdd
        newWord.def = defAdd
        newWord.isFavorite = true
        newWord.lastViewed = nil
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save new word: \(error)")
        }
    }
}

#Preview {
    AddWordView()
        .environmentObject(LanguageViewModel())
}
