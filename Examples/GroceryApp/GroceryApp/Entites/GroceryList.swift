import Foundation

struct GroceryList: ToggleableItem, Hashable {
    let id = UUID()
    let name: String
    var completed: Bool
}
