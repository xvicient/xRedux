@testable import GroceryApp

struct GroceryListMock {
    static var lists: [GroceryList] {
        (0..<3).map { _ in GroceryList(name: "Test list", completed: true) }
    }
}
