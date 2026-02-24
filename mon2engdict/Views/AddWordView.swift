//  AddWordView.swift
//  mon2engdict
//
//  Created by SaikChan on 21/09/2024.
//

import SwiftUI

struct AddWordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var languageViewModel: LanguageViewModel
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    @State private var wordAdd = ""
    @State private var defAdd = ""
    @FocusState private var focusedField: Field?
    
    private enum Field { case word, definition }
    
    private var canSave: Bool {
        !wordAdd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !defAdd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Word Field
                Section {
                    HStack {
                        Image(systemName: "character.cursor.ibeam")
                            .foregroundColor(.blue)
                            .font(.callout)
                        TextField(
                            NSLocalizedString("English or Mon", comment: "add word"),
                            text: $wordAdd
                        )
                        .font(.custom("Pyidaungsu", size: fontSizeDouble))
                        .focused($focusedField, equals: .word)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .definition
                        }
                    }
                } header: {
                    HStack {
                        Text(NSLocalizedString("Word", comment: "Word field header"))
                            .font(.custom("Pyidaungsu", size: fontSizeDouble - 3))
                        Spacer()
                        Text("\(wordAdd.count)")
                            .font(.custom("Pyidaungsu", size: fontSizeDouble - 3))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // MARK: - Definition Field
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $defAdd)
                            .font(.custom("Pyidaungsu", size: fontSizeDouble))
                            .frame(minHeight: 200)
                            .focused($focusedField, equals: .definition)
                            .overlay(alignment: .topLeading) {
                                if defAdd.isEmpty {
                                    Text(NSLocalizedString("Definition", comment: "Def subtitle"))
                                        .font(.custom("Pyidaungsu", size: fontSizeDouble))
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text(NSLocalizedString("Definition", comment: "Def subtitle"))
                            .font(.custom("Pyidaungsu", size: fontSizeDouble - 3))
                        Spacer()
                        Text("\(defAdd.count)")
                            .font(.custom("Pyidaungsu", size: fontSizeDouble - 3))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // MARK: - Notice
                Section {
                    Label {
                        Text(NSLocalizedString("Own add Word", comment: "notice for add new own word."))
                            .font(.custom("Pyidaungsu", size: fontSizeDouble - 2))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.callout)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("New Word", comment: "the dictionary new word navi."))
                        .font(.custom("Pyidaungsu", size: fontSizeDouble))
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text(NSLocalizedString("Cancel", comment: "cancel button"))
                            .font(.custom("Pyidaungsu", size: fontSizeDouble))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addWord()
                        dismiss()
                    } label: {
                        Text(NSLocalizedString("Save", comment: "save button"))
                            .font(.custom("Pyidaungsu", size: fontSizeDouble))
                            .fontWeight(.semibold)
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                focusedField = .word
            }
        }
    }
    
    private func addWord() {
        let trimmedWord = wordAdd.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDef = defAdd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty, !trimmedDef.isEmpty else { return }
        
        let newWord = MonDic(context: viewContext)
        newWord.id = UUID()
        newWord.word = trimmedWord
        newWord.def = trimmedDef
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
