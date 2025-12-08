@testable import Iskra
import Foundation
import Testing

// MARK: - Filter Callback Parsing Tests

@Suite("Filter Callback Parsing Tests")
struct FilterCallbackParsingTests {

    @Test("Test filter menu callback parses correctly")
    func testFilterMenuCallbackParsesCorrectly() {
        // Arrange
        let data = "filter:menu"

        // Act
        let parsed = ParsedCallback.parse(id: "1", data: data)

        // Assert
        #expect(parsed.prefix == "filter")
        #expect(parsed.payload == "menu")
    }

    @Test("Test gender filter callback parses correctly")
    func testGenderFilterCallbackParsesCorrectly() {
        // Arrange
        let data = "filter:gender:own"

        // Act
        let parsed = ParsedCallback.parse(id: "2", data: data)

        // Assert
        #expect(parsed.prefix == "filter")
        #expect(parsed.payload == "gender:own")

        // Verify nested parsing
        let parts = parsed.payload!.split(separator: ":", maxSplits: 1)
        #expect(String(parts[0]) == "gender")
        #expect(String(parts[1]) == "own")
    }

    @Test("Test age filter callback parses correctly")
    func testAgeFilterCallbackParsesCorrectly() {
        // Arrange
        let data = "filter:age:18:25"

        // Act
        let parsed = ParsedCallback.parse(id: "3", data: data)

        // Assert
        #expect(parsed.prefix == "filter")
        #expect(parsed.payload == "age:18:25")

        // Verify nested parsing
        let parts = parsed.payload!.split(separator: ":")
        #expect(parts.count == 3)
        #expect(String(parts[0]) == "age")
        #expect(String(parts[1]) == "18")
        #expect(String(parts[2]) == "25")
    }

    @Test("Test geo filter callback parses correctly")
    func testGeoFilterCallbackParsesCorrectly() {
        // Arrange
        let data = "filter:geo:any"

        // Act
        let parsed = ParsedCallback.parse(id: "4", data: data)

        // Assert
        #expect(parsed.prefix == "filter")
        #expect(parsed.payload == "geo:any")
    }

    @Test("Test show gender options callback")
    func testShowGenderOptionsCallback() {
        // Arrange
        let data = "filter:show:gender"

        // Act
        let parsed = ParsedCallback.parse(id: "5", data: data)

        // Assert
        #expect(parsed.prefix == "filter")
        #expect(parsed.payload == "show:gender")
    }

    @Test("Test show age options callback")
    func testShowAgeOptionsCallback() {
        // Arrange
        let data = "filter:show:age"

        // Act
        let parsed = ParsedCallback.parse(id: "6", data: data)

        // Assert
        #expect(parsed.prefix == "filter")
        #expect(parsed.payload == "show:age")
    }

    @Test("Test done callback")
    func testDoneCallback() {
        // Arrange
        let data = "filter:done"

        // Act
        let parsed = ParsedCallback.parse(id: "7", data: data)

        // Assert
        #expect(parsed.prefix == "filter")
        #expect(parsed.payload == "done")
    }
}

// MARK: - Settings Step Tests

@Suite("Settings Step Tests")
struct SettingsStepTests {

    @Test("Test filters step equality")
    func testFiltersStepEquality() {
        // Assert
        #expect(SettingsStep.filters == SettingsStep.filters)
    }

    @Test("Test bot state with settings filters")
    func testBotStateWithSettingsFilters() {
        // Arrange
        let state = BotState.settings(.filters)

        // Assert
        #expect(state == .settings(.filters))
        #expect(state != .idle)
    }
}

// MARK: - Filter DTO Tests

@Suite("Filter DTO Tests")
struct FilterDTOTests {

    @Test("Test filter DTO stores all fields")
    func testFilterDTOStoresAllFields() {
        // Arrange
        let userId = UUID()

        // Act
        let dto = FilterDTO(
            userId: userId,
            targetGenders: [.male, .female],
            ageMin: 18,
            ageMax: 35,
            lookingFor: [.friendship]
        )

        // Assert
        #expect(dto.userId == userId)
        #expect(dto.targetGenders == [Gender.male, Gender.female])
        #expect(dto.ageMin == 18)
        #expect(dto.ageMax == 35)
        #expect(dto.lookingFor == [LookingFor.friendship])
    }

    @Test("Test target genders any is both male and female")
    func testTargetGendersAnyIsBothMaleAndFemale() {
        // Arrange
        let anyGenders: [Gender] = [.male, .female]

        // Assert
        #expect(anyGenders.contains(.male))
        #expect(anyGenders.contains(.female))
        #expect(anyGenders.count == 2)
    }
}

// MARK: - Gender Enum Tests

@Suite("Gender Filter Tests")
struct GenderFilterTests {

    @Test("Test gender enum raw values")
    func testGenderEnumRawValues() {
        // Assert
        #expect(Gender.male.rawValue == "male")
        #expect(Gender.female.rawValue == "female")
    }

    @Test("Test target gender own for male user")
    func testTargetGenderOwnForMaleUser() {
        // Arrange
        let userGender = Gender.male

        // Act - "own" means same gender
        let targetGenders = [userGender]

        // Assert
        #expect(targetGenders == [.male])
    }

    @Test("Test target gender opposite for male user")
    func testTargetGenderOppositeForMaleUser() {
        // Arrange
        let userGender = Gender.male

        // Act - "opposite" means different gender
        let targetGenders = userGender == .male ? [Gender.female] : [Gender.male]

        // Assert
        #expect(targetGenders == [.female])
    }

    @Test("Test target gender any for any user")
    func testTargetGenderAnyForAnyUser() {
        // Act - "any" means both genders
        let targetGenders: [Gender] = [.male, .female]

        // Assert
        #expect(targetGenders.count == 2)
    }
}

// MARK: - LookingFor Enum Tests

@Suite("LookingFor Enum Tests")
struct LookingForEnumTests {

    @Test("Test looking for raw values")
    func testLookingForRawValues() {
        // Assert
        #expect(LookingFor.friendship.rawValue == "friendship")
        #expect(LookingFor.relationship.rawValue == "relationship")
    }

    @Test("Test looking for all cases")
    func testLookingForAllCases() {
        // Assert
        #expect(LookingFor.allCases.count == 2)
        #expect(LookingFor.allCases.contains(.friendship))
        #expect(LookingFor.allCases.contains(.relationship))
    }
}
