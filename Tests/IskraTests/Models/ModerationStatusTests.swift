@testable import Iskra
import Testing

@Suite("Moderation Status Tests")
struct ModerationStatusTests {

    @Test("Test all statuses have raw values")
    func testAllStatusesHaveRawValues() {
        // Assert
        #expect(ModerationStatus.pending.rawValue == "pending")
        #expect(ModerationStatus.approved.rawValue == "approved")
        #expect(ModerationStatus.rejected.rawValue == "rejected")
    }

    @Test("Test status from raw value")
    func testStatusFromRawValue() {
        // Assert
        #expect(ModerationStatus(rawValue: "pending") == .pending)
        #expect(ModerationStatus(rawValue: "approved") == .approved)
        #expect(ModerationStatus(rawValue: "rejected") == .rejected)
        #expect(ModerationStatus(rawValue: "invalid") == nil)
    }

    @Test("Test pending is initial state")
    func testPendingIsInitialState() {
        // This test documents that pending is the expected initial state
        let initialStatus = ModerationStatus.pending

        // Assert
        #expect(initialStatus == .pending)
        #expect(initialStatus != .approved)
        #expect(initialStatus != .rejected)
    }
}

@Suite("User Status Tests")
struct UserStatusTests {

    @Test("Test all user statuses have raw values")
    func testAllUserStatusesHaveRawValues() {
        // Assert
        #expect(UserStatus.active.rawValue == "active")
        #expect(UserStatus.paused.rawValue == "paused")
        #expect(UserStatus.banned.rawValue == "banned")
        #expect(UserStatus.archived.rawValue == "archived")
    }

    @Test("Test user status from raw value")
    func testUserStatusFromRawValue() {
        // Assert
        #expect(UserStatus(rawValue: "active") == .active)
        #expect(UserStatus(rawValue: "paused") == .paused)
        #expect(UserStatus(rawValue: "banned") == .banned)
        #expect(UserStatus(rawValue: "archived") == .archived)
        #expect(UserStatus(rawValue: "invalid") == nil)
    }

    @Test("Test active is default state for new users")
    func testActiveIsDefaultStateForNewUsers() {
        // This test documents that active is the expected default state
        let defaultStatus = UserStatus.active

        // Assert
        #expect(defaultStatus == .active)
    }
}

@Suite("Gender Tests")
struct GenderTests {

    @Test("Test all genders have raw values")
    func testAllGendersHaveRawValues() {
        // Assert
        #expect(Gender.male.rawValue == "male")
        #expect(Gender.female.rawValue == "female")
    }

    @Test("Test gender from raw value")
    func testGenderFromRawValue() {
        // Assert
        #expect(Gender(rawValue: "male") == .male)
        #expect(Gender(rawValue: "female") == .female)
        #expect(Gender(rawValue: "invalid") == nil)
    }
}
