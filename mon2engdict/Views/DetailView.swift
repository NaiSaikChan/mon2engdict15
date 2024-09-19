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
    
    public var synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(dict.word ?? "")
                    .font(.custom("Pyidaungsu", size: 24))
                    .bold()
                Spacer()
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: dict.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(dict.isFavorite ? .yellow : .gray)
                }
                .accessibilityLabel(dict.isFavorite ? NSLocalizedString("Remove from favorites", comment: "For remove the favorites word.") : NSLocalizedString("Add to favorites", comment: "For add the favoites word."))
                .font(.custom("Pyidaungsu", size: 14))
            }
            
                Text(dict.def ?? "")
                    .font(.custom("Pyidaungsu", size: 18))
                    .foregroundColor(.secondary)
            
            Button (action: {
                pronounceWord(dict.word ?? "", language: "en-US")
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Text(NSLocalizedString("Pronounce in English", comment: "To pronunce in only English."))
                        .font(.custom("Pyidaungsu", size: 14))
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
            }
            Spacer()
        }
        .padding()
        .navigationTitle(NSLocalizedString("Detail", comment: "the dictionary word detail."))
        .navigationBarTitleDisplayMode(.inline)
        .font(.custom("Pyidaungsu", size: 14))
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
