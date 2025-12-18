@testable import Iskra
import Testing

@Suite("Moderation Localization Tests")
struct ModerationLocalizationTests {

    init() {
        L10n.load(locale: "en")
    }

    @Test("Test moderation approved message exists")
    func testModerationApprovedMessageExists() {
        // Act
        let text = L10n["moderation.approved"]

        // Assert
        #expect(!text.isEmpty)
        #expect(!text.contains("moderation.approved")) // Not returning key as fallback
    }

    @Test("Test moderation rejected message exists and has placeholder")
    func testModerationRejectedMessageExistsAndHasPlaceholder() {
        // Act
        let text = L10n["moderation.rejected"]

        // Assert
        #expect(!text.isEmpty)
        #expect(text.contains("%@")) // Has placeholder for reason
    }

    @Test("Test admin button texts exist")
    func testAdminButtonTextsExist() {
        // Act & Assert
        let approve = L10n["moderation.admin.approve"]
        #expect(!approve.isEmpty)
        #expect(approve.contains("Approve"))

        let reject = L10n["moderation.admin.reject"]
        #expect(!reject.isEmpty)
        #expect(reject.contains("Reject"))
    }

    @Test("Test admin status messages exist")
    func testAdminStatusMessagesExist() {
        // Act & Assert
        let approved = L10n["moderation.admin.statusApproved"]
        #expect(!approved.isEmpty)
        #expect(approved.contains("APPROVED"))

        let rejected = L10n["moderation.admin.statusRejected"]
        #expect(!rejected.isEmpty)
        #expect(rejected.contains("REJECTED"))
        #expect(rejected.contains("%@")) // Has placeholder for reason
    }

    @Test("Test rejection reason buttons exist")
    func testRejectionReasonButtonsExist() {
        // Act & Assert
        let reasons = ["photo", "bio", "inappropriate", "other"]

        for reason in reasons {
            let button = L10n["moderation.reasons.\(reason).button"]
            #expect(!button.isEmpty, "Button for \(reason) should exist")
            #expect(!button.hasPrefix("["), "Button for \(reason) should not return fallback key path")
        }
    }

    @Test("Test rejection reason texts exist")
    func testRejectionReasonTextsExist() {
        // Act & Assert
        let reasons = ["photo", "bio", "inappropriate", "other"]

        for reason in reasons {
            let text = L10n["moderation.reasons.\(reason).text"]
            #expect(!text.isEmpty, "Text for \(reason) should exist")
            #expect(!text.hasPrefix("["), "Text for \(reason) should not return fallback key path")
        }
    }

    @Test("Test edit profile button text exists")
    func testEditProfileButtonTextExists() {
        // Act
        let text = L10n["moderation.admin.editProfile"]

        // Assert
        #expect(!text.isEmpty)
        #expect(text.contains("Edit"))
    }

    @Test("Test common back button exists")
    func testCommonBackButtonExists() {
        // Act
        let text = L10n["common.back"]

        // Assert
        #expect(!text.isEmpty)
        #expect(text.contains("Back"))
    }
}
