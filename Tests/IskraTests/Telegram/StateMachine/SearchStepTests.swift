@testable import Iskra
import Foundation
import Testing

@Suite("Search Step Tests")
struct SearchStepTests {

    @Test("Test bot state with search browsing")
    func testBotStateWithSearchBrowsing() {
        let state = BotState.search(.browsing)
        #expect(state == .search(.browsing))
    }

    @Test("Test bot state with search no profiles")
    func testBotStateWithSearchNoProfiles() {
        let state = BotState.search(.noProfiles)
        #expect(state == .search(.noProfiles))
    }

    @Test("Test bot state with search viewing incoming")
    func testBotStateWithSearchViewingIncoming() {
        let state = BotState.search(.viewingIncoming)
        #expect(state == .search(.viewingIncoming))
    }

    @Test("Test bot state with composing message")
    func testBotStateWithComposingMessage() {
        let targetId = UUID()
        let state = BotState.search(.composingMessage(targetId: targetId))
        #expect(state == .search(.composingMessage(targetId: targetId)))
    }

    @Test("Test search step equality")
    func testSearchStepEquality() {
        #expect(SearchStep.browsing == SearchStep.browsing)
        #expect(SearchStep.noProfiles == SearchStep.noProfiles)
        #expect(SearchStep.viewingIncoming == SearchStep.viewingIncoming)

        let id = UUID()
        #expect(SearchStep.composingMessage(targetId: id) == SearchStep.composingMessage(targetId: id))
    }

    @Test("Test search step inequality with different target IDs")
    func testSearchStepInequalityWithDifferentTargetIds() {
        let id1 = UUID()
        let id2 = UUID()
        #expect(SearchStep.composingMessage(targetId: id1) != SearchStep.composingMessage(targetId: id2))
    }
}
