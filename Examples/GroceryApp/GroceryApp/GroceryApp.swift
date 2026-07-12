import SwiftUI

@main
struct GroceryApp: App {
    var body: some Scene {
        WindowGroup {
            CoordinatorView(coordinator: Coordinator())
        }
    }
}
