import Testing
import xRedux
import xReduxTest

@testable import GroceryApp

@MainActor
struct ItemsTests {

    private typealias ItemsStore<R: Reducer> = TestStore<R.State, R.Action>

    private enum UseCaseError: Error {
        case error
    }

    private lazy var store: ItemsStore<ToggleableListReducer<ItemsUseCaseMock>> = {
        TestStore(
            initialState: .init(),
            reducer: ToggleableListReducer(useCase: useCaseMock)
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

        await store.send(.didTapItem(item.id)) {
            $0.viewState == .idle && $0.items[0].completed == item.completed
        }

        await store.receive(.voidResult(useCaseMock.updateItemResult)) {
            $0.viewState == .idle
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
        useCaseMock.fetchItemsResult = .failure(UseCaseError.error)
    }
}
