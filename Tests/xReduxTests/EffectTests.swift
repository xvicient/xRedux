import Combine
import Testing

@testable import xRedux

@MainActor
struct EffectTests {

    @Test("Mapping a none effect stays none")
    func testMapNone() {
        let effect: Effect<Int> = .none
        let mapped = effect.map(String.init)

        guard case .none = mapped else {
            Issue.record("Expected .none")
            return
        }
    }

    @Test("Mapping a publish effect transforms its emitted action")
    func testMapPublish() async {
        let effect: Effect<Int> = .publish(Just(1).eraseToAnyPublisher())
        let mapped = effect.map(String.init)

        guard case .publish(let publisher) = mapped else {
            Issue.record("Expected .publish")
            return
        }

        let received = await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = publisher.sink { value in
                continuation.resume(returning: value)
                cancellable?.cancel()
            }
        }

        #expect(received == "1")
    }

    @Test("Mapping a task effect transforms actions sent through it")
    func testMapTask() async {
        let effect: Effect<Int> = .task { send in
            await send(1)
        }
        let mapped = effect.map(String.init)

        guard case .task(let task) = mapped else {
            Issue.record("Expected .task")
            return
        }

        var received: String?
        await task { action in
            received = action
        }

        #expect(received == "1")
    }
}
