@testable import Iskra
import Testing

@Suite("Parsed Callback Tests")
struct ParsedCallbackTests {

    @Test("Test parse with prefix and payload extracts both")
    func testParseWithPrefixAndPayloadExtractsBoth() {
        // Arrange
        let id = "123"
        let data = "action:confirm"

        // Act
        let sut = ParsedCallback.parse(id: id, data: data)

        // Assert
        #expect(sut.id == "123")
        #expect(sut.data == "action:confirm")
        #expect(sut.prefix == "action")
        #expect(sut.payload == "confirm")
    }

    @Test("Test parse with nested payload preserves full payload")
    func testParseWithNestedPayloadPreservesFullPayload() {
        // Arrange
        let data = "menu:settings:audio"

        // Act
        let sut = ParsedCallback.parse(id: "456", data: data)

        // Assert
        #expect(sut.prefix == "menu")
        #expect(sut.payload == "settings:audio")
    }

    @Test("Test parse with prefix only returns nil payload")
    func testParseWithPrefixOnlyReturnsNilPayload() {
        // Arrange
        let data = "cancel"

        // Act
        let sut = ParsedCallback.parse(id: "789", data: data)

        // Assert
        #expect(sut.prefix == "cancel")
        #expect(sut.payload == nil)
    }

    @Test("Test parse with empty payload after colon returns nil payload")
    func testParseWithEmptyPayloadAfterColonReturnsNilPayload() {
        // Arrange
        let data = "action:"

        // Act
        let sut = ParsedCallback.parse(id: "111", data: data)

        // Assert
        #expect(sut.prefix == "action")
        #expect(sut.payload == nil)
    }

    @Test("Test parse with colon at start returns empty prefix")
    func testParseWithColonAtStartReturnsEmptyPrefix() {
        // Arrange
        let data = ":payload"

        // Act
        let sut = ParsedCallback.parse(id: "222", data: data)

        // Assert
        #expect(sut.prefix == "")
        #expect(sut.payload == "payload")
    }

    @Test("Test equality with same values returns true")
    func testEqualityWithSameValuesReturnsTrue() {
        // Arrange
        let cb1 = ParsedCallback(id: "1", data: "a:b", prefix: "a", payload: "b")
        let cb2 = ParsedCallback(id: "1", data: "a:b", prefix: "a", payload: "b")

        // Act & Assert
        #expect(cb1 == cb2)
    }

    @Test("Test equality with different id returns false")
    func testEqualityWithDifferentIdReturnsFalse() {
        // Arrange
        let cb1 = ParsedCallback(id: "1", data: "a:b", prefix: "a", payload: "b")
        let cb2 = ParsedCallback(id: "2", data: "a:b", prefix: "a", payload: "b")

        // Act & Assert
        #expect(cb1 != cb2)
    }
}
