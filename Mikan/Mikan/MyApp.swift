import SwiftUI

@main
struct MyApp: App {
    @StateObject private var store = KanjiStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .onOpenURL { url in
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                       let queryItems = components.queryItems,
                       let idItem = queryItems.first(where: { $0.name == "id" }),
                       let kanjiId = idItem.value {
                        withAnimation {
                            store.selectKanji(byId: kanjiId)
                        }
                    }
                }
        }
    }
}
