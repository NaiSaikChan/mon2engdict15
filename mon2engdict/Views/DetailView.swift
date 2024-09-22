//
//  DetailView.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI
import CoreData
import AVFoundation

struct DetailView: View {
    @ObservedObject var dict: MonDic
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.fontSize) var fontSize
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    public var synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Text(dict.word ?? "")
                            .font(.custom("Pyidaungsu", size: fontSizeDouble+8))
                            .bold()
                        
                        Button(action: {
                            toggleFavorite()
                        }) {
                            Image(systemName: dict.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(dict.isFavorite ? .yellow : .gray)
                        }
                        .accessibilityLabel(dict.isFavorite ? NSLocalizedString("Remove from favorites", comment: "For remove the favorites word.") : NSLocalizedString("Add to favorites", comment: "For add the favoites word."))
                        .font(.custom("Pyidaungsu", size: fontSizeDouble))
                        Spacer()
                    }
                        .padding(.all,3)
                    
                    Text(dict.def ?? "")
                        .font(.custom("Pyidaungsu", size: fontSizeDouble+2))
                        .foregroundColor(.secondary)
                    
                    Button (action: {
                        pronounceWord(dict.word ?? "", language: "en-US")
                    }) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text(NSLocalizedString("Pronounce in English", comment: "To pronunce in only English."))
                                .font(.custom("Pyidaungsu", size: fontSizeDouble))
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding()
                
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text((NSLocalizedString("Detail", comment: "the dictionary word detail.")))
                            .font(.custom("Pyidaungsu", size:fontSizeDouble))
                    }
                }
            }
        
    }
    
    ///Functions
    
    ///Favorite Button to save the favorite word.
    private func toggleFavorite() {
        dict.isFavorite.toggle()
        saveContext()
    }
    
    ///Function for save the favoite word into CoreData.
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    /// Function for pronunce the word in English.
    private func pronounceWord(_ text: String, language: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        synthesizer.speak(utterance)
    }
}


struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Example usage of a preview context
        let context = PersistenceController.preview.container.viewContext
        let sampleWord = MonDic(context: context)
        sampleWord.word = "Hello"
        sampleWord.def = "မ္ၚဵုရအဴ"
        return DetailView(dict: sampleWord).environment(\.managedObjectContext, context)
    }
}
