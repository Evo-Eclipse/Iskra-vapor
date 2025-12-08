@testable import Iskra
import Testing

@Suite("Match Localization Tests")
struct MatchLocalizationTests {

    init() {
        L10n.load(locale: "en")
    }

    @Test("Test match notification strings exist")
    func testMatchNotificationStringsExist() {
        #expect(!L10n["match.notification.title"].hasPrefix("["))
        #expect(!L10n["match.notification.contact"].hasPrefix("["))
        #expect(!L10n["match.notification.openChat"].hasPrefix("["))
        #expect(!L10n["match.notification.spamBlockWarning"].hasPrefix("["))
    }

    @Test("Test match notification title contains placeholder")
    func testMatchNotificationTitleContainsPlaceholder() {
        let title = L10n["match.notification.title"]
        #expect(title.contains("%@"))
    }

    @Test("Test match notification contact contains placeholder")
    func testMatchNotificationContactContainsPlaceholder() {
        let contact = L10n["match.notification.contact"]
        #expect(contact.contains("%@"))
    }
}
