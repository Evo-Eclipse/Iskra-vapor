@testable import Iskra
import Testing

@Suite("Moderation Callback Parsing Tests")
struct ModerationCallbackParsingTests {

    @Test("Test approve callback parses moderation ID correctly")
    func testApproveCallbackParsesModerationIdCorrectly() {
        // Arrange
        let uuid = "DAEFFC17-5922-4D4C-9873-4891CCB501B7"
        let data = "mod:approve:\(uuid)"

        // Act
        let parsed = ParsedCallback.parse(id: "1", data: data)

        // Assert
        #expect(parsed.prefix == "mod")
        #expect(parsed.payload == "approve:\(uuid)")
    }

    @Test("Test reject callback parses moderation ID correctly")
    func testRejectCallbackParsesModerationIdCorrectly() {
        // Arrange
        let uuid = "DAEFFC17-5922-4D4C-9873-4891CCB501B7"
        let data = "mod:reject:\(uuid)"

        // Act
        let parsed = ParsedCallback.parse(id: "2", data: data)

        // Assert
        #expect(parsed.prefix == "mod")
        #expect(parsed.payload == "reject:\(uuid)")
    }

    @Test("Test reason callback parses moderation ID and reason correctly")
    func testReasonCallbackParsesModerationIdAndReasonCorrectly() {
        // Arrange
        let uuid = "DAEFFC17-5922-4D4C-9873-4891CCB501B7"
        let data = "mod:reason:\(uuid):photo"

        // Act
        let parsed = ParsedCallback.parse(id: "3", data: data)

        // Assert
        #expect(parsed.prefix == "mod")
        #expect(parsed.payload == "reason:\(uuid):photo")

        // Verify nested parsing
        let payload = parsed.payload!
        let parts = payload.split(separator: ":", maxSplits: 1)
        #expect(parts.count == 2)
        #expect(String(parts[0]) == "reason")

        let reasonParts = String(parts[1]).split(separator: ":", maxSplits: 1)
        #expect(reasonParts.count == 2)
        #expect(String(reasonParts[0]) == uuid)
        #expect(String(reasonParts[1]) == "photo")
    }

    @Test("Test back callback parses moderation ID correctly")
    func testBackCallbackParsesModerationIdCorrectly() {
        // Arrange
        let uuid = "DAEFFC17-5922-4D4C-9873-4891CCB501B7"
        let data = "mod:back:\(uuid)"

        // Act
        let parsed = ParsedCallback.parse(id: "4", data: data)

        // Assert
        #expect(parsed.prefix == "mod")
        #expect(parsed.payload == "back:\(uuid)")
    }

    @Test("Test extracting action from payload works correctly")
    func testExtractingActionFromPayloadWorksCorrectly() {
        // Arrange
        let testCases: [(String, String)] = [
            ("approve:uuid", "approve"),
            ("reject:uuid", "reject"),
            ("reason:uuid:photo", "reason"),
            ("back:uuid", "back"),
        ]

        for (payload, expectedAction) in testCases {
            // Act
            let parts = payload.split(separator: ":", maxSplits: 1)
            let action = parts.first.map(String.init)

            // Assert
            #expect(action == expectedAction, "Expected \(expectedAction) but got \(action ?? "nil")")
        }
    }
}
