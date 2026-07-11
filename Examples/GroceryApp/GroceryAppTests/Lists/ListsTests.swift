import Testing
import xRedux
import xReduxTest

@testable import GroceryApp

@MainActor
struct ListsTests {

    private typealias ListsStore<R: Reducer> = TestStore<R.State, R.Action>

    private enum UseCaseError: Error {
        case error
    }

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

        await store.send(.shared(.didTapItem(list.id))) {
            $0.viewState == .idle && $0.items[0].completed == list.completed
        }

        await store.receive(.shared(.voidResult(useCaseMock.updateListResult))) {
            $0.viewState == .idle
        }
    }

    @Test("Did select list leaves state untouched")
    mutating func testOnDidSelectList() async {
        givenASuccessListsFetch()

        await store.send(.shared(.onAppear)) {
            $0.viewState == .loading
        }

        await store.receive(.shared(.fetchItemsResult(useCaseMock.fetchListsResult))) {
            $0.viewState == .idle
        }

        await store.send(.didSelectList(listsMock[0].id)) {
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
        useCaseMock.fetchListsResult = .failure(UseCaseError.error)
    }
}
