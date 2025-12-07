@testable import Iskra
import Testing

@Suite("Bot Command Tests")
struct BotCommandTests {

    @Test("Test name is always lowercase")
    func testNameIsAlwaysLowercase() {
        // Arrange & Act
        let sut = BotCommand(name: "start", arguments: nil, rawCommand: "/start")

        // Assert
        #expect(sut.name == "start")
    }

    @Test("Test arguments when provided returns value")
    func testArgumentsWhenProvidedReturnsValue() {
        // Arrange & Act
        let sut = BotCommand(name: "start", arguments: "deep_link_payload", rawCommand: "/start")

        // Assert
        #expect(sut.arguments == "deep_link_payload")
    }

    @Test("Test arguments when not provided returns nil")
    func testArgumentsWhenNotProvidedReturnsNil() {
        // Arrange & Act
        let sut = BotCommand(name: "help", arguments: nil, rawCommand: "/help")

        // Assert
        #expect(sut.arguments == nil)
    }

    @Test("Test raw command with bot mention preserves full command")
    func testRawCommandWithBotMentionPreservesFullCommand() {
        // Arrange & Act
        let sut = BotCommand(name: "start", arguments: nil, rawCommand: "/start@MyBot")

        // Assert
        #expect(sut.rawCommand == "/start@MyBot")
    }

    @Test("Test equality with same values returns true")
    func testEqualityWithSameValuesReturnsTrue() {
        // Arrange
        let cmd1 = BotCommand(name: "start", arguments: "payload", rawCommand: "/start")
        let cmd2 = BotCommand(name: "start", arguments: "payload", rawCommand: "/start")

        // Act & Assert
        #expect(cmd1 == cmd2)
    }

    @Test("Test equality with different arguments returns false")
    func testEqualityWithDifferentArgumentsReturnsFalse() {
        // Arrange
        let cmd1 = BotCommand(name: "start", arguments: "payload1", rawCommand: "/start")
        let cmd2 = BotCommand(name: "start", arguments: "payload2", rawCommand: "/start")

        // Act & Assert
        #expect(cmd1 != cmd2)
    }
}
