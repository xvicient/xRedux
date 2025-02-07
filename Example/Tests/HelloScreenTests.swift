import Testing
import xRedux
import xReduxTest

@MainActor
struct HelloScreenTests {

    private typealias HelloStore<R: Reducer> = TestStore<R.State, R.Action>
    private enum TestError: Error {
        case resultError
    }
    
    private lazy var store: HelloStore<Hello.Reducer> = {
        TestStore(
            initialState: .init(),
            reducer: Hello.Reducer()
        )
    }()
    
    private let successContentMock: String = "Hello"
    
    @Test("Fetch content success after view appears")
    mutating func testDidViewAppearAndFetchContent_Success() async {
        let result = givenASuccessContentFetch()
        
        await store.send(.onViewAppear) {
            $0.viewState == .loading
        }
        
        await store.receive(.fetchContentResult(result)) { [successContentMock] in
            $0.viewState == .idle && $0.viewModel.content == successContentMock
        }
    }
    
    @Test("Fetch content fails after view appears")
    mutating func testDidViewAppearAndFetchContent_Failure() async {
        let result = givenAFailureContentFetch()
        
        await store.send(.onViewAppear) {
            $0.viewState == .loading
        }
        
        await store.receive(.fetchContentResult(result)) {
            $0.viewState == .error
        }
    }
    
    @Test("Fetch users fails after view appears")
    mutating func testDidTapSayHello() async {
        let result = givenAFailureContentFetch()
        
        await store.send(.didTapSayHello) {
            $0.viewModel.content == "Hello!"
        }
    }
}

extension HelloScreenTests {
    fileprivate func givenASuccessContentFetch() -> ActionResult<String> {
        .success(successContentMock)
    }
    
    fileprivate func givenAFailureContentFetch() -> ActionResult<String> {
        .failure(TestError.resultError)
    }
}
