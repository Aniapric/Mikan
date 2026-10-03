import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: KanjiStore
    @Environment(\.dismiss) private var dismiss
    
    // Palette colors
    private let sumiInk = Color(red: 0.22, green: 0.15, blue: 0.19)
    private let sepiaSlate = Color(red: 0.55, green: 0.44, blue: 0.48)
    private let watercolorPink = Color(red: 0.88, green: 0.52, blue: 0.62)
    private let watercolorPinkWash = LinearGradient(
        colors: [Color(red: 0.93, green: 0.61, blue: 0.70), Color(red: 0.87, green: 0.51, blue: 0.61)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let washiCardBg = Color(red: 0.996, green: 0.990, blue: 0.985)
    private let borderWatercolor = Color(red: 0.93, green: 0.83, blue: 0.84)
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.996, green: 0.984, blue: 0.976),
                        Color(red: 0.988, green: 0.945, blue: 0.948),
                        Color(red: 0.972, green: 0.900, blue: 0.915),
                        Color(red: 0.955, green: 0.855, blue: 0.885)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        navigationModeSection
                        jlptLevelSection
                        widgetFrequencySection
                        statsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.headline.bold())
                            .foregroundColor(watercolorPink)
                    }
                }
            }
        }
    }
    
    // Learning mode section (in order vs random)
    private var navigationModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "LEARNING MODE", icon: "arrow.triangle.swap")
            
            VStack(spacing: 8) {
                ForEach(NavigationMode.allCases) { mode in
                    let isSelected = store.navigationMode == mode
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            store.setNavigationMode(mode)
                        }
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: mode == .inOrder ? "arrow.forward.circle.fill" : "shuffle.circle.fill")
                                .font(.title2)
                                .foregroundColor(isSelected ? watercolorPink : sepiaSlate.opacity(0.5))
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(mode == .inOrder ? "In Order (Sequential)" : "Random (Shuffle)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(sumiInk)
                                
                                Text(mode == .inOrder ? "Study kanji step-by-step in curriculum order." : "Shuffle kanji to boost active recall.")
                                    .font(.caption)
                                    .foregroundColor(sepiaSlate)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(watercolorPink)
                                    .font(.headline)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? Color(red: 0.996, green: 0.955, blue: 0.965) : washiCardBg.opacity(0.65))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? watercolorPink.opacity(0.45) : borderWatercolor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(washiCardBg)
                .shadow(color: Color(red: 0.65, green: 0.35, blue: 0.45).opacity(0.08), radius: 14, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderWatercolor, lineWidth: 1)
        )
    }
    
    // JLPT level selector grid
    private var jlptLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "ACTIVE JLPT LEVEL", icon: "graduationcap.fill")
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 85), spacing: 8)], spacing: 8) {
                ForEach(JLPTLevel.allCases) { level in
                    let isSelected = store.selectedLevel == level
                    let count = countForLevel(level)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            store.setLevel(level)
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(level.rawValue)
                                .font(.caption.bold())
                                .foregroundColor(isSelected ? .white : sumiInk)
                            
                            Text("\(count)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(isSelected ? .white.opacity(0.9) : sepiaSlate)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? AnyShapeStyle(watercolorPinkWash) : AnyShapeStyle(washiCardBg.opacity(0.6)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.clear : borderWatercolor, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? watercolorPink.opacity(0.20) : Color.clear, radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(washiCardBg)
                .shadow(color: Color(red: 0.65, green: 0.35, blue: 0.45).opacity(0.08), radius: 14, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderWatercolor, lineWidth: 1)
        )
    }
    
    // Widget update frequency settings
    private var widgetFrequencySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "WIDGET ROTATION FREQUENCY", icon: "clock.badge.checkmark.fill")
            
            Text("How often the widget updates with a new kanji:")
                .font(.caption)
                .foregroundColor(sepiaSlate)
            
            VStack(spacing: 8) {
                ForEach(UpdateFrequencyType.allCases) { freq in
                    let isSelected = store.updateFrequencyType == freq
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            store.setUpdateFrequency(freq)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: freq.icon)
                                .font(.headline)
                                .foregroundColor(isSelected ? watercolorPink : sepiaSlate.opacity(0.7))
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(freq.rawValue)
                                    .font(.subheadline.bold())
                                    .foregroundColor(sumiInk)
                                
                                Text(freq.subtitle)
                                    .font(.caption2)
                                    .foregroundColor(sepiaSlate)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(watercolorPink)
                                    .font(.headline)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? Color(red: 0.996, green: 0.955, blue: 0.965) : washiCardBg.opacity(0.65))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? watercolorPink.opacity(0.45) : borderWatercolor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if store.updateFrequencyType == .custom {
                VStack(spacing: 14) {
                    Divider().background(borderWatercolor)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Exact Interval")
                                .font(.caption.bold())
                                .foregroundColor(sumiInk)
                            
                            let dailyCount = 24 / max(1, store.customHoursInterval)
                            Text("Every \(store.customHoursInterval) \(store.customHoursInterval == 1 ? "hour" : "hours")  •  ~\(dailyCount) kanji / day")
                                .font(.caption2.bold())
                                .foregroundColor(watercolorPink)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                if store.customHoursInterval > 1 {
                                    store.setCustomHoursInterval(store.customHoursInterval - 1)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(store.customHoursInterval > 1 ? watercolorPink : sepiaSlate.opacity(0.3))
                            }
                            .disabled(store.customHoursInterval <= 1)
                            
                            Text("\(store.customHoursInterval)h")
                                .font(.system(size: 17, weight: .bold, design: .serif))
                                .foregroundColor(sumiInk)
                                .frame(minWidth: 32)
                            
                            Button(action: {
                                if store.customHoursInterval < 24 {
                                    store.setCustomHoursInterval(store.customHoursInterval + 1)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(store.customHoursInterval < 24 ? watercolorPink : sepiaSlate.opacity(0.3))
                            }
                            .disabled(store.customHoursInterval >= 24)
                        }
                    }
                    .padding(.top, 4)
                    
                    HStack(spacing: 8) {
                        ForEach([2, 3, 4, 8, 12], id: \.self) { hours in
                            let isCur = store.customHoursInterval == hours
                            Button(action: {
                                store.setCustomHoursInterval(hours)
                            }) {
                                Text("\(hours)h")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(isCur ? AnyShapeStyle(watercolorPinkWash) : AnyShapeStyle(washiCardBg))
                                    )
                                    .overlay(
                                        Capsule().stroke(isCur ? Color.clear : borderWatercolor, lineWidth: 1)
                                    )
                                    .foregroundColor(isCur ? .white : sepiaSlate)
                                    .shadow(color: isCur ? watercolorPink.opacity(0.20) : Color.clear, radius: 3)
                            }
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.996, green: 0.955, blue: 0.965))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderWatercolor, lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(washiCardBg)
                .shadow(color: Color(red: 0.65, green: 0.35, blue: 0.45).opacity(0.08), radius: 14, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderWatercolor, lineWidth: 1)
        )
    }
    
    // Study progress and collection stats
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "COLLECTION PROGRESS", icon: "chart.bar.fill")
            
            HStack(spacing: 12) {
                statCard(title: "Total Kanji", value: "\(store.allKanjis.count)", icon: "character.book.closed.fill")
                statCard(title: "Saved", value: "\(store.favoriteIDs.count)", icon: "star.fill")
                statCard(title: "Current Level", value: store.selectedLevel.rawValue, icon: "bookmark.fill")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(washiCardBg)
                .shadow(color: Color(red: 0.65, green: 0.35, blue: 0.45).opacity(0.08), radius: 14, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderWatercolor, lineWidth: 1)
        )
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(watercolorPink)
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(watercolorPink)
                .tracking(1.2)
        }
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(watercolorPink)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(sumiInk)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(sepiaSlate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(washiCardBg.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderWatercolor, lineWidth: 1)
        )
    }
    
    // Helper to count kanji per level
    private func countForLevel(_ level: JLPTLevel) -> Int {
        switch level {
        case .all:
            return store.allKanjis.count
        case .favorites:
            return store.favoriteIDs.count
        case .n5, .n4, .n3, .n2, .n1:
            return store.allKanjis.filter { $0.level.uppercased() == level.rawValue.uppercased() }.count
        }
    }
}
