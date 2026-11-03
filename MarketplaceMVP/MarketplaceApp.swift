import SwiftUI

@main
struct MarketplaceApp: App {
    @StateObject private var store = ProductStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
