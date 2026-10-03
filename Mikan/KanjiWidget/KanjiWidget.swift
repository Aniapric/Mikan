import WidgetKit
import SwiftUI

struct KanjiEntry: TimelineEntry {
    let date: Date
    let kanji: Kanji
}

struct Provider: TimelineProvider {
    typealias Entry = KanjiEntry

    func placeholder(in context: Context) -> KanjiEntry {
        KanjiEntry(date: Date(), kanji: Kanji.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (KanjiEntry) -> ()) {
        let kanjis = getAvailableKanjis()
        let (_, current, _) = computeCurrentIndexAndNextDate(from: kanjis, hourInterval: 24)
        let entry = KanjiEntry(date: Date(), kanji: current)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let kanjis = getAvailableKanjis()
        guard !kanjis.isEmpty else {
            completion(Timeline(entries: [KanjiEntry(date: Date(), kanji: Kanji.sample)], policy: .atEnd))
            return
        }
        
        let suite = SharedStorage.defaults
        let rawFreq = suite.string(forKey: SharedStorage.frequencyKey) ?? UpdateFrequencyType.daily.rawValue
        let freqType = UpdateFrequencyType(rawValue: rawFreq) ?? .daily
        let customHours = suite.integer(forKey: SharedStorage.customHoursKey)
        let effectiveHourInterval = freqType.hourInterval(customHours: customHours > 0 ? customHours : 4)
        
        let rawMode = suite.string(forKey: SharedStorage.modeKey) ?? NavigationMode.inOrder.rawValue
        let isRandom = (rawMode == NavigationMode.random.rawValue)
        
        let calendar = Calendar.current
        let now = Date()
        
        let (currentIndex, currentKanji, nextDate) = computeCurrentIndexAndNextDate(from: kanjis, hourInterval: effectiveHourInterval)
        
        var entries: [KanjiEntry] = [
            KanjiEntry(date: now, kanji: currentKanji)
        ]
        
        var runningDate = nextDate
        for step in 1...8 {
            let nextKanji: Kanji
            if isRandom && kanjis.count > 1 {
                let randomIdx = Int.random(in: 0..<kanjis.count)
                nextKanji = kanjis[randomIdx]
            } else {
                let nextIndex = (currentIndex + step) % kanjis.count
                nextKanji = kanjis[nextIndex]
            }
            
            entries.append(KanjiEntry(date: runningDate, kanji: nextKanji))
            
            if let futureDate = calendar.date(byAdding: .hour, value: effectiveHourInterval, to: runningDate) {
                runningDate = futureDate
            } else {
                break
            }
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func getAvailableKanjis() -> [Kanji] {
        guard let url = Bundle.main.url(forResource: "kanji", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let allKanjis = try? JSONDecoder().decode([Kanji].self, from: data),
              !allKanjis.isEmpty else {
            return [Kanji.sample]
        }
        
        let suite = SharedStorage.defaults
        if let preferredLevel = suite.string(forKey: SharedStorage.levelKey) {
            if preferredLevel == "★ Saved", let favs = suite.stringArray(forKey: SharedStorage.favoritesKey), !favs.isEmpty {
                let favSet = Set(favs)
                let filtered = allKanjis.filter { favSet.contains($0.id) }
                if !filtered.isEmpty {
                    return filtered
                }
            } else if preferredLevel != "All", preferredLevel != "★ Saved" {
                let filtered = allKanjis.filter { $0.level.uppercased() == preferredLevel.uppercased() }
                if !filtered.isEmpty {
                    return filtered
                }
            }
        }
        
        return allKanjis
    }
    
    private func computeCurrentIndexAndNextDate(from kanjis: [Kanji], hourInterval: Int) -> (Int, Kanji, Date) {
        guard !kanjis.isEmpty else { return (0, Kanji.sample, Date().addingTimeInterval(3600)) }
        
        let suite = SharedStorage.defaults
        let calendar = Calendar.current
        let now = Date()
        
        let anchorId = suite.string(forKey: SharedStorage.currentKanjiKey) ?? suite.string(forKey: SharedStorage.anchorKanjiKey)
        let anchorTimestamp = suite.double(forKey: SharedStorage.anchorDateKey)
        
        let baseIndex: Int
        if let anchorId = anchorId, let idx = kanjis.firstIndex(where: { $0.id == anchorId }) {
            baseIndex = idx
        } else {
            baseIndex = 0
        }
        
        if hourInterval >= 24 {
            let todayStart = calendar.startOfDay(for: now)
            let anchorDate = anchorTimestamp > 0 ? Date(timeIntervalSince1970: anchorTimestamp) : todayStart
            let daysPassed = max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: anchorDate), to: todayStart).day ?? 0)
            let currentIndex = (baseIndex + daysPassed) % kanjis.count
            let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? now.addingTimeInterval(86400)
            return (currentIndex, kanjis[currentIndex], tomorrowStart)
        } else {
            let anchorDate = anchorTimestamp > 0 ? Date(timeIntervalSince1970: anchorTimestamp) : now
            let secondsPassed = max(0, now.timeIntervalSince(anchorDate))
            let intervalSeconds = Double(hourInterval * 3600)
            let intervalsPassed = Int(secondsPassed / intervalSeconds)
            let currentIndex = (baseIndex + intervalsPassed) % kanjis.count
            
            let secondsIntoCurrent = secondsPassed.truncatingRemainder(dividingBy: intervalSeconds)
            let secondsUntilNext = max(60, intervalSeconds - secondsIntoCurrent)
            let nextDate = now.addingTimeInterval(secondsUntilNext)
            return (currentIndex, kanjis[currentIndex], nextDate)
        }
    }
}

struct KanjiWidgetEntryView: View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
                .widgetBackground(Color.clear)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
                .widgetBackground(Color.clear)
        default:
            HomeScreenWidgetView(entry: entry)
                .widgetBackground(
                    LinearGradient(
                        colors: [
                            Color(red: 0.996, green: 0.984, blue: 0.976),
                            Color(red: 0.985, green: 0.935, blue: 0.942),
                            Color(red: 0.965, green: 0.880, blue: 0.900)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct AccessoryRectangularView: View {
    var entry: Provider.Entry
    
    var reading: String {
        if let on = entry.kanji.onyomi.first, !on.isEmpty {
            return on
        }
        if let kun = entry.kanji.kunyomi.first, !kun.isEmpty {
            return kun
        }
        return entry.kanji.level
    }
    
    var secondaryReading: String? {
        if !entry.kanji.kunyomi.isEmpty && entry.kanji.onyomi.first != nil {
            return entry.kanji.kunyomi.first
        }
        return nil
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(reading)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(entry.kanji.kanji)
                    .font(.system(size: 44, weight: .bold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(minWidth: 46, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.kanji.meanings.joined(separator: ", "))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let example = entry.kanji.examples.first {
                    Text(example.japanese)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if let sec = secondaryReading {
                    Text("Kun: \(sec)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text(entry.kanji.level)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(URL(string: "mikan://kanji?id=\(entry.kanji.id)"))
    }
}

struct AccessoryInlineView: View {
    var entry: Provider.Entry
    
    var body: some View {
        let reading = entry.kanji.onyomi.first ?? entry.kanji.kunyomi.first ?? ""
        let meaning = entry.kanji.meanings.first ?? ""
        ViewThatFits {
            Text("\(entry.kanji.kanji) (\(reading)) • \(meaning)")
            Text("\(entry.kanji.kanji) • \(meaning)")
            Text(entry.kanji.kanji)
        }
        .widgetURL(URL(string: "mikan://kanji?id=\(entry.kanji.id)"))
    }
}

struct AccessoryCircularView: View {
    var entry: Provider.Entry
    
    var reading: String {
        if let on = entry.kanji.onyomi.first, !on.isEmpty {
            return on
        }
        if let kun = entry.kanji.kunyomi.first, !kun.isEmpty {
            return kun
        }
        return entry.kanji.level
    }
    
    var meaning: String {
        entry.kanji.meanings.first ?? ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(reading)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(entry.kanji.kanji)
                .font(.system(size: 38, weight: .bold))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(meaning)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "mikan://kanji?id=\(entry.kanji.id)"))
    }
}

struct HomeScreenWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.kanji.level)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.93, green: 0.61, blue: 0.70), Color(red: 0.87, green: 0.51, blue: 0.61)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color(red: 0.88, green: 0.52, blue: 0.62).opacity(0.20), radius: 3, x: 0, y: 1)
                
                Spacer()
                
                if let reading = entry.kanji.onyomi.first ?? entry.kanji.kunyomi.first {
                    Text(reading)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.55, green: 0.44, blue: 0.48))
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 0)
            
            HStack {
                Spacer()
                Text(entry.kanji.kanji)
                    .font(.system(size: 56, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.22, green: 0.15, blue: 0.19))
                    .shadow(color: Color(red: 0.70, green: 0.40, blue: 0.45).opacity(0.08), radius: 6, x: 0, y: 2)
                Spacer()
            }
            
            Spacer(minLength: 0)
            
            Text(entry.kanji.meanings.prefix(2).joined(separator: ", "))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.25))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 0.93, green: 0.83, blue: 0.84), lineWidth: 1.2)
        )
        .widgetURL(URL(string: "mikan://kanji?id=\(entry.kanji.id)"))
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}

struct KanjiWidget: Widget {
    let kind: String = "KanjiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            KanjiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Kanji")
        .description("Learn a new JLPT Kanji daily on your Home Screen and Lock Screen.")
        .supportedFamilies([
            .systemSmall,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}
