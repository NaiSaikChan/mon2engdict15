# 📘 MonEng Dictionary

**MonEng Dictionary** is a bilingual offline dictionary for iOS that allows users to search, learn, and manage over 50,000 words and definitions between **Mon** and **English**. Designed for students, travelers, and language enthusiasts, the app provides a modern, fast, and personalized language reference tool.

---

## 🚀 Features

- 🔍 **Bilingual Search**  
  Search for words in **Mon → English** or **English → Mon** with smart filtering logic.

- 🧠 **50,000+ Words Offline**  
  A rich built-in dictionary dataset accessible without internet.

- ✨ **Highlighted Results**  
  Highlights matching search terms for easier visual scanning.

- ➕ **Add Custom Words**  
  Users can add their own words and definitions in both Mon and English.

- ⭐ **Favorites & History**  
  - Favorite words can be saved for quick access.  
  - Tracks recently viewed words with timestamps.

- 🔊 **Speech Support**  
  Pronounces English words using `AVSpeechSynthesizer`.

- 🎨 **UI Customization**  
  - Light, Dark, or System theme  
  - Adjustable font size (14–26 pts)  
  - Sort options for word lists

- 🌐 **Localization**  
  UI language can be switched between **Mon** and **English**.

---

## 📲 Installation

Clone the repo and open it in **Xcode** (requires Xcode 14 or later):

```bash
git clone https://github.com/yourusername/moneng-dictionary.git
cd moneng-dictionary
open MonEngDictionary.xcodeproj
````

### Dependencies:

* SwiftUI
* CoreData
* AVFoundation (for speech synthesis)

---

## 📁 Project Structure

```
MonEngDictionary/
│
├── Models/
│   └── MonDic.xcdatamodeld         # CoreData entity for dictionary words
│
├── Views/
│   ├── SearchView.swift            # Main search screen
│   ├── DetailView.swift            # Word details with speech/favorite/history
│   ├── FavoritesView.swift
│   ├── HistoryView.swift
│   ├── SettingsView.swift
│   └── AddWordView.swift
│
├── Resources/
│   ├── dictionary_a.json           # Initial dictionary dataset
│   ├── Localizable.strings         # App localization for Mon and English
│
├── Utilities/
│   ├── PersistenceController.swift # CoreData setup
│   └── HighlightHelper.swift       # Helper for text highlighting
│
└── Assets.xcassets/                # App icons and UI assets
```

---

## 💡 Search Logic

* If search text starts with a-z or A-Z:

  * First query: `english BEGINSWITH[cd] %@`
  * Fallback query: `mon CONTAINS[cd] %@`

* Else:

  * Query: `english ==[cd] %@ OR mon CONTAINS[cd] %@`

* **Results are ordered** with exact matches shown first, followed by partial matches.

---

## 🗃️ First Launch Setup

* On first app launch, a built-in JSON file (`dictionary_a.json`) is parsed and imported into CoreData.
* Future launches skip the import using a `UserDefaults` flag: `isDataImported`.

---

## 📦 App Store Ready

App name: **MonEng Dictionary**
App icon, metadata, and localization are included.
See [App Store Description »](#)

---

## 🛠 Development Notes

* Written in **SwiftUI**.
* Compatible with **iOS 15+**.
* Uses **NavigationSplitView** and `@AppStorage` for responsive design and persistent settings.

---

## 🙌 Credits

Developed by \[Monitvilla / Team]
[Monitvilla Mon-En Dic Data source](https://github.com/Monitvilla/monitvilla.github.io)
Special thanks to the Mon community for preserving and promoting language resources.

---

## 📄 License

This project is licensed under the MIT License.
See `LICENSE` file for more details.

```

---

Let me know if you’d like a version tailored for GitHub Pages, export to PDF, or additions like screenshots, contribution guidelines, or FAQ.
```
