@testable import Iskra
import Testing

@Suite("Profile Draft Tests")
struct ProfileDraftTests {

    @Test("Test empty draft has all nil values")
    func testEmptyDraftHasAllNilValues() {
        // Act
        let sut = ProfileDraft()

        // Assert
        #expect(sut.city == nil)
        #expect(sut.goal == nil)
        #expect(sut.lookingFor == nil)
        #expect(sut.bio == nil)
        #expect(sut.photoFileId == nil)
    }

    @Test("Test draft with values stores correctly")
    func testDraftWithValuesStoresCorrectly() {
        // Arrange & Act
        let sut = ProfileDraft(
            city: "Vienna",
            goal: .both,
            lookingFor: .any,
            bio: "Hello world!",
            photoFileId: "ABC123"
        )

        // Assert
        #expect(sut.city == "Vienna")
        #expect(sut.goal == .both)
        #expect(sut.lookingFor == .any)
        #expect(sut.bio == "Hello world!")
        #expect(sut.photoFileId == "ABC123")
    }

    @Test("Test draft equality with same values")
    func testDraftEqualityWithSameValues() {
        // Arrange
        let draft1 = ProfileDraft(city: "Berlin", goal: .friendship, lookingFor: .male, bio: "Test", photoFileId: "X")
        let draft2 = ProfileDraft(city: "Berlin", goal: .friendship, lookingFor: .male, bio: "Test", photoFileId: "X")

        // Assert
        #expect(draft1 == draft2)
    }

    @Test("Test draft inequality with different values")
    func testDraftInequalityWithDifferentValues() {
        // Arrange
        let draft1 = ProfileDraft(city: "Berlin", goal: .friendship, lookingFor: .male, bio: "Test", photoFileId: "X")
        let draft2 = ProfileDraft(city: "Paris", goal: .friendship, lookingFor: .male, bio: "Test", photoFileId: "X")

        // Assert
        #expect(draft1 != draft2)
    }

    @Test("Test draft is complete when all fields present")
    func testDraftIsCompleteWhenAllFieldsPresent() {
        // Arrange
        let sut = ProfileDraft(
            city: "Vienna",
            goal: .both,
            lookingFor: .any,
            bio: "Hello world!",
            photoFileId: "ABC123"
        )

        // Assert
        #expect(sut.city != nil)
        #expect(sut.goal != nil)
        #expect(sut.lookingFor != nil)
        #expect(sut.bio != nil)
        #expect(sut.photoFileId != nil)
    }
}

@Suite("Profile Goal Tests")
struct ProfileGoalTests {

    @Test("Test all profile goals have raw values")
    func testAllProfileGoalsHaveRawValues() {
        // Assert
        #expect(ProfileGoal.friendship.rawValue == "friendship")
        #expect(ProfileGoal.relationship.rawValue == "relationship")
        #expect(ProfileGoal.both.rawValue == "both")
    }

    @Test("Test profile goal from raw value")
    func testProfileGoalFromRawValue() {
        // Assert
        #expect(ProfileGoal(rawValue: "friendship") == .friendship)
        #expect(ProfileGoal(rawValue: "relationship") == .relationship)
        #expect(ProfileGoal(rawValue: "both") == .both)
        #expect(ProfileGoal(rawValue: "invalid") == nil)
    }

    @Test("Test all cases returns all goals")
    func testAllCasesReturnsAllGoals() {
        // Assert
        #expect(ProfileGoal.allCases.count == 3)
        #expect(ProfileGoal.allCases.contains(.friendship))
        #expect(ProfileGoal.allCases.contains(.relationship))
        #expect(ProfileGoal.allCases.contains(.both))
    }
}

@Suite("Looking For Preference Tests")
struct LookingForPreferenceTests {

    @Test("Test all preferences have raw values")
    func testAllPreferencesHaveRawValues() {
        // Assert
        #expect(LookingForPreference.male.rawValue == "male")
        #expect(LookingForPreference.female.rawValue == "female")
        #expect(LookingForPreference.any.rawValue == "any")
    }

    @Test("Test preference from raw value")
    func testPreferenceFromRawValue() {
        // Assert
        #expect(LookingForPreference(rawValue: "male") == .male)
        #expect(LookingForPreference(rawValue: "female") == .female)
        #expect(LookingForPreference(rawValue: "any") == .any)
        #expect(LookingForPreference(rawValue: "invalid") == nil)
    }

    @Test("Test all cases returns all preferences")
    func testAllCasesReturnsAllPreferences() {
        // Assert
        #expect(LookingForPreference.allCases.count == 3)
        #expect(LookingForPreference.allCases.contains(.male))
        #expect(LookingForPreference.allCases.contains(.female))
        #expect(LookingForPreference.allCases.contains(.any))
    }
}
