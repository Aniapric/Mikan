import SwiftUI

@main
struct MyApp: App {
    @StateObject private var store = KanjiStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
