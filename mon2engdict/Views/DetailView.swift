//
//  DetailView.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//

import SwiftUI
import AVFoundation

struct DetailView: View {
    @State var entry: DictionaryEntry
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("fontSize") private var fontSizeDouble: Double = 16
    
    @State private var heartScale: CGFloat = 1.0
    @State private var showCopied = false
    
    private let synthesizer = AVSpeechSynthesizer()
    private let dbManager = DatabaseManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Word Header Card
                VStack(spacing: 12) {
                    HStack(alignment: .top) {
                        // First-letter avatar (matching DictionaryRowView)
                        let letter = entry.word.first ?? "?"
                        Text(String(letter).uppercased())
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(avatarColor(for: letter))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.word)
                                .font(.custom("Pyidaungsu", size: fontSizeDouble + 8))
                                .fontWeight(.bold)
                                .textSelection(.enabled)
                            
                            Text(NSLocalizedString("Dictionary", comment: "word type label"))
                                .font(.custom("Pyidaungsu", size: fontSizeDouble - 4))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        // Animated favorite heart
                        Button {
                            toggleFavorite()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                heartScale = 1.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                    heartScale = 1.0
                                }
                            }
                        } label: {
                            Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(entry.isFavorite ? .pink : .gray)
                                .scaleEffect(heartScale)
                        }
                        .accessibilityLabel(entry.isFavorite
                            ? NSLocalizedString("Remove from favorites", comment: "")
                            : NSLocalizedString("Add to favorites", comment: ""))
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
                
                // MARK: - Definition Section
                VStack(alignment: .leading, spacing: 10) {
                    Label(NSLocalizedString("Definition", comment: "Definition section header"),
                          systemImage: "text.quote")
                        .font(.custom("Pyidaungsu", size: fontSizeDouble - 1))
                        .foregroundStyle(.secondary)
                    
                    Text(entry.definition)
                        .font(.custom("Pyidaungsu", size: fontSizeDouble + 1))
                        .lineSpacing(6)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
                
                // MARK: - Action Buttons
                HStack(spacing: 12) {
                    // Pronounce
                    ActionButton(
                        title: NSLocalizedString("Pronounce", comment: "Pronounce button"),
                        icon: "speaker.wave.2.fill",
                        color: .blue,
                        fontSize: fontSizeDouble
                    ) {
                        pronounceWord(entry.word, language: "en-US")
                    }
                    
                    // Copy
                    ActionButton(
                        title: showCopied
                            ? NSLocalizedString("Copied!", comment: "Copied feedback")
                            : NSLocalizedString("Copy", comment: "Copy button"),
                        icon: showCopied ? "checkmark.circle.fill" : "doc.on.doc",
                        color: showCopied ? .green : .orange,
                        fontSize: fontSizeDouble
                    ) {
                        copyToClipboard()
                    }
                    
                    // Share
                    ActionButton(
                        title: NSLocalizedString("Share", comment: "Share button"),
                        icon: "square.and.arrow.up",
                        color: .purple,
                        fontSize: fontSizeDouble
                    ) {
                        shareWord()
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(NSLocalizedString("Detail", comment: "the dictionary word detail."))
                    .font(.custom("Pyidaungsu", size: fontSizeDouble))
                    .fontWeight(.semibold)
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleFavorite() {
        let newValue = dbManager.toggleFavorite(id: entry.id, currentValue: entry.isFavorite)
        entry.isFavorite = newValue
    }
    
    private func pronounceWord(_ text: String, language: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
    
    private func copyToClipboard() {
        let text = "\(entry.word)\n\(entry.definition)"
        UIPasteboard.general.string = text
        withAnimation {
            showCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopied = false
            }
        }
    }
    
    private func shareWord() {
        let text = "\(entry.word) - \(entry.definition)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Walk up to the topmost presented controller to avoid presentation conflicts
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            // iPad popover source
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Action Button Component

private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let fontSize: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(title)
                    .font(.custom("Pyidaungsu", size: fontSize - 3))
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Preview

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailView(entry: DictionaryEntry(id: 1, word: "Hello", definition: "မ္ၚဵုရအဴ", isFavorite: false))
        }
    }
}
