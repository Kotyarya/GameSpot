import XCTest
@testable import Game_Spot

final class ConfigurationSecurityTests: XCTestCase {

    func testSupabaseConfigurationUsesHTTPSAndPublishableKey() {
        XCTAssertEqual(
            AppConfiguration.supabaseURL.scheme,
            "https"
        )
        XCTAssertTrue(
            AppConfiguration.supabasePublishableKey
                .hasPrefix("sb_publishable_")
        )
        XCTAssertFalse(
            AppConfiguration.supabasePublishableKey
                .hasPrefix("sb_secret_")
        )
    }
}
