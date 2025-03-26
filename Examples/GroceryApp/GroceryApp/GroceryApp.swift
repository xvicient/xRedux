import SwiftUI

@main
struct GroceryApp: App {
    var body: some Scene {
        WindowGroup {
            HomeBuilder.makeHome()
        }
    }
}
