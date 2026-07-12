import Testing

@testable import GroceryApp

@MainActor
struct CoordinatorTests {

    @Test("Push appends the list to the path")
    func testPush() {
        let coordinator = Coordinator()
        let list = GroceryListMock.lists[0]

        coordinator.push(list)

        #expect(coordinator.path == [list])
    }
}
