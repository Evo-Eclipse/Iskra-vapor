@testable import Iskra
import Testing

@Suite("Filters Localization Tests")
struct FiltersLocalizationTests {

    init() {
        L10n.load(locale: "en")
    }

    @Test("Test filter menu strings exist")
    func testFilterMenuStringsExist() {
        // Assert
        #expect(!L10n["filters.menu.title"].hasPrefix("["))
        #expect(!L10n["filters.menu.body"].hasPrefix("["))
        #expect(!L10n["filters.menu.gender"].hasPrefix("["))
        #expect(!L10n["filters.menu.age"].hasPrefix("["))
        #expect(!L10n["filters.menu.done"].hasPrefix("["))
    }

    @Test("Test gender filter strings exist")
    func testGenderFilterStringsExist() {
        // Assert
        #expect(!L10n["filters.gender.title"].hasPrefix("["))
        #expect(!L10n["filters.gender.own"].hasPrefix("["))
        #expect(!L10n["filters.gender.opposite"].hasPrefix("["))
        #expect(!L10n["filters.gender.any"].hasPrefix("["))
    }

    @Test("Test age filter strings exist")
    func testAgeFilterStringsExist() {
        // Assert
        #expect(!L10n["filters.age.title"].hasPrefix("["))
        #expect(!L10n["filters.age.peers"].hasPrefix("["))
        #expect(!L10n["filters.age.young"].hasPrefix("["))
        #expect(!L10n["filters.age.mid"].hasPrefix("["))
        #expect(!L10n["filters.age.mature"].hasPrefix("["))
        #expect(!L10n["filters.age.any"].hasPrefix("["))
    }

    @Test("Test filter labels exist")
    func testFilterLabelsExist() {
        // Assert
        #expect(!L10n["filters.labels.own"].hasPrefix("["))
        #expect(!L10n["filters.labels.opposite"].hasPrefix("["))
        #expect(!L10n["filters.labels.any"].hasPrefix("["))
        #expect(!L10n["filters.labels.peers"].hasPrefix("["))
    }

    @Test("Test saved confirmation exists")
    func testSavedConfirmationExists() {
        // Assert
        let saved = L10n["filters.saved"]
        #expect(!saved.hasPrefix("["))
        #expect(saved.contains("✅"))
    }

    @Test("Test menu strings have placeholders")
    func testMenuStringsHavePlaceholders() {
        // Assert - these should have %@ for dynamic content
        #expect(L10n["filters.menu.gender"].contains("%@"))
        #expect(L10n["filters.menu.age"].contains("%@"))
    }
}
