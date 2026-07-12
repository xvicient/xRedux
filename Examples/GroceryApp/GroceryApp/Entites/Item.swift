import Foundation

struct Item: ToggleableItem {
    let id = UUID()
    let name: String
    var completed: Bool
}
