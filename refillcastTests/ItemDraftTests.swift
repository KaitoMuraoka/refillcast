import Foundation
import Testing
@testable import refillcast

struct ItemDraftTests {
    private func draft(name: String = "歯ブラシ", cycleDays: Int? = 30) -> ItemDraft {
        ItemDraft(name: name, cycleDays: cycleDays, memo: "", initialPurchaseDate: nil)
    }

    @Test func validDraft() {
        #expect(draft().isValid)
    }

    @Test(arguments: ["", "   ", "\n"])
    func emptyNameCannotBeSaved(name: String) {
        #expect(draft(name: name).nameIssue == .empty)
        #expect(!draft(name: name).isValid)
    }

    @Test func nameLengthLimit() {
        #expect(draft(name: String(repeating: "あ", count: 30)).nameIssue == nil)
        #expect(draft(name: String(repeating: "あ", count: 31)).nameIssue == .tooLong)
    }

    @Test func surroundingSpacesAreNotCounted() {
        let name = "  " + String(repeating: "a", count: 30) + "  "
        #expect(draft(name: name).nameIssue == nil)
        #expect(draft(name: name).trimmedName.count == 30)
    }

    @Test func cycleMustBeAtLeastOne() {
        #expect(draft(cycleDays: 0).cycleIssue == .outOfRange)
        #expect(draft(cycleDays: -5).cycleIssue == .outOfRange)
        #expect(draft(cycleDays: 1).cycleIssue == nil)
        #expect(draft(cycleDays: nil).cycleIssue == .missing)
    }

    @Test func parseCycleDays() {
        #expect(ItemDraft.parseCycleDays("30") == 30)
        #expect(ItemDraft.parseCycleDays(" 7 ") == 7)
        #expect(ItemDraft.parseCycleDays("") == nil)
        #expect(ItemDraft.parseCycleDays("3.5") == nil)
        #expect(ItemDraft.parseCycleDays("-1") == nil)
        #expect(ItemDraft.parseCycleDays("３０") == nil)
    }
}
