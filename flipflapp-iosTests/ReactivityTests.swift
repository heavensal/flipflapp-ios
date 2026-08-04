import XCTest
@testable import flipflapp_ios

final class PushNavigationTests: XCTestCase {
    func testParsesFriendshipsPath() {
        XCTAssertEqual(PushNavigationPath.destination(from: "/friendships"), .friends)
    }

    func testParsesEventPath() {
        XCTAssertEqual(PushNavigationPath.destination(from: "events/42"), .events(EventID(rawValue: 42)))
    }

    func testParsesUserInfoPath() {
        let destination = PushNavigationPath.destination(from: ["path": "/events/7"])
        XCTAssertEqual(destination, .events(EventID(rawValue: 7)))
    }

    func testParsesFriendshipRequestedKind() {
        let destination = PushNavigationPath.destination(from: ["kind": "friendship_requested"])
        XCTAssertEqual(destination, .friends)
    }
}

@MainActor
final class DebouncedTaskTests: XCTestCase {
    func testDebounceDelaysExecution() async {
        let debouncer = DebouncedTask()
        let clock = ContinuousClock()
        let start = clock.now

        debouncer.schedule(delay: .milliseconds(50)) {
            // no-op
        }
        try? await Task.sleep(for: .milliseconds(80))

        let elapsed = start.duration(to: clock.now)
        XCTAssertGreaterThanOrEqual(elapsed, .milliseconds(45))
    }

    func testCancelPreventsExecution() async {
        let debouncer = DebouncedTask()
        final class Flag: @unchecked Sendable {
            var value = false
        }
        let flag = Flag()

        debouncer.schedule(delay: .milliseconds(100)) {
            flag.value = true
        }
        debouncer.cancel()
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertFalse(flag.value)
    }
}
