@testable import GroceryApp

struct ItemMock {
    static var items: [Item] {
        (0..<10).map { _ in Item(name: "Test item", completed: true) }
    }
}
