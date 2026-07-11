import SwiftUI

@main
struct GroceryApp: App {
    var body: some Scene {
        WindowGroup {
            ListsBuilder.makeLists()
        }
    }
}
