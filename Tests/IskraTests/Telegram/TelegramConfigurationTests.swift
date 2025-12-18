@testable import Iskra
import Testing

@Suite("Telegram Configuration Tests")
struct TelegramConfigurationTests {

    @Test("Test mode raw values match expected")
    func testModeRawValuesMatchExpected() {
        // Assert
        #expect(TelegramBotMode.webhook.rawValue == "webhook")
        #expect(TelegramBotMode.polling.rawValue == "polling")
    }

    @Test("Test default webhook path is correct")
    func testDefaultWebhookPathIsCorrect() {
        // Assert
        #expect(TelegramConfiguration.defaultWebhookPath == "/webhook/telegram")
    }

    @Test("Test init with all parameters stores values")
    func testInitWithAllParametersStoresValues() {
        // Arrange & Act
        let sut = TelegramConfiguration(
            botToken: "test_token",
            adminChatId: -123456789,
            mode: .polling,
            webhookSecretToken: "secret123",
            webhookURL: "https://example.com/webhook/telegram",
            deleteWebhookOnStart: false,
            pollingTimeout: 25,
            pollingLimit: 50
        )

        // Assert
        #expect(sut.botToken == "test_token")
        #expect(sut.mode == .polling)
        #expect(sut.webhookSecretToken == "secret123")
        #expect(sut.webhookURL == "https://example.com/webhook/telegram")
        #expect(sut.deleteWebhookOnStart == false)
        #expect(sut.pollingTimeout == 25)
        #expect(sut.pollingLimit == 50)
    }
}

@Suite("Configuration Error Tests")
struct ConfigurationErrorTests {

    @Test("Test error description for missing env var contains variable name")
    func testErrorDescriptionForMissingEnvVarContainsVariableName() {
        // Arrange
        let sut = ConfigurationError.missingEnvironmentVariable("TEST_VAR")

        // Act
        let description = sut.errorDescription

        // Assert
        #expect(description?.contains("TEST_VAR") == true)
    }

    @Test("Test error description for not configured service contains service name")
    func testErrorDescriptionForNotConfiguredServiceContainsServiceName() {
        // Arrange
        let sut = ConfigurationError.notConfigured("TestService")

        // Act
        let description = sut.errorDescription

        // Assert
        #expect(description?.contains("TestService") == true)
    }
}
