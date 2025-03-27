@testable import GroceryApp

struct ItemMock {    
    static var items: [Item] {
        Array(repeating: Item(name: "Test item", completed: true), count: 10)
    }
}
