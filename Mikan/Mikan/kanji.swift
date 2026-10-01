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

// JLPT levels for filtering
enum JLPTLevel: String, CaseIterable, Identifiable, Codable {
    case all = "All"
    case n5 = "N5"
    case n4 = "N4"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"
    
    var id: String { rawValue }
}

// Manages kanji list, filtering, and navigation
@MainActor
class KanjiStore: ObservableObject {
    @Published var allKanjis: [Kanji] = []
    @Published var selectedLevel: JLPTLevel = .n5
    @Published var currentIndex: Int = 0
    
    // Filter kanjis by selected JLPT level
    var filteredKanjis: [Kanji] {
        switch selectedLevel {
        case .all:
            return allKanjis
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
    
    var canGoBack: Bool {
        return currentIndex > 0
    }
    
    var canGoForward: Bool {
        return currentIndex < filteredKanjis.count - 1
    }
    
    init() {
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
        } catch {
            print("Error parsing kanji.json: \(error)")
        }
    }
    
    // Change active JLPT level
    func setLevel(_ level: JLPTLevel) {
        self.selectedLevel = level
        self.currentIndex = 0
    }
    
    // Navigation helpers
    func nextKanji() {
        guard canGoForward else { return }
        currentIndex += 1
    }
    
    func previousKanji() {
        guard canGoBack else { return }
        currentIndex -= 1
    }
    
    func randomKanji() {
        guard !filteredKanjis.isEmpty else { return }
        currentIndex = Int.random(in: 0..<filteredKanjis.count)
    }
}
