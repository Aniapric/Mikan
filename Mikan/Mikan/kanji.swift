import Foundation
import SwiftUI
import Combine
import WidgetKit

struct Example: Codable, Hashable {
    let japanese: String
    let english: String
}

struct Kanji: Identifiable, Codable, Hashable {
    let id: String
    let kanji: String
    let level: String
    let strokes: Int
    let meanings: [String]
    let onyomi: [String]
    let kunyomi: [String]
    let examples: [Example]
    
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

public struct SharedStorage {
    public static let suiteName = "group.com.aniapricop.Mikan"
    public static let levelKey = "mikan_selected_level"
    public static let modeKey = "mikan_navigation_mode"
    public static let favoritesKey = "mikan_favorite_ids"
    public static let currentKanjiKey = "mikan_current_kanji_id"
    public static let anchorDateKey = "mikan_anchor_date"
    public static let anchorKanjiKey = "mikan_anchor_kanji_id"
    public static let frequencyKey = "mikan_update_frequency"
    public static let customHoursKey = "mikan_custom_hours"
    
    public static var defaults: UserDefaults {
        if let shared = UserDefaults(suiteName: suiteName) {
            return shared
        }
        return UserDefaults.standard
    }
}

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

enum NavigationMode: String, CaseIterable, Identifiable, Codable {
    case inOrder = "In Order"
    case random = "Random"
    
    var id: String { rawValue }
}

enum UpdateFrequencyType: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily (24h)"
    case twiceDaily = "2x / Day (12h)"
    case fourTimesDaily = "4x / Day (6h)"
    case hourly = "Hourly (1h)"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var subtitle: String {
        switch self {
        case .daily: return "Once a day at midnight"
        case .twiceDaily: return "Every 12 hours"
        case .fourTimesDaily: return "Every 6 hours"
        case .hourly: return "Every hour (24 kanji / day)"
        case .custom: return "Choose your preferred hours or frequency"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .twiceDaily: return "arrow.2.circlepath"
        case .fourTimesDaily: return "clock.arrow.2.circlepath"
        case .hourly: return "bolt.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    func hourInterval(customHours: Int) -> Int {
        switch self {
        case .daily: return 24
        case .twiceDaily: return 12
        case .fourTimesDaily: return 6
        case .hourly: return 1
        case .custom: return max(1, min(24, customHours))
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "Daily (24h)", "1 / zi (24h)": self = .daily
        case "2x / Day (12h)", "2 / zi (12h)": self = .twiceDaily
        case "4x / Day (6h)", "4 / zi (6h)": self = .fourTimesDaily
        case "Hourly (1h)", "Odată la 1h": self = .hourly
        case "Custom", "Personalizat": self = .custom
        default: return nil
        }
    }
}

@MainActor
class KanjiStore: ObservableObject {
    @Published var allKanjis: [Kanji] = []
    @Published var selectedLevel: JLPTLevel = .all
    @Published var navigationMode: NavigationMode = .inOrder
    @Published var favoriteIDs: Set<String> = []
    @Published var currentIndex: Int = 0
    @Published var updateFrequencyType: UpdateFrequencyType = .daily
    @Published var customHoursInterval: Int = 4
    
    private var randomHistory: [String] = []
    private var pendingTargetId: String? = nil
    
    var effectiveHourInterval: Int {
        updateFrequencyType.hourInterval(customHours: customHoursInterval)
    }
    
    var kanjis: [Kanji] {
        filteredKanjis
    }
    
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
    
    var currentKanji: Kanji {
        guard !filteredKanjis.isEmpty else {
            return Kanji.sample
        }
        let safeIndex = min(max(currentIndex, 0), filteredKanjis.count - 1)
        return filteredKanjis[safeIndex]
    }
    
    var isCurrentFavorite: Bool {
        guard !filteredKanjis.isEmpty else { return false }
        return favoriteIDs.contains(currentKanji.id)
    }
    
    var canGoBack: Bool {
        if navigationMode == .inOrder {
            return currentIndex > 0
        } else {
            return !randomHistory.isEmpty
        }
    }
    
    var canGoForward: Bool {
        if navigationMode == .inOrder {
            return currentIndex < filteredKanjis.count - 1
        } else {
            return filteredKanjis.count > 1
        }
    }
    
    init() {
        loadPreferences()
        loadKanjis()
    }
    
    func loadKanjis() {
        if let url = Bundle.main.url(forResource: "kanji", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let loadedKanjis = try decoder.decode([Kanji].self, from: data)
                self.allKanjis = loadedKanjis
                print("Loaded \(loadedKanjis.count) kanji successfully")
                
                restoreOrComputeCurrentKanji()
            } catch {
                print("Error loading kanji.json: \(error)")
            }
        } else {
            print("Could not find kanji.json in bundle")
        }
    }
    
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
        if let savedCurrentId = defaults.string(forKey: SharedStorage.currentKanjiKey) {
            self.pendingTargetId = savedCurrentId
        }
        if let savedFreqRaw = defaults.string(forKey: SharedStorage.frequencyKey),
           let savedFreq = UpdateFrequencyType(rawValue: savedFreqRaw) {
            self.updateFrequencyType = savedFreq
        }
        let savedHours = defaults.integer(forKey: SharedStorage.customHoursKey)
        if savedHours >= 1 && savedHours <= 24 {
            self.customHoursInterval = savedHours
        }
    }
    
    private func restoreOrComputeCurrentKanji() {
        let calendar = Calendar.current
        let now = Date()
        let defaults = SharedStorage.defaults
        var needsAnchorReset = false
        
        if let targetId = pendingTargetId, let idx = filteredKanjis.firstIndex(where: { $0.id == targetId }) {
            self.currentIndex = idx
            
            let anchorTimestamp = defaults.double(forKey: SharedStorage.anchorDateKey)
            if anchorTimestamp > 0 && navigationMode == .inOrder && !filteredKanjis.isEmpty {
                let anchorDate = Date(timeIntervalSince1970: anchorTimestamp)
                let h = effectiveHourInterval
                if h >= 24 {
                    let daysPassed = calendar.dateComponents([.day], from: calendar.startOfDay(for: anchorDate), to: calendar.startOfDay(for: now)).day ?? 0
                    if daysPassed > 0 {
                        self.currentIndex = (idx + daysPassed) % filteredKanjis.count
                        needsAnchorReset = true
                    }
                } else {
                    let secondsPassed = max(0, now.timeIntervalSince(anchorDate))
                    let intervalSeconds = Double(h * 3600)
                    let intervalsPassed = Int(secondsPassed / intervalSeconds)
                    if intervalsPassed > 0 {
                        self.currentIndex = (idx + intervalsPassed) % filteredKanjis.count
                        needsAnchorReset = true
                    }
                }
            }
        } else {
            self.currentIndex = 0
            needsAnchorReset = true
        }
        
        savePreferences(resetAnchor: needsAnchorReset)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func savePreferences(resetAnchor: Bool = false) {
        let defaults = SharedStorage.defaults
        let now = Date()
        defaults.set(selectedLevel.rawValue, forKey: SharedStorage.levelKey)
        defaults.set(navigationMode.rawValue, forKey: SharedStorage.modeKey)
        defaults.set(Array(favoriteIDs), forKey: SharedStorage.favoritesKey)
        defaults.set(currentKanji.id, forKey: SharedStorage.currentKanjiKey)
        defaults.set(updateFrequencyType.rawValue, forKey: SharedStorage.frequencyKey)
        defaults.set(customHoursInterval, forKey: SharedStorage.customHoursKey)
        
        let existingAnchor = defaults.double(forKey: SharedStorage.anchorDateKey)
        if resetAnchor || existingAnchor == 0 {
            defaults.set(currentKanji.id, forKey: SharedStorage.anchorKanjiKey)
            if effectiveHourInterval >= 24 {
                defaults.set(Calendar.current.startOfDay(for: now).timeIntervalSince1970, forKey: SharedStorage.anchorDateKey)
            } else {
                defaults.set(now.timeIntervalSince1970, forKey: SharedStorage.anchorDateKey)
            }
        }
        
        UserDefaults.standard.set(selectedLevel.rawValue, forKey: SharedStorage.levelKey)
        UserDefaults.standard.set(navigationMode.rawValue, forKey: SharedStorage.modeKey)
        UserDefaults.standard.set(Array(favoriteIDs), forKey: SharedStorage.favoritesKey)
        UserDefaults.standard.set(currentKanji.id, forKey: SharedStorage.currentKanjiKey)
        UserDefaults.standard.set(updateFrequencyType.rawValue, forKey: SharedStorage.frequencyKey)
        UserDefaults.standard.set(customHoursInterval, forKey: SharedStorage.customHoursKey)
        if resetAnchor || UserDefaults.standard.double(forKey: SharedStorage.anchorDateKey) == 0 {
            UserDefaults.standard.set(currentKanji.id, forKey: SharedStorage.anchorKanjiKey)
            if effectiveHourInterval >= 24 {
                UserDefaults.standard.set(Calendar.current.startOfDay(for: now).timeIntervalSince1970, forKey: SharedStorage.anchorDateKey)
            } else {
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: SharedStorage.anchorDateKey)
            }
        }
    }
    
    func syncToWidget(resetAnchor: Bool = false) {
        savePreferences(resetAnchor: resetAnchor)
        WidgetCenter.shared.reloadAllTimelines()
        print("Synced widget with kanji: \(currentKanji.kanji) (Level: \(currentKanji.level))")
    }
    
    func setLevel(_ level: JLPTLevel) {
        selectedLevel = level
        currentIndex = 0
        randomHistory.removeAll()
        syncToWidget(resetAnchor: true)
    }
    
    func setNavigationMode(_ mode: NavigationMode) {
        navigationMode = mode
        randomHistory.removeAll()
        syncToWidget(resetAnchor: true)
    }
    
    func toggleNavigationMode() {
        setNavigationMode(navigationMode == .inOrder ? .random : .inOrder)
    }
    
    func setUpdateFrequency(_ freq: UpdateFrequencyType) {
        updateFrequencyType = freq
        syncToWidget(resetAnchor: true)
    }
    
    func setCustomHoursInterval(_ hours: Int) {
        customHoursInterval = max(1, min(24, hours))
        if updateFrequencyType == .custom {
            syncToWidget(resetAnchor: true)
        }
    }
    
    func toggleFavorite(id: String) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
            if selectedLevel == .favorites && currentIndex >= filteredKanjis.count {
                currentIndex = max(0, filteredKanjis.count - 1)
            }
        } else {
            favoriteIDs.insert(id)
        }
        syncToWidget(resetAnchor: false)
    }
    
    func nextKanji() {
        guard !filteredKanjis.isEmpty else { return }
        
        if navigationMode == .inOrder {
            if currentIndex < filteredKanjis.count - 1 {
                currentIndex += 1
            } else {
                currentIndex = 0
            }
        } else {
            let currentId = currentKanji.id
            randomHistory.append(currentId)
            
            if filteredKanjis.count > 1 {
                var nextIndex = Int.random(in: 0..<filteredKanjis.count)
                while nextIndex == currentIndex {
                    nextIndex = Int.random(in: 0..<filteredKanjis.count)
                }
                currentIndex = nextIndex
            }
        }
        syncToWidget(resetAnchor: true)
    }
    
    func previousKanji() {
        guard !filteredKanjis.isEmpty else { return }
        
        if navigationMode == .inOrder {
            if currentIndex > 0 {
                currentIndex -= 1
            } else {
                currentIndex = filteredKanjis.count - 1
            }
        } else {
            if let lastId = randomHistory.popLast() {
                if let idx = filteredKanjis.firstIndex(where: { $0.id == lastId }) {
                    currentIndex = idx
                }
            }
        }
        syncToWidget(resetAnchor: true)
    }
}

