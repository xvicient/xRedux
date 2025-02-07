import xRedux

// MARK: - Results

extension Hello.Reducer {
    
    func onFetchContentResult(
        state: inout State,
        result: ActionResult<String>
    ) -> Effect<Action> {
        switch result {
        case .success(let content):
            state.viewState = .idle
            state.viewModel.content = content
        case .failure:
            state.viewState = .error
        }
        return .none
    }
}
