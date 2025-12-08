@testable import Iskra
import Testing

@Suite("Search Localization Tests")
struct SearchLocalizationTests {

    init() {
        L10n.load(locale: "en")
    }

    @Test("Test search menu strings exist")
    func testSearchMenuStringsExist() {
        #expect(!L10n["search.menu.title"].hasPrefix("["))
        #expect(!L10n["search.menu.hint"].hasPrefix("["))
        #expect(!L10n["search.menu.startSurfing"].hasPrefix("["))
        #expect(!L10n["search.menu.incoming"].hasPrefix("["))
        #expect(!L10n["search.menu.filters"].hasPrefix("["))
    }

    @Test("Test search action strings exist")
    func testSearchActionStringsExist() {
        #expect(!L10n["search.actions.like"].hasPrefix("["))
        #expect(!L10n["search.actions.skip"].hasPrefix("["))
        #expect(!L10n["search.actions.message"].hasPrefix("["))
        #expect(!L10n["search.actions.report"].hasPrefix("["))
    }

    @Test("Test search button strings exist")
    func testSearchButtonStringsExist() {
        #expect(!L10n["search.buttons.createProfile"].hasPrefix("["))
        #expect(!L10n["search.buttons.browse"].hasPrefix("["))
        #expect(!L10n["search.buttons.resume"].hasPrefix("["))
        #expect(!L10n["search.buttons.stop"].hasPrefix("["))
    }

    @Test("Test search error strings exist")
    func testSearchErrorStringsExist() {
        #expect(!L10n["search.error.noProfile"].hasPrefix("["))
        #expect(!L10n["search.error.notRegistered"].hasPrefix("["))
    }

    @Test("Test search no profiles strings exist")
    func testSearchNoProfilesStringsExist() {
        #expect(!L10n["search.noProfiles.title"].hasPrefix("["))
        #expect(!L10n["search.noProfiles.hint"].hasPrefix("["))
        #expect(!L10n["search.noProfiles.adjustFilters"].hasPrefix("["))
        #expect(!L10n["search.noProfiles.viewIncoming"].hasPrefix("["))
    }

    @Test("Test search match strings exist")
    func testSearchMatchStringsExist() {
        #expect(!L10n["search.match.title"].hasPrefix("["))
        #expect(!L10n["search.match.hint"].hasPrefix("["))
        #expect(!L10n["search.match.sendMessage"].hasPrefix("["))
        #expect(!L10n["search.match.continue"].hasPrefix("["))
    }

    @Test("Test search message strings exist")
    func testSearchMessageStringsExist() {
        #expect(!L10n["search.message.prompt"].hasPrefix("["))
        #expect(!L10n["search.message.sent"].hasPrefix("["))
    }

    @Test("Test search incoming strings exist")
    func testSearchIncomingStringsExist() {
        #expect(!L10n["search.incoming.empty"].hasPrefix("["))
        #expect(!L10n["search.incoming.done"].hasPrefix("["))
        #expect(!L10n["search.incoming.message"].hasPrefix("["))
        #expect(!L10n["search.incoming.liked"].hasPrefix("["))
        #expect(!L10n["search.incoming.back"].hasPrefix("["))
    }

    @Test("Test search notification strings exist")
    func testSearchNotificationStringsExist() {
        #expect(!L10n["search.notification.like"].hasPrefix("["))
        #expect(!L10n["search.notification.message"].hasPrefix("["))
        #expect(!L10n["search.notification.match"].hasPrefix("["))
        #expect(!L10n["search.notification.viewProfiles"].hasPrefix("["))
        #expect(!L10n["search.notification.viewMatch"].hasPrefix("["))
    }
}
