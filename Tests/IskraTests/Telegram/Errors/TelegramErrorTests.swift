@testable import Iskra
import Foundation
import Testing

@Suite("Telegram Error Tests")
struct TelegramErrorTests {

    @Test("Test authentication failed error")
    func testAuthenticationFailedErrorContainsKeyword() {
        // Arrange
        let sut = TelegramError.authenticationFailed

        // Act
        let description = sut.errorDescription

        // Assert
        #expect(description?.contains("authentication") == true)
    }

    @Test("Test configuration missing error contains key")
    func testConfigurationMissingErrorContainsKey() {
        // Arrange
        let sut = TelegramError.configurationMissing("BOT_TOKEN")

        // Act
        let description = sut.errorDescription

        // Assert
        #expect(description?.contains("BOT_TOKEN") == true)
    }

    @Test("Test API error with description contains both values")
    func testAPIErrorWithDescriptionContainsBoth() {
        // Arrange
        let sut = TelegramError.apiError(statusCode: 400, description: "Bad Request")

        // Act
        let description = sut.errorDescription

        // Assert
        #expect(description?.contains("400") == true)
        #expect(description?.contains("Bad Request") == true)
    }

    @Test("Test API error without description shows unknown")
    func testAPIErrorWithoutDescriptionShowsUnknown() {
        // Arrange
        let sut = TelegramError.apiError(statusCode: 500, description: nil)

        // Act
        let description = sut.errorDescription

        // Assert
        #expect(description?.contains("500") == true)
        #expect(description?.contains("Unknown") == true)
    }

    @Test("Test invalid update payload shows invalid")
    func testInvalidUpdatePayloadShowsInvalid() {
        // Arrange
        struct StubError: Error {}
        let sut = TelegramError.invalidUpdatePayload(underlyingError: StubError())

        // Act
        let description = sut.errorDescription

        // Assert
        #expect(description?.contains("Invalid") == true)
    }

    @Test("Test network error shows network")
    func testNetworkErrorShowsNetwork() {
        // Arrange
        struct StubError: Error {}
        let sut = TelegramError.networkError(underlyingError: StubError())

        // Act
        let description = sut.errorDescription

        // Assert
        #expect(description?.contains("Network") == true)
    }
}
