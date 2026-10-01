import SwiftUI

struct ContentView: View {
    @ObservedObject var store: KanjiStore
    @State private var isFlipped = false
    
    // Theme palette
    private let textDark = Color(red: 0.18, green: 0.18, blue: 0.20)
    private let textGray = Color(red: 0.45, green: 0.45, blue: 0.48)
    private let pinkAccent = Color(red: 0.85, green: 0.45, blue: 0.55)
    private let cardBackground = Color(red: 0.99, green: 0.98, blue: 0.97)
    private let cardBorder = Color(red: 0.90, green: 0.86, blue: 0.86)
    
    var body: some View {
        ZStack {
            // Soft paper background wash
            Color(red: 0.97, green: 0.96, blue: 0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header with title and counter
                HStack {
                    Text("Daily Kanji")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(textDark)
                    
                    Spacer()
                    
                    if !store.filteredKanjis.isEmpty {
                        Text("\(store.currentIndex + 1) / \(store.filteredKanjis.count)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(cardBackground))
                            .overlay(Capsule().stroke(cardBorder, lineWidth: 1))
                            .foregroundColor(textGray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // JLPT level selector
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
                                Text(level.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? pinkAccent : cardBackground)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Color.clear : cardBorder, lineWidth: 1)
                                    )
                                    .foregroundColor(isSelected ? .white : textGray)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Main flashcard
                cardView
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // Bottom navigation controls
                HStack(spacing: 24) {
                    // Previous button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isFlipped = false
                            store.previousKanji()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(store.canGoBack ? textDark : Color.gray.opacity(0.4))
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(cardBackground))
                            .overlay(Circle().stroke(cardBorder, lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                    }
                    .disabled(!store.canGoBack)
                    
                    // Flip button
                    Button(action: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            isFlipped.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .bold))
                            Text(isFlipped ? "Show Kanji" : "Reveal Meaning")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .frame(height: 54)
                        .background(Capsule().fill(pinkAccent))
                        .shadow(color: pinkAccent.opacity(0.25), radius: 8, y: 3)
                    }
                    
                    // Next button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isFlipped = false
                            store.nextKanji()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(store.canGoForward ? textDark : Color.gray.opacity(0.4))
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(cardBackground))
                            .overlay(Circle().stroke(cardBorder, lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                    }
                    .disabled(!store.canGoForward)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    // Interactive 3D card view
    private var cardView: some View {
        ZStack {
            if isFlipped {
                cardBack
            } else {
                cardFront
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                isFlipped.toggle()
            }
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
    }
    
    // Front side: kanji character and stroke count
    private var cardFront: some View {
        VStack(spacing: 16) {
            HStack {
                Text(store.currentKanji.level)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(pinkAccent.opacity(0.15)))
                    .foregroundColor(pinkAccent)
                
                Spacer()
                
                Text("\(store.currentKanji.strokes) strokes")
                    .font(.caption)
                    .foregroundColor(textGray)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            Spacer()
            
            Text(store.currentKanji.kanji)
                .font(.system(size: 110, weight: .light, design: .serif))
                .foregroundColor(textDark)
            
            Spacer()
            
            Text("Tap to flip")
                .font(.caption)
                .foregroundColor(textGray.opacity(0.7))
                .padding(.bottom, 20)
        }
    }
    
    // Back side: meanings and pronunciations
    private var cardBack: some View {
        VStack(spacing: 14) {
            // English meanings
            VStack(spacing: 4) {
                Text(store.currentKanji.meanings.joined(separator: ", "))
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(textDark)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            
            Divider()
                .padding(.horizontal, 30)
            
            // Readings: Kunyomi on left, Onyomi on right
            HStack(alignment: .top, spacing: 16) {
                // Kunyomi
                VStack(alignment: .leading, spacing: 4) {
                    Text("KUN")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(pinkAccent)
                    
                    if store.currentKanji.kunyomi.isEmpty {
                        Text("-")
                            .font(.subheadline)
                            .foregroundColor(textGray)
                    } else {
                        ForEach(store.currentKanji.kunyomi, id: \.self) { kun in
                            Text(kun)
                                .font(.subheadline)
                                .foregroundColor(textDark)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Onyomi
                VStack(alignment: .trailing, spacing: 4) {
                    Text("ON")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(pinkAccent)
                    
                    if store.currentKanji.onyomi.isEmpty {
                        Text("-")
                            .font(.subheadline)
                            .foregroundColor(textGray)
                    } else {
                        ForEach(store.currentKanji.onyomi, id: \.self) { on in
                            Text(on)
                                .font(.subheadline)
                                .foregroundColor(textDark)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 28)
            
            Spacer()
            
            // Word examples
            if !store.currentKanji.examples.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(store.currentKanji.examples.prefix(2), id: \.self) { ex in
                        HStack {
                            Text(ex.japanese)
                                .font(.caption.bold())
                                .foregroundColor(textDark)
                            Text("—")
                                .font(.caption)
                                .foregroundColor(textGray)
                            Text(ex.english)
                                .font(.caption)
                                .foregroundColor(textGray)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: 1.0, z: 0.0))
    }
}
