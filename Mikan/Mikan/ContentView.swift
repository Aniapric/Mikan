import SwiftUI

struct ContentView: View {
    @ObservedObject var store: KanjiStore
    @State private var isFlipped = false
    @State private var showSettings = false
    
    // Palette colors
    private let sumiInk = Color(red: 0.22, green: 0.15, blue: 0.19)
    private let plumText = Color(red: 0.30, green: 0.20, blue: 0.25)
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
            
            VStack(spacing: 16) {
                // Header with mascot avatar, title, counter and settings
                HStack(spacing: 10) {
                    Image("MikanMascot")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(borderWatercolor, lineWidth: 1.2))
                        .shadow(color: Color(red: 0.70, green: 0.40, blue: 0.45).opacity(0.10), radius: 5, y: 2)

                    Text("Mikan")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(sumiInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Spacer()
                    
                    if !store.filteredKanjis.isEmpty {
                        Text("\(store.currentIndex + 1) / \(store.filteredKanjis.count)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(washiCardBg.opacity(0.95)))
                            .overlay(Capsule().stroke(borderWatercolor, lineWidth: 1))
                            .foregroundColor(sepiaSlate)
                            .shadow(color: Color(red: 0.70, green: 0.40, blue: 0.45).opacity(0.06), radius: 4)
                    }
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(plumText)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(washiCardBg.opacity(0.95)))
                            .overlay(Circle().stroke(borderWatercolor, lineWidth: 1))
                            .shadow(color: Color(red: 0.70, green: 0.40, blue: 0.45).opacity(0.08), radius: 6, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 38)
                
                // Level filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(JLPTLevel.allCases) { level in
                            let isSelected = store.selectedLevel == level
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    isFlipped = false
                                    store.setLevel(level)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(level.rawValue)
                                        .font(.caption.bold())
                                    
                                    if level == .favorites && !store.favoriteIDs.isEmpty {
                                        Text("\(store.favoriteIDs.count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(isSelected ? Color.black.opacity(0.18) : watercolorPink))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? AnyShapeStyle(watercolorPinkWash) : AnyShapeStyle(washiCardBg.opacity(0.9)))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.clear : borderWatercolor, lineWidth: 1)
                                )
                                .foregroundColor(isSelected ? .white : sepiaSlate)
                                .shadow(color: isSelected ? watercolorPink.opacity(0.20) : Color.clear, radius: 4, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Navigation mode and favorites toggle
                HStack {
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: store.navigationMode == .random ? "shuffle" : "arrow.forward")
                                .font(.caption.bold())
                                .foregroundColor(watercolorPink)
                            Text(store.navigationMode.rawValue)
                                .font(.caption.bold())
                            Text("•")
                                .font(.caption2)
                            Text(store.updateFrequencyType == .custom ? "\(store.customHoursInterval)h" : store.updateFrequencyType.rawValue)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(washiCardBg.opacity(0.9)))
                        .overlay(Capsule().stroke(borderWatercolor, lineWidth: 1))
                        .foregroundColor(sepiaSlate)
                        .shadow(color: Color(red: 0.70, green: 0.40, blue: 0.45).opacity(0.06), radius: 4)
                    }
                    
                    Spacer()
                    
                    if !store.filteredKanjis.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                store.toggleFavorite(id: store.currentKanji.id)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: store.isCurrentFavorite ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(store.isCurrentFavorite ? Color(red: 0.94, green: 0.62, blue: 0.28) : sepiaSlate)
                                Text(store.isCurrentFavorite ? "Saved" : "Save")
                                    .font(.caption.bold())
                                    .foregroundColor(store.isCurrentFavorite ? Color(red: 0.85, green: 0.52, blue: 0.20) : sepiaSlate)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(store.isCurrentFavorite ? Color(red: 1.0, green: 0.965, blue: 0.90) : washiCardBg.opacity(0.9))
                            )
                            .overlay(
                                Capsule().stroke(store.isCurrentFavorite ? Color(red: 0.94, green: 0.75, blue: 0.45) : borderWatercolor, lineWidth: 1)
                            )
                            .shadow(color: store.isCurrentFavorite ? Color.orange.opacity(0.15) : Color.clear, radius: 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Flashcard view with 3D flip
                if store.filteredKanjis.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: store.selectedLevel == .favorites ? "star.slash" : "tray")
                            .font(.system(size: 50))
                            .foregroundColor(watercolorPink.opacity(0.7))
                        
                        Text(store.selectedLevel == .favorites ? "No Saved Kanji Yet" : "No Kanji in this Level")
                            .font(.headline.bold())
                            .foregroundColor(sumiInk)
                        
                        Text(store.selectedLevel == .favorites ? "Tap the star icon on any kanji card to save it for review." : "Select another level from the top bar.")
                            .font(.subheadline)
                            .foregroundColor(sepiaSlate)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(height: 460)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(washiCardBg)
                            .shadow(color: Color(red: 0.65, green: 0.35, blue: 0.45).opacity(0.08), radius: 18, y: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(borderWatercolor, lineWidth: 1.2)
                    )
                    .padding(.horizontal, 24)
                } else {
                    ZStack {
                        CardFace(kanji: store.currentKanji, isFront: true)
                            .opacity(isFlipped ? 0 : 1)
                            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                        
                        CardFace(kanji: store.currentKanji, isFront: false)
                            .opacity(isFlipped ? 1 : 0)
                            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                            isFlipped.toggle()
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Bottom navigation controls
                HStack(spacing: 40) {
                    Button(action: {
                        withAnimation {
                            isFlipped = false
                            store.previousKanji()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundColor(store.canGoBack ? sumiInk : sepiaSlate.opacity(0.4))
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(washiCardBg.opacity(store.canGoBack ? 0.95 : 0.45)))
                            .overlay(Circle().stroke(borderWatercolor, lineWidth: 1.2))
                            .shadow(color: Color(red: 0.65, green: 0.35, blue: 0.45).opacity(0.06), radius: 6, y: 2)
                    }
                    .disabled(!store.canGoBack)
                    .opacity(store.canGoBack ? 1.0 : 0.4)
                    
                    Button(action: {
                        withAnimation {
                            isFlipped = false
                            store.nextKanji()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2.bold())
                            .foregroundColor(store.canGoForward ? .white : sepiaSlate.opacity(0.4))
                            .frame(width: 60, height: 60)
                            .background(
                                Circle().fill(
                                    store.canGoForward
                                        ? AnyShapeStyle(watercolorPinkWash)
                                        : AnyShapeStyle(washiCardBg.opacity(0.45))
                                )
                            )
                            .overlay(Circle().stroke(borderWatercolor, lineWidth: 1.2))
                            .shadow(color: store.canGoForward ? watercolorPink.opacity(0.20) : .clear, radius: 6, x: 0, y: 2)
                    }
                    .disabled(!store.canGoForward)
                    .opacity(store.canGoForward ? 1.0 : 0.4)
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store)
        }
    }
}

// Flashcard front and back content
struct CardFace: View {
    let kanji: Kanji
    let isFront: Bool
    
    private let sumiInk = Color(red: 0.22, green: 0.15, blue: 0.19)
    private let sepiaSlate = Color(red: 0.55, green: 0.44, blue: 0.48)
    private let watercolorPink = Color(red: 0.88, green: 0.52, blue: 0.62)
    private let watercolorPinkWash = LinearGradient(
        colors: [Color(red: 0.93, green: 0.61, blue: 0.70), Color(red: 0.87, green: 0.51, blue: 0.61)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let borderWatercolor = Color(red: 0.93, green: 0.83, blue: 0.84)
    private let washiCardBg = Color(red: 0.996, green: 0.990, blue: 0.985)
    private let miniCardBg = Color(red: 0.992, green: 0.965, blue: 0.970)
    
    var body: some View {
        VStack(spacing: 20) {
            if isFront {
                // Front side: kanji character, level badge and stroke count
                HStack {
                    Text(kanji.level)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(watercolorPinkWash)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(color: watercolorPink.opacity(0.20), radius: 3, y: 2)
                    
                    Spacer()
                    
                    Text("\(kanji.strokes) strokes")
                        .font(.caption.bold())
                        .foregroundColor(sepiaSlate)
                }
                
                Spacer()
                
                Text(kanji.kanji)
                    .font(.system(size: 120, weight: .bold, design: .serif))
                    .foregroundColor(sumiInk)
                    .shadow(color: Color(red: 0.70, green: 0.40, blue: 0.45).opacity(0.08), radius: 8, x: 0, y: 4)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption2)
                    Text("Tap to flip for meaning & readings")
                        .font(.caption.bold())
                }
                .foregroundColor(sepiaSlate)
            } else {
                // Back side: meanings, readings, and examples
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MEANING")
                                .font(.caption2.bold())
                                .foregroundColor(watercolorPink)
                                .tracking(1.4)
                            
                            Text(kanji.meanings.joined(separator: ", "))
                                .font(.title3.bold())
                                .foregroundColor(sumiInk)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Divider().background(borderWatercolor)
                        
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("KUNYOMI (Japanese)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(watercolorPink)
                                
                                Text(kanji.kunyomi.isEmpty ? "-" : kanji.kunyomi.joined(separator: ", "))
                                    .font(.subheadline.bold())
                                    .foregroundColor(sumiInk)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(miniCardBg)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderWatercolor, lineWidth: 1)
                            )
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ONYOMI (Chinese)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(watercolorPink)
                                
                                Text(kanji.onyomi.isEmpty ? "-" : kanji.onyomi.joined(separator: ", "))
                                    .font(.subheadline.bold())
                                    .foregroundColor(sumiInk)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(miniCardBg)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderWatercolor, lineWidth: 1)
                            )
                        }
                        
                        Divider().background(borderWatercolor)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EXAMPLES & VOCABULARY")
                                .font(.caption2.bold())
                                .foregroundColor(watercolorPink)
                                .tracking(1.4)
                            
                            ForEach(kanji.examples, id: \.japanese) { example in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(example.japanese)
                                        .font(.body.bold())
                                        .foregroundColor(sumiInk)
                                    Text(example.english)
                                        .font(.caption)
                                        .foregroundColor(sepiaSlate)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(miniCardBg.opacity(0.85))
                                )
                            }
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
        .padding(28)
        .frame(height: 500)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(washiCardBg)
                .shadow(color: Color(red: 0.65, green: 0.35, blue: 0.45).opacity(0.08), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(borderWatercolor, lineWidth: 1.2)
        )
    }
}

#Preview {
    ContentView(store: KanjiStore())
}
