import Testing
import xRedux
import xReduxTest

@testable import GroceryApp

@MainActor
struct ItemsTests {

    private typealias ItemsStore<R: Reducer> = TestStore<R.State, R.Action>

    private lazy var store: ItemsStore<ToggleableListReducer<ItemsUseCaseMock>> = {
        TestStore(
            initialState: .init(),
            reducer: ToggleableListReducer(useCase: useCaseMock)
        )
    }()
    private lazy var itemsReducerStore: ItemsStore<ItemsReducer<ItemsUseCaseMock>> = {
        TestStore(
            initialState: .init(listName: "Test list"),
            reducer: ItemsReducer(useCase: useCaseMock)
        )
    }()
    private var useCaseMock = ItemsUseCaseMock()
    private let itemsMock = ItemMock.items

    @Test("Fetch content succeed after view appears")
    mutating func testOnAppearAndFetchItems_Success() async {
        givenASuccessItemsFetch()

        await store.send(.onAppear) {
            $0.viewState == .loading
        }

        await store.receive(.fetchItemsResult(useCaseMock.fetchItemsResult)) { [itemsMock] in
            $0.viewState == .idle && $0.items == itemsMock
        }
    }

    @Test("Fetch content fails after view appears")
    mutating func testOnAppearAndFetchItems_Failure() async {
        givenAFailureItemsFetch()

        await store.send(.onAppear) {
            $0.viewState == .loading
        }

        await store.receive(.fetchItemsResult(useCaseMock.fetchItemsResult)) {
            $0.viewState == .error && $0.items.isEmpty
        }
    }

    @Test("Did tap item toggles item")
    mutating func testOnDidTapItemTogglesItem() async {
        givenASuccessItemsFetch()

        var item = itemsMock[0]
        item.completed.toggle()

        await store.send(.onAppear) {
            $0.viewState == .loading
        }

        await store.receive(.fetchItemsResult(useCaseMock.fetchItemsResult)) {
            $0.viewState == .idle
        }

        // The toggle is optimistic and fire-and-forget: no result action follows.
        await store.send(.didTapItem(item.id)) {
            $0.viewState == .idle && $0.items[0].completed == item.completed
        }
    }

    @Test("Did delete item removes it from state")
    mutating func testOnDidDeleteItem() async {
        givenASuccessItemsFetch()

        let item = itemsMock[0]

        await itemsReducerStore.send(.shared(.onAppear)) {
            $0.shared.viewState == .loading
        }

        await itemsReducerStore.receive(.shared(.fetchItemsResult(useCaseMock.fetchItemsResult))) { [itemsMock] in
            $0.shared.viewState == .idle && $0.shared.items == itemsMock
        }

        // Deletion is optimistic and fire-and-forget: no result action follows.
        await itemsReducerStore.send(.didDeleteItem(item.id)) {
            !$0.shared.items.contains(item)
        }
    }

}

extension ItemsTests {
    fileprivate func givenASuccessItemsFetch() {
        useCaseMock.fetchItemsResult = .success(
            itemsMock
        )
    }

    fileprivate func givenAFailureItemsFetch() {
        useCaseMock.fetchItemsResult = .failure(ItemsError.fetchFailed)
    }
}
