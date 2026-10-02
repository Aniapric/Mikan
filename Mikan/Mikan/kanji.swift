import Foundation
import SwiftUI
import Combine

// Word example model
struct Example: Codable, Hashable {
    let japanese: String
    let english: String
}

// Main kanji data model
struct Kanji: Identifiable, Codable, Hashable {
    let id: String
    let kanji: String
    let level: String
    let strokes: Int
    let meanings: [String]
    let onyomi: [String]
    let kunyomi: [String]
    let examples: [Example]
    
    // Sample kanji for previews and testing
    static let sample = Kanji(
        id: "n5_1",
        kanji: "日",
        level: "N5",
        strokes: 4,
        meanings: ["Sun", "Day"],
        onyomi: ["ニチ", "ジツ"],
        kunyomi: ["ひ", "-び"],
        examples: [
            Example(japanese: "日本 (にほん)", english: "Japan"),
            Example(japanese: "毎日 (まいにち)", english: "Every day")
        ]
    )
}

// App Group shared storage container
public struct SharedStorage {
    public static let suiteName = "group.com.aniapricop.Mikan"
    public static let levelKey = "mikan_selected_level"
    public static let modeKey = "mikan_navigation_mode"
    public static let favoritesKey = "mikan_favorite_ids"
    public static let currentKanjiKey = "mikan_current_kanji_id"
    
    public static var defaults: UserDefaults {
        if let shared = UserDefaults(suiteName: suiteName) {
            return shared
        }
        return UserDefaults.standard
    }
}

// JLPT levels for filtering, including saved favorites
enum JLPTLevel: String, CaseIterable, Identifiable, Codable {
    case all = "All"
    case n5 = "N5"
    case n4 = "N4"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"
    case favorites = "★ Saved"
    
    var id: String { rawValue }
}

// Order of browsing kanji
enum NavigationMode: String, CaseIterable, Identifiable, Codable {
    case inOrder = "In Order"
    case random = "Random"
    
    var id: String { rawValue }
}

// Manages kanji list, filtering, favorites, and persistent storage
@MainActor
class KanjiStore: ObservableObject {
    @Published var allKanjis: [Kanji] = []
    @Published var selectedLevel: JLPTLevel = .all
    @Published var navigationMode: NavigationMode = .inOrder
    @Published var favoriteIDs: Set<String> = []
    @Published var currentIndex: Int = 0
    
    // Filter kanjis based on selected level or favorites
    var filteredKanjis: [Kanji] {
        switch selectedLevel {
        case .all:
            return allKanjis
        case .favorites:
            return allKanjis.filter { favoriteIDs.contains($0.id) }
        case .n5, .n4, .n3, .n2, .n1:
            return allKanjis.filter { $0.level.uppercased() == selectedLevel.rawValue.uppercased() }
        }
    }
    
    // Current kanji displayed on the card
    var currentKanji: Kanji {
        guard !filteredKanjis.isEmpty else {
            return Kanji.sample
        }
        let safeIndex = min(max(currentIndex, 0), filteredKanjis.count - 1)
        return filteredKanjis[safeIndex]
    }
    
    // Check if the current kanji is bookmarked as favorite
    var isCurrentFavorite: Bool {
        guard !filteredKanjis.isEmpty else { return false }
        return favoriteIDs.contains(currentKanji.id)
    }
    
    var canGoBack: Bool {
        return currentIndex > 0
    }
    
    var canGoForward: Bool {
        return currentIndex < filteredKanjis.count - 1
    }
    
    init() {
        loadPreferences()
        loadKanjis()
    }
    
    // Load kanji data from the bundled json file
    func loadKanjis() {
        guard let url = Bundle.main.url(forResource: "kanji", withExtension: "json") else {
            print("Could not find kanji.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.allKanjis = try decoder.decode([Kanji].self, from: data)
            print("Loaded \(allKanjis.count) kanji successfully")
            
            // Restore position if previously saved
            let defaults = SharedStorage.defaults
            if let savedId = defaults.string(forKey: SharedStorage.currentKanjiKey),
               let idx = filteredKanjis.firstIndex(where: { $0.id == savedId }) {
                self.currentIndex = idx
            }
        } catch {
            print("Error parsing kanji.json: \(error)")
        }
    }
    
    // Load saved preferences from shared UserDefaults
    private func loadPreferences() {
        let defaults = SharedStorage.defaults
        if let savedLevelRaw = defaults.string(forKey: SharedStorage.levelKey),
           let savedLevel = JLPTLevel(rawValue: savedLevelRaw) {
            self.selectedLevel = savedLevel
        }
        if let savedModeRaw = defaults.string(forKey: SharedStorage.modeKey),
           let savedMode = NavigationMode(rawValue: savedModeRaw) {
            self.navigationMode = savedMode
        }
        if let savedFavs = defaults.stringArray(forKey: SharedStorage.favoritesKey) {
            self.favoriteIDs = Set(savedFavs)
        }
    }
    
    // Save current settings and position
    private func savePreferences() {
        let defaults = SharedStorage.defaults
        defaults.set(selectedLevel.rawValue, forKey: SharedStorage.levelKey)
        defaults.set(navigationMode.rawValue, forKey: SharedStorage.modeKey)
        defaults.set(Array(favoriteIDs), forKey: SharedStorage.favoritesKey)
        defaults.set(currentKanji.id, forKey: SharedStorage.currentKanjiKey)
    }
    
    // Toggle favorite status for a kanji
    func toggleFavorite(id: String) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        savePreferences()
    }
    
    // Change active JLPT level
    func setLevel(_ level: JLPTLevel) {
        self.selectedLevel = level
        self.currentIndex = 0
        savePreferences()
    }
    
    // Switch between sequential and random browsing
    func toggleNavigationMode() {
        self.navigationMode = (navigationMode == .inOrder) ? .random : .inOrder
        savePreferences()
    }
    
    // Navigation helpers
    func nextKanji() {
        if navigationMode == .random && !filteredKanjis.isEmpty {
            currentIndex = Int.random(in: 0..<filteredKanjis.count)
        } else {
            guard canGoForward else { return }
            currentIndex += 1
        }
        savePreferences()
    }
    
    func previousKanji() {
        guard canGoBack else { return }
        currentIndex -= 1
        savePreferences()
    }
}
