import Testing
import xRedux
import xReduxTest

@testable import GroceryApp

@MainActor
struct ListsTests {

    private typealias ListsStore<R: Reducer> = TestStore<R.State, R.Action>

    private lazy var store: ListsStore<ListsReducer<ListsUseCaseMock>> = {
        TestStore(
            initialState: .init(),
            reducer: ListsReducer(useCase: useCaseMock)
        )
    }()
    private var useCaseMock = ListsUseCaseMock()
    private let listsMock = GroceryListMock.lists

    @Test("Fetch content succeed after view appears")
    mutating func testOnAppearAndFetchLists_Success() async {
        givenASuccessListsFetch()

        await store.send(.shared(.onAppear)) {
            $0.viewState == .loading
        }

        await store.receive(.shared(.fetchItemsResult(useCaseMock.fetchListsResult))) { [listsMock] in
            $0.viewState == .idle && $0.items == listsMock
        }
    }

    @Test("Fetch content fails after view appears")
    mutating func testOnAppearAndFetchLists_Failure() async {
        givenAFailureListsFetch()

        await store.send(.shared(.onAppear)) {
            $0.viewState == .loading
        }

        await store.receive(.shared(.fetchItemsResult(useCaseMock.fetchListsResult))) {
            $0.viewState == .error && $0.items.isEmpty
        }
    }

    @Test("Did tap list toggles it as completed")
    mutating func testOnDidTapItemTogglesList() async {
        givenASuccessListsFetch()

        var list = listsMock[0]
        list.completed.toggle()

        await store.send(.shared(.onAppear)) {
            $0.viewState == .loading
        }

        await store.receive(.shared(.fetchItemsResult(useCaseMock.fetchListsResult))) {
            $0.viewState == .idle
        }

        // The toggle is optimistic and fire-and-forget: no result action follows.
        await store.send(.shared(.didTapItem(list.id))) {
            $0.viewState == .idle && $0.items[0].completed == list.completed
        }
    }

    @Test("Re-appearing after a successful fetch does not re-fetch and lose local changes")
    mutating func testOnAppearAgainDoesNotRefetch() async {
        givenASuccessListsFetch()

        var list = listsMock[0]
        list.completed.toggle()

        await store.send(.shared(.onAppear)) {
            $0.viewState == .loading
        }

        await store.receive(.shared(.fetchItemsResult(useCaseMock.fetchListsResult))) {
            $0.viewState == .idle
        }

        await store.send(.shared(.didTapItem(list.id))) {
            $0.viewState == .idle && $0.items[0].completed == list.completed
        }

        // Simulates popping back to the root, which re-sends onAppear.
        await store.send(.shared(.onAppear)) {
            $0.viewState == .idle && $0.items[0].completed == list.completed
        }
    }

    @Test("Did tap share leaves state untouched")
    mutating func testOnDidTapShare() async {
        givenASuccessListsFetch()

        await store.send(.shared(.onAppear)) {
            $0.viewState == .loading
        }

        await store.receive(.shared(.fetchItemsResult(useCaseMock.fetchListsResult))) {
            $0.viewState == .idle
        }

        await store.send(.didTapShare(listsMock[0].id)) {
            $0.viewState == .idle
        }
    }

}

extension ListsTests {
    fileprivate func givenASuccessListsFetch() {
        useCaseMock.fetchListsResult = .success(
            listsMock
        )
    }

    fileprivate func givenAFailureListsFetch() {
        useCaseMock.fetchListsResult = .failure(ListsError.fetchFailed)
    }
}
