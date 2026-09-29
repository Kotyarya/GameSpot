import XCTest
@testable import Game_Spot

@MainActor
final class AuthLinkCoordinatorTests: XCTestCase {

    func testRouteRecognizesOnlyExactGameSpotAuthPaths() {
        XCTAssertEqual(
            AuthRedirect.route(
                for: URL(
                    string: "gamespot://auth/recovery?code=sensitive"
                )!
            ),
            .passwordRecovery
        )
        XCTAssertEqual(
            AuthRedirect.route(
                for: URL(
                    string: "gamespot://auth/confirmed?code=sensitive"
                )!
            ),
            .emailConfirmation
        )
        XCTAssertNil(
            AuthRedirect.route(
                for: URL(string: "https://example.com/recovery")!
            )
        )
        XCTAssertNil(
            AuthRedirect.route(
                for: URL(string: "gamespot://auth/unknown")!
            )
        )
    }

    func testRecoveryLinkExchangesSessionAndShowsPasswordForm() async {
        let service = AuthLinkExchangeStub()
        let coordinator = AuthLinkCoordinator(service: service)
        let url = URL(
            string: "gamespot://auth/recovery?code=sensitive"
        )!

        let route = await coordinator.handle(url)

        XCTAssertEqual(route, .passwordRecovery)
        XCTAssertEqual(coordinator.state, .passwordRecovery)
        XCTAssertEqual(service.exchangeCallCount, 1)
        XCTAssertTrue(coordinator.showsPasswordRecovery)
    }

    func testExpiredRecoveryLinkShowsGenericError() async {
        let service = AuthLinkExchangeStub(
            error: AuthLinkTestError.secretTokenFailure
        )
        let coordinator = AuthLinkCoordinator(service: service)

        _ = await coordinator.handle(
            URL(string: "gamespot://auth/recovery?code=sensitive")!
        )

        guard case .failed(.passwordRecovery, let message) =
                coordinator.state else {
            return XCTFail("Expected a password recovery failure")
        }

        XCTAssertTrue(message.contains("expired"))
        XCTAssertFalse(message.contains("secret"))
    }

    func testUnrelatedURLIsIgnoredWithoutExchange() async {
        let service = AuthLinkExchangeStub()
        let coordinator = AuthLinkCoordinator(service: service)

        let route = await coordinator.handle(
            URL(string: "https://example.com/path")!
        )

        XCTAssertNil(route)
        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertEqual(service.exchangeCallCount, 0)
    }
}

@MainActor
private final class AuthLinkExchangeStub: AuthLinkExchanging {

    private let error: Error?
    private(set) var exchangeCallCount = 0

    init(error: Error? = nil) {
        self.error = error
    }

    func exchangeAuthSession(
        from url: URL
    ) async throws {
        exchangeCallCount += 1
        if let error {
            throw error
        }
    }
}

private enum AuthLinkTestError: LocalizedError {

    case secretTokenFailure

    var errorDescription: String? {
        "secret token exchange failure"
    }
}
